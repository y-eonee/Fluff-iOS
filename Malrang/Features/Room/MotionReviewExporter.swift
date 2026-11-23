#if DEBUG
import AVFoundation
import RealityKit
import SwiftUI

/// Isolated renderer for reviewing the exact production tracks without room occlusion.
/// Saves movies and timestamped stills; no saved dolls or room data are touched.
struct MotionReviewExporter: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: CGRect(x: 0, y: 0, width: 720, height: 480), cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(UIColor(white: 0.96, alpha: 1))
        view.renderOptions = [.disableMotionBlur, .disableDepthOfField, .disableCameraGrain]
        context.coordinator.task = Task { @MainActor in
            do { try await context.coordinator.export(view) }
            catch { try? String(describing: error).write(to: URL.documentsDirectory.appending(path: "MotionReview/error.txt"), atomically: true, encoding: .utf8) }
        }
        return view
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) { coordinator.task?.cancel(); uiView.scene.anchors.removeAll() }

    @MainActor final class Coordinator {
        var task: Task<Void, Never>?
        func export(_ view: ARView) async throws {
            let output = URL.documentsDirectory.appending(path: "MotionReview", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: output.appending(path: "complete.txt"))
            let anchor = AnchorEntity(world: .zero)
            var dolls: [Entity] = []
            for (index, shape) in [DollShape.cat, .bear, .rabbit].enumerated() {
                let state = DollState(id: UUID(), name: shape.rawValue, imageData: Data(), filling: .fluffy,
                                      position: [Float(index - 1) * 0.52, 0, 0], dance: nil,
                                      preset: PresetConfiguration(shape: shape))
                let doll = await SceneFactory.doll(state)
                doll.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
                anchor.addChild(doll); dolls.append(doll)
            }
            let camera = PerspectiveCamera(); camera.camera.fieldOfViewInDegrees = 32
            camera.look(at: [0, 0.27, 0], from: [0, 0.30, 2.15], relativeTo: nil)
            anchor.addChild(camera)
            for (position, intensity): (SIMD3<Float>, Float) in [([-2,3,4], 1600), ([2,1,3], 900)] {
                let light = DirectionalLight(); light.light.intensity = intensity
                light.look(at: [0,0.25,0], from: position, relativeTo: nil); anchor.addChild(light)
            }
            if let environment = await CozyRoomLighting.environmentResource(at: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!) {
                view.environment.lighting.resource = environment
            }
            view.environment.lighting.intensityExponent = -0.8
            view.scene.addAnchor(anchor)
            try await Task.sleep(for: .milliseconds(800))
            let rest = dolls.flatMap { MorningExerciseMotion.tracks(on: $0) }.map { ($0.entity, $0.entity.transform) }
            let fps: Int32 = 30
            let clips: [MorningExerciseMotion.Clip] = ProcessInfo.processInfo.arguments.contains("--review-new-motions")
                ? [.wiggle, .tapDance] : MorningExerciseMotion.Clip.allCases
            for clip in clips {
                for (entity, transform) in rest { entity.transform = transform }
                let tracks = dolls.flatMap { MorningExerciseMotion.tracks(on: $0, clip: clip) }
                let url = output.appending(path: "\(clip.name).mp4")
                try? FileManager.default.removeItem(at: url)
                let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
                let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
                    AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 720, AVVideoHeightKey: 480,
                    AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 2500000]])
                let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                    kCVPixelBufferWidthKey as String: 720, kCVPixelBufferHeightKey as String: 480,
                    kCVPixelBufferCGImageCompatibilityKey as String: true,
                    kCVPixelBufferCGBitmapContextCompatibilityKey as String: true])
                writer.add(input)
                guard writer.startWriting() else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
                writer.startSession(atSourceTime: .zero)
                let frameCount = Int((clip.duration * Double(fps)).rounded())
                for frame in 0..<frameCount {
                    try Task.checkCancellation()
                    let time = Double(frame) / Double(fps)
                    let index = min(tracks[0].frames.count - 1, Int((time * Double(MorningExerciseSequence.frameRate)).rounded()))
                    for track in tracks { track.entity.transform = track.frames[index] }
                    try await Task.sleep(for: .milliseconds(40))
                    guard let snapshot: UIImage = await withCheckedContinuation({ continuation in
                        view.snapshot(saveToHDR: false) { continuation.resume(returning: $0) }
                    }) else { throw CocoaError(.fileReadUnknown) }
                    let format = UIGraphicsImageRendererFormat(); format.scale = 1
                    let image = UIGraphicsImageRenderer(size: CGSize(width: 720, height: 480), format: format).image { context in
                        snapshot.draw(in: CGRect(x: 0, y: 0, width: 720, height: 480))
                        UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 720, height: 40))
                        let sourceTime = time + clip.sourceStart
                        let text = time > clip.sourceDuration ? "LOOP RESET (outside reference)" : String(format: "SOURCE %05.2fs", sourceTime)
                        ("\(clip.name)  ·  \(text)" as NSString).draw(at: CGPoint(x: 18, y: 12), withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: 15, weight: .medium), .foregroundColor: UIColor.darkGray])
                    }
                    if frame % 30 == 0 || (clip == .tapDance && frame % 3 == 0) || (clip == .wiggle && frame % 6 == 0) {
                        try image.pngData()?.write(to: output.appending(path: String(format: "%@-%05.2f.png", clip.name, time)))
                    }
                    while !input.isReadyForMoreMediaData {
                        try Task.checkCancellation()
                        guard writer.status == .writing else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
                        try await Task.sleep(for: .milliseconds(5))
                    }
                    var buffer: CVPixelBuffer?
                    guard let pool = adaptor.pixelBufferPool,
                          CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer) == kCVReturnSuccess, let buffer,
                          let cgImage = image.cgImage else { throw CocoaError(.fileWriteUnknown) }
                    CVPixelBufferLockBaseAddress(buffer, [])
                    let bitmap = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: 720, height: 480,
                        bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
                    bitmap.draw(cgImage, in: CGRect(x: 0, y: 0, width: 720, height: 480))
                    CVPixelBufferUnlockBaseAddress(buffer, [])
                    guard adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(frame), timescale: fps)) else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
                    if frame % 15 == 0 { try "\(clip.name) \(frame)/\(frameCount)".write(to: output.appending(path: "progress.txt"), atomically: true, encoding: .utf8) }
                }
                input.markAsFinished()
                writer.endSession(atSourceTime: CMTime(value: Int64(frameCount), timescale: fps))
                await writer.finishWriting()
                guard writer.status == .completed else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
            }
            try "Rendered selected production clips at 30 fps".write(to: output.appending(path: "complete.txt"), atomically: true, encoding: .utf8)
        }
    }
}
#endif
