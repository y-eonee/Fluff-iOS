import Combine
@preconcurrency import Metal
@preconcurrency import MetalKit
import RealityKit
import UIKit

/// Home owns its render cadence through public RealityRenderer + MTKView APIs.
/// Editing previews retain ARView; both paths share the same scene and picking rules.
@MainActor
final class RoomRenderView: UIView, MTKViewDelegate {
    private var renderer: RealityRenderer?
    private var metalView: MTKView?
    private var legacy: EfficientARView?
    private var queue: MTLCommandQueue?
    private var event: MTLEvent?
    private var sequence: UInt64 = 0
    private var inFlight: Set<Int> = []
    private var previousFrame: CFTimeInterval?
    private var interactiveUntil: CFTimeInterval = 0
    private var observations: [AnyCancellable] = []
    private var bloom: CozyBloom?
    private var wantsBloom = false
    private var sources: [MTLTexture?] = [nil, nil]
    private var captures: [(UIImage?) -> Void] = []
    private(set) var root: AnchorEntity?
    private weak var camera: PerspectiveCamera?
    private(set) var completedFrames = 0
    private(set) var requestedFPS = 30
    private(set) var lastRenderError: String?
    var performanceInteraction: ((Double) -> Void)?
    private let createdAt = CACurrentMediaTime()
    static let liveViews = NSHashTable<RoomRenderView>.weakObjects()
    var renderScale: CGFloat { legacy?.contentScaleFactor ?? contentScaleFactor }
    var isAdaptive: Bool { renderer != nil }

    var sceneBackground: UIColor = .clear {
        didSet {
            legacy?.environment.background = .color(sceneBackground)
            renderer?.cameraSettings.colorBackground = .color(sceneBackground.cgColor)
        }
    }
    var environmentResource: EnvironmentResource? {
        get { renderer?.lighting.resource ?? legacy?.environment.lighting.resource }
        set { renderer?.lighting.resource = newValue; legacy?.environment.lighting.resource = newValue }
    }
    var lightingExponent: Float = 0 {
        didSet { renderer?.lighting.intensityExponent = lightingExponent; legacy?.environment.lighting.intensityExponent = lightingExponent }
    }

    init(adaptive: Bool) {
        super.init(frame: .zero)
        if adaptive, !ProcessInfo.processInfo.arguments.contains("--legacy-room-renderer"),
           let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue(),
           let event = device.makeEvent(), let renderer = try? RealityRenderer() {
            self.renderer = renderer; self.queue = queue; self.event = event
            let view = MTKView(frame: .zero, device: device)
            view.colorPixelFormat = .bgra8Unorm_srgb
            view.framebufferOnly = false
            view.isOpaque = false
            view.backgroundColor = .clear
            view.isUserInteractionEnabled = false
            view.preferredFramesPerSecond = 30
            view.delegate = self
            metalView = view
            addSubview(view)
            renderer.cameraSettings.isToneMappingEnabled = true
        } else {
            let view = EfficientARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
            view.renderOptions.formUnion([.disableMotionBlur, .disableDepthOfField, .disableCameraGrain])
            view.isUserInteractionEnabled = false
            legacy = view
            addSubview(view)
            requestedFPS = 60
        }
        Self.liveViews.add(self)
        for name in [UIApplication.didBecomeActiveNotification, UIApplication.willResignActiveNotification,
                     ProcessInfo.thermalStateDidChangeNotification, .NSProcessInfoPowerStateDidChange] {
            observations.append(NotificationCenter.default.publisher(for: name).receive(on: RunLoop.main).sink { [weak self] notification in
                MainActor.assumeIsolated {
                    if notification.name == UIApplication.willResignActiveNotification {
                        self?.metalView?.isPaused = true
                        self?.previousFrame = nil
                    } else { self?.applyBudget() }
                }
            })
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMoveToWindow() { super.didMoveToWindow(); previousFrame = nil; applyBudget() }
    override func layoutSubviews() {
        super.layoutSubviews()
        legacy?.frame = bounds
        metalView?.frame = bounds
        applyBudget()
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if event?.type == .touches, bounds.contains(point) { markInteraction() }
        return super.hitTest(point, with: event)
    }
    func markInteraction() {
        interactiveUntil = CACurrentMediaTime() + 0.8
        if renderer != nil { requestedFPS = 60; metalView?.preferredFramesPerSecond = 60 }
    }
    func attach(_ root: AnchorEntity, camera: PerspectiveCamera) {
        self.root = root; self.camera = camera
        if let renderer { renderer.entities.append(root); renderer.activeCamera = camera }
        else { legacy?.scene.addAnchor(root) }
    }
    func subscribe(_ update: @escaping (TimeInterval) -> Void) -> any Cancellable {
        if let renderer {
            let subscription = renderer.subscribe(to: SceneEvents.Update.self) { update($0.deltaTime) }
            return AnyCancellable { subscription.cancel() }
        }
        return legacy!.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            MainActor.assumeIsolated {
                self?.completedFrames += 1
                self?.runPerformanceInteraction()
            }
            update(event.deltaTime)
        }
    }
    func configureBloom() { wantsBloom = true; legacy?.configureBloom(); applyBudget() }

    private func applyBudget() {
        guard let view = metalView else { return }
        let constrained = ProcessInfo.processInfo.isLowPowerModeEnabled || ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue
        contentScaleFactor = min(max(1, traitCollection.displayScale), constrained ? 1 : 1.5)
        view.drawableSize = CGSize(width: max(1, bounds.width * contentScaleFactor), height: max(1, bounds.height * contentScaleFactor))
        view.isPaused = window == nil || UIApplication.shared.applicationState != .active
        if wantsBloom && !constrained, bloom == nil, let device = view.device { bloom = CozyBloom(device: device) }
        if constrained || !wantsBloom { bloom = nil; sources = [nil, nil] }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { sources = [nil, nil] }
    func draw(in view: MTKView) {
        guard let slot = (0..<2).first(where: { !inFlight.contains($0) }), let renderer, let root, !root.children.isEmpty,
              let drawable = view.currentDrawable, let event, let command = queue?.makeCommandBuffer() else { return }
        let now = CACurrentMediaTime()
        runPerformanceInteraction()
        let touching = gestureRecognizers?.contains { $0.state == .began || $0.state == .changed } == true
        let fps = touching || now < interactiveUntil ? 60 : 30
        if requestedFPS != fps { requestedFPS = fps; view.preferredFramesPerSecond = fps }
        let delta = min(previousFrame.map { now - $0 } ?? 1 / Double(fps), 0.1)
        previousFrame = now
        let target = drawable.texture
        var source = sources[slot]
        if bloom != nil, source?.width != target.width || source?.height != target.height {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: target.width, height: target.height, mipmapped: false)
            descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            descriptor.storageMode = .private
            source = view.device?.makeTexture(descriptor: descriptor)
            sources[slot] = source
        }
        let renderTarget = bloom == nil ? target : (source ?? target)
        sequence += 1
        do {
            let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: renderTarget))
            inFlight.insert(slot)
            try renderer.updateAndRender(deltaTime: delta, cameraOutput: output, actionsAfterRender: [.signal(event, value: sequence)])
        } catch {
            inFlight.remove(slot)
            lastRenderError = String(describing: error)
            return
        }
        command.encodeWaitForEvent(event, value: sequence)
        if renderTarget !== target { bloom?.render(source: renderTarget, target: target, commandBuffer: command) }
        let pending = captures
        captures.removeAll()
        var pixels: MTLBuffer?
        let bytesPerRow = ((target.width * 4 + 255) / 256) * 256
        if !pending.isEmpty, let buffer = view.device?.makeBuffer(length: bytesPerRow * target.height, options: .storageModeShared),
           let blit = command.makeBlitCommandEncoder() {
            blit.copy(from: target, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                      sourceSize: MTLSize(width: target.width, height: target.height, depth: 1), to: buffer,
                      destinationOffset: 0, destinationBytesPerRow: bytesPerRow, destinationBytesPerImage: bytesPerRow * target.height)
            blit.endEncoding(); pixels = buffer
        }
        let capturedPixels = pixels
        let width = target.width, height = target.height
        command.present(drawable)
        command.addCompletedHandler { [weak self] buffer in
            Task { @MainActor [weak self] in
                self?.inFlight.remove(slot)
                if buffer.status == .completed { self?.completedFrames += 1 }
                else { self?.lastRenderError = buffer.error?.localizedDescription ?? "Metal frame failed" }
                if !pending.isEmpty {
                    var image: UIImage?
                    if buffer.status == .completed, let capturedPixels {
                        let data = Data(bytes: capturedPixels.contents(), count: bytesPerRow * height)
                        if let provider = CGDataProvider(data: data as CFData),
                           let cgImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                              bytesPerRow: bytesPerRow, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                              bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue),
                              provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) { image = UIImage(cgImage: cgImage) }
                    }
                    pending.forEach { $0(image) }
                }
            }
        }
        command.commit()
    }

    func snapshot(_ completion: @escaping (UIImage?) -> Void) {
        if let legacy { legacy.snapshot(saveToHDR: false, completion: completion) }
        else { captures.append(completion); markInteraction() }
    }
    func project(_ point: SIMD3<Float>) -> CGPoint? {
        if let legacy { return legacy.project(point) }
        guard let camera, bounds.width > 0, bounds.height > 0 else { return nil }
        let local = camera.transformMatrix(relativeTo: nil).inverse * SIMD4(point, 1)
        guard local.z < -camera.camera.near else { return nil }
        let half = tan(camera.camera.fieldOfViewInDegrees * .pi / 360)
        let aspect = Float(bounds.width / bounds.height)
        return CGPoint(x: CGFloat(local.x / (-local.z * half * aspect) + 1) * bounds.width / 2,
                       y: CGFloat(1 - local.y / (-local.z * half)) * bounds.height / 2)
    }
    func ray(through point: CGPoint) -> (origin: SIMD3<Float>, direction: SIMD3<Float>)? {
        if let legacy { return legacy.ray(through: point) }
        guard let camera, bounds.width > 0, bounds.height > 0 else { return nil }
        let half = tan(camera.camera.fieldOfViewInDegrees * .pi / 360)
        let local = SIMD4<Float>(Float(2 * point.x / bounds.width - 1) * half * Float(bounds.width / bounds.height),
                                 Float(1 - 2 * point.y / bounds.height) * half, -1, 0)
        let transform = camera.transformMatrix(relativeTo: nil)
        let direction = transform * local
        return (camera.position(relativeTo: nil), simd_normalize(SIMD3(direction.x, direction.y, direction.z)))
    }
    func raycast(origin: SIMD3<Float>, direction: SIMD3<Float>, length: Float) -> [CollisionCastHit] {
        (legacy?.scene ?? root?.scene)?.raycast(origin: origin, direction: direction, length: length, query: .all) ?? []
    }
    func shutdown() {
        observations.removeAll()
        metalView?.isPaused = true; metalView?.delegate = nil
        renderer?.entities.removeAll(); renderer?.lighting.resource = nil
        legacy?.renderCallbacks.postProcess = nil
        legacy?.scene.anchors.removeAll(); legacy?.environment.lighting.resource = nil
        root = nil; camera = nil; sources = [nil, nil]; bloom = nil
        performanceInteraction = nil
        captures.forEach { $0(nil) }; captures.removeAll()
    }
    private func runPerformanceInteraction() {
        guard RoomPerformanceAudit.enabled else { return }
        let elapsed = CACurrentMediaTime() - createdAt
        if elapsed < Double(RoomPerformanceAudit.duration) {
            performanceInteraction?(elapsed.truncatingRemainder(dividingBy: 60))
        } else {
            performanceInteraction?(60)
            performanceInteraction = nil
        }
    }
}
