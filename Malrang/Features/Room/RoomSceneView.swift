import Combine
import RealityKit
import SwiftUI

/// 위에서 비스듬히 내려다보는 3D 방.
/// 길게 눌러 끌기, 탭, 두 번 탭을 쓰려고 ARView(비 AR 모드)를 감싼다. RealityView에는 화면 좌표로 끌어 옮길 API가 없다.
struct RoomSceneView: UIViewRepresentable {
    enum Mode {
        /// 구경만 하고 인형 탭만 받는다
        case view
        /// 인형을 탭하거나 길게 눌러 옮긴다 (내 방)
        case home
        /// 가구를 길게 눌러 옮기거나 두 번 탭해 꾸민다 (방 꾸미기)
        case decorate
    }

    /// 완료 버튼이 화면에 남아 있는 실제 배치 좌표를 가져오는 UIKit 연결점.
    final class Placement {
        fileprivate var snapshot: (() -> [UUID: SIMD3<Float>])?
        fileprivate var capture: ((@escaping (UIImage?) -> Void) -> Void)?
        fileprivate var position: ((UUID) -> SIMD3<Float>?)?
        func currentPosition(of id: UUID) -> SIMD3<Float>? { position?(id) }
        fileprivate var pan: ((CGSize) -> Void)?
        fileprivate var cancel: (() -> Void)?
        func cancelDrag() { cancel?() }
        #if DEBUG
        fileprivate var audit: (() async -> [String])?
        func auditDrag() async -> [String] { await audit?() ?? ["FAIL: missing scene"] }
        #endif
        func look(by delta: CGSize) { pan?(delta) }
        func captureImage(_ completion: @escaping (UIImage?) -> Void) {
            guard let capture else { completion(nil); return }
            capture(completion)
        }

        func finish() -> [UUID: SIMD3<Float>] { snapshot?() ?? [:] }
    }

    var items: [RoomItemState]
    var dolls: [DollState] = []
    var mode = Mode.view
    /// 값이 있으면 방 없이 이 가구 하나만 가운데에 보여준다
    var focusItem: RoomItemState?
    var onTapDoll: (UUID) -> Void = { _ in }
    /// 내 방(home)에서는 새 인형을 배치하는 동안에만 인형을 끌 수 있다.
    var canMoveDolls = true
    /// Outside placement mode, moving requires a long press, never a tap or ordinary pan.
    var canLongPressDolls = false
    var dollRemovalTarget = CGRect.zero
    var onDropDoll: (UUID, SIMD3<Float>, Bool) -> Bool = { _, _, _ in false }
    var onCannotMoveDoll: () -> Void = {}
    var allowsDollWandering = false
    var movingDollID: UUID?
    var placement: Placement?
    var onPickDoll: (UUID) -> Void = { _ in }
    /// 인형을 들고 있는 동안 화면 위치와 놓일 자리를 알린다. 놓으면 nil.
    var onHoldDoll: (Hold?) -> Void = { _ in }
    var onMoveDoll: (UUID, SIMD3<Float>) -> Void = { _, _ in }
    var onBlockedPlacement: (FurnitureKind?) -> Void = { _ in }
    var onMoveItem: (UUID, SIMD2<Float>) -> Void = { _, _ in }
    var onDoubleTapItem: (UUID) -> Void = { _ in }
    var onTapBoard: () -> Void = {}
    /// 가구 하나를 보여줄 때 한 손가락으로 돌려 볼 수 있다. 사진을 꾸밀 때는 두 손가락으로 크기와 기울기도 바꾼다.
    var isPhotoEditing = false
    var onPinch: (CGFloat) -> Void = { _ in }
    /// 두 손가락으로 쓸 때마다 사진을 옮길 양(화면 너비를 1로 본 비율)을 알린다.
    var onPan: (CGSize) -> Void = { _ in }
    /// 꾸미기 화면에서 고른 가구. 테두리로 표시한다.
    var selectedItemID: UUID?
    /// 가구를 한 번 탭하면 그 가구의 id, 빈 곳을 탭하면 nil
    var onTapItem: (UUID?) -> Void = { _ in }
    /// 가구나 인형을 집거나 놓을 때 불린다. 화면이 이걸로 햅틱을 울린다.
    var onFeel: () -> Void = {}
    /// 시안 A처럼 방 뒤의 종이 배경이 보여야 할 때 장면 바탕을 투명하게 한다.
    var isTransparent = false
    /// 방 일러스트가 방 모습을 대신 보여줄 때, 가구와 벽은 보이지 않게 하고 눌러서 고르는 동작만 남긴다.
    var hidesRoom = false
    /// 시안 A의 방 일러스트와 모양이 맞도록 원근을 줄이고 낮춘 카메라로 본다. 값은 카메라가 바라볼 높이(m)로, 방이 화면에서 놓일 세로 위치를 정한다.
    var illustrationTargetY: Float?
    /// 홈 시안의 방 안을 바라보는 구도와 무광 입체 가구.
    var isCozyRoom = false
    /// 첫 번째 인형 머리 위의 화면 좌표. 인형이 없으면 nil. 말풍선이 인형을 따라다니게 한다.
    var onDollScreen: (CGPoint?) -> Void = { _ in }
    var onSleepSettled: (UUID) -> Void = { _ in }
    var onSceneReady: () -> Void = {}
    var onDeskScreen: (CGPoint?) -> Void = { _ in }
    var onFurnitureScreen: ([String: CGRect]) -> Void = { _ in }

    struct Hold: Equatable {
        /// 인형 머리 위 화면 좌표
        var screen: CGPoint
        var position: SIMD3<Float>
        var id: UUID
        var isOverRemovalTarget = false
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> ARView {
        let view = EfficientARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.renderOptions.formUnion([.disableMotionBlur, .disableDepthOfField, .disableCameraGrain])
        view.environment.background = .color(isTransparent ? .clear : UIColor(Color.app.background))
        view.backgroundColor = .clear
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.render(SceneState(items: items, dolls: dolls, focusItem: focusItem, selectedItemID: selectedItemID))
    }

    static func dismantleUIView(_ view: ARView, coordinator: Coordinator) {
        coordinator.stopRendering()
        view.renderCallbacks.postProcess = nil
        view.scene.anchors.removeAll()
        view.environment.lighting.resource = nil
    }

    struct SceneState: Equatable {
        var items: [RoomItemState]
        var dolls: [DollState]
        var focusItem: RoomItemState?
        var selectedItemID: UUID?
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: RoomSceneView
        private weak var view: ARView?
        private let root = AnchorEntity(world: .zero)
        private let camera = PerspectiveCamera()
        private let light = DirectionalLight()
        private var latest: SceneState?
        private var rendered: SceneState?
        private var displayed: SceneState?
        private var renderTask: Task<Void, Never>?
        private var drag: Drag?
        private var dragPoint = CGPoint.zero
        private var dropBlocked = false
        private var highlights: [Entity] = []
        private let lift: Float = 0.06
        private var aim: (target: SIMD3<Float>, width: Float, height: Float)?
        private var fittedSize = CGSize.zero
        private var wander: RoomDollWander?
        private var updateSubscription: (any Cancellable)?
        private var orbitYaw: Float = 0
        private var lastDollPoint: CGPoint?
        private var approachingBeds = Set<UUID>()
        private var restingTime: Float = 0
        private var restingBodies: [UUID: Entity] = [:]
        private var returningBeds: [UUID: UUID] = [:]
        private var lastLightingMinute: Int?
        private var lastLightingProfile: RoomDaylight?
        private var lightingTask: Task<Void, Never>?
        private var accessibleEntities: [(Entity, RoomAccessibilityElement)] = []
        private var roomHidden = false
        private var fitDistance: Float = 1
        private var lastStaticProjection: (camera: Transform, content: Transform, size: CGSize)?
        /// 방을 두 손가락으로 확대한 정도와 옮긴 위치. 방을 잃어버리지 않게 범위를 제한한다.
        private var zoom: Float = 1
        private var shift = SIMD3<Float>.zero
        private weak var shiftPan: UIPanGestureRecognizer?
        private weak var dollPan: UIPanGestureRecognizer?
        private lazy var cameraDirection = parent.isCozyRoom
            ? simd_normalize(SIMD3<Float>(1.1, 1.1, 1.5))
            : simd_normalize(SIMD3<Float>(1, parent.illustrationTargetY == nil ? 0.9 : 0.85, 1))

        private struct Drag {
            let entity: Entity
            let id: UUID
            let isDoll: Bool
            let start: SIMD3<Float>
        }

        init(parent: RoomSceneView) {
            self.parent = parent
        }

        func attach(to view: ARView) {
            self.view = view
            parent.placement?.position = { [weak self] id in self?.root.findEntity(named: "doll|\(id)")?.position }
            parent.placement?.cancel = { [weak self] in
                guard let self else { return }
                self.endDrag(at: self.dragPoint, ended: false)
            }
            #if DEBUG
            parent.placement?.audit = { [weak self] in await self?.auditDirectDrag() ?? ["FAIL: released scene"] }
            #endif
            parent.placement?.snapshot = { [weak self] in self?.finishPlacement() ?? [:] }
            parent.placement?.pan = { [weak self] delta in self?.moveCamera(by: CGPoint(x: delta.width, y: delta.height)) }
            parent.placement?.capture = { [weak view] completion in
                guard let view else { completion(nil); return }
                view.snapshot(saveToHDR: false, completion: completion)
            }
            orbitYaw = parent.focusItem.map { $0.kind.isMovable && !$0.kind.hangsOnWall ? $0.yaw : 0 } ?? 0
            view.scene.addAnchor(root)
            camera.camera.fieldOfViewInDegrees = (parent.isCozyRoom && parent.mode != .decorate) ? 42 : (parent.illustrationTargetY == nil ? 30 : 4)
            light.light.intensity = parent.isCozyRoom ? 1250 : 2500
            if parent.isCozyRoom {
                (view as? EfficientARView)?.configureBloom()
                light.light.color = Palette.uiColor("#FFE8DE")
                view.environment.background = .color(parent.mode == .decorate ? .clear : Palette.uiColor("#FFFFF4"))
                view.environment.lighting.intensityExponent = 0.05
            }
            light.shadow = DirectionalLightComponent.Shadow(maximumDistance: 6, depthBias: 2)
            light.look(at: .zero, from: parent.isCozyRoom ? [-0.6, 3, 2] : [1.5, 3, 2], relativeTo: nil)

            // 화면 크기가 정해지거나 바뀌면 카메라 거리를 다시 맞춘다.
            updateSubscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
                MainActor.assumeIsolated {
                    if let self {
                        self.wander?.update(delta: event.deltaTime, running: self.parent.allowsDollWandering
                            && self.parent.mode == .home && !self.parent.canMoveDolls && self.drag == nil
                            && !UIAccessibility.isReduceMotionEnabled
                            && UIApplication.shared.applicationState == .active)
                    }
                    if let self {
                        self.restingTime += Float(min(event.deltaTime, 0.1))
                        if !UIAccessibility.isReduceMotionEnabled {
                            for (id, body) in self.restingBodies where !self.approachingBeds.contains(id) {
                                body.scale.z = 1 + sin(self.restingTime * 1.7) * 0.012
                            }
                        }
                    }
                    self?.fitCamera()
                    if let self {
                        self.overlayElapsed += event.deltaTime
                        if self.overlayElapsed >= 0.1 {
                            self.overlayElapsed = 0
                            self.updateDaylight()
                            self.reportDollScreen()
                            self.reportStaticScreenGeometry()
                            if UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning {
                                self.updateAccessibilityFrames()
                            }
                        }
                    }
                }
            }

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            view.addGestureRecognizer(tap)
            if parent.mode == .decorate || parent.mode == .home {
                let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
                doubleTap.numberOfTapsRequired = 2
                tap.require(toFail: doubleTap)
                view.addGestureRecognizer(doubleTap)
            }
            if parent.focusItem != nil {
                let orbit = UIPanGestureRecognizer(target: self, action: #selector(handleOrbit))
                orbit.maximumNumberOfTouches = 1
                let movePan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
                movePan.minimumNumberOfTouches = 2
                movePan.delegate = self
                let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
                pinch.delegate = self
                [orbit, movePan, pinch].forEach(view.addGestureRecognizer)
            }
            if parent.focusItem == nil {
                let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRoomRotation))
                rotation.delegate = self
                view.addGestureRecognizer(rotation)
                let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleZoom))
                let pan = UIPanGestureRecognizer(target: self, action: #selector(handleShift))
                pan.maximumNumberOfTouches = 1
                shiftPan = pan
                [pinch, pan].forEach {
                    $0.delegate = self
                    view.addGestureRecognizer($0)
                }
            }
            if parent.mode != .view {
                let press = UILongPressGestureRecognizer(target: self, action: #selector(handlePress))
                press.minimumPressDuration = 0.35
                press.delegate = self
                view.addGestureRecognizer(press)
                let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePress))
                pan.maximumNumberOfTouches = 1
                pan.delegate = self
                dollPan = pan
                pan.require(toFail: press)
                // 바로 끌 때는 pan, 잠시 눌렀다가 끌 때는 long press가 같은 이동 처리를 쓴다.
                view.addGestureRecognizer(pan)
            }
        }

        func stopRendering() {
            lightingTask?.cancel(); lightingTask = nil; lastLightingMinute = nil
            lastLightingProfile = nil
            wander = nil
            approachingBeds.removeAll()
            restingBodies.removeAll()
            renderTask?.cancel()
            renderTask = nil
            updateSubscription?.cancel()
            updateSubscription = nil
            parent.placement?.position = nil
            parent.placement?.cancel = { [weak self] in
                guard let self else { return }
                self.endDrag(at: self.dragPoint, ended: false)
            }
            #if DEBUG
            parent.placement?.audit = { [weak self] in await self?.auditDirectDrag() ?? ["FAIL: released scene"] }
            #endif
            parent.placement?.snapshot = nil
            parent.placement?.capture = nil
            parent.placement?.pan = nil
            parent.placement?.cancel = nil
            #if DEBUG
            parent.placement?.audit = nil
            #endif
            root.stopAllAnimations(recursive: true)
            root.children.removeAll()
            highlights.removeAll()
            accessibleEntities.removeAll()
            latest = nil; rendered = nil; displayed = nil
            lastStaticProjection = nil
            drag = nil
        }

        func render(_ state: SceneState) {
            if parent.mode == .home && !parent.canMoveDolls && !parent.canLongPressDolls && drag != nil {
                // 완료를 먼저 눌러도 든 인형을 편집 좌표에 내려놓고, 늦게 끝난 제스처는 무시한다.
                drag = nil
                parent.onHoldDoll(nil)
                highlights.forEach { $0.removeFromParent() }
                highlights = []
                rendered = nil
            }
            latest = state
            if parent.hidesRoom != roomHidden {
                roomHidden = parent.hidesRoom
                applyRoomHidden()
            }
            guard state != rendered, drag == nil else { return }
            rendered = state
            renderTask?.cancel()
            renderTask = Task { await build(state) }
        }

        /// 이미 그려진 방의 가구와 벽을 다시 만들지 않고 바로 보이게 하거나 숨긴다. (끌고 있는 동안에도 쓴다)
        private func applyRoomHidden() {
            guard let content = root.children.first else { return }
            for child in content.children where child.name.hasPrefix("item|") || child.name == "board" {
                if roomHidden {
                    child.components.set(OpacityComponent(opacity: 0))
                } else {
                    child.components.remove(OpacityComponent.self)
                }
            }
        }

        private func build(_ state: SceneState) async {
            lightingTask?.cancel(); lightingTask = nil
            approachingBeds.formIntersection(Set(state.dolls.filter { $0.restingBedID != nil }.map(\.id)))
            if parent.isCozyRoom, let environment = await CozyRoomLighting.environmentResource(at: RoomDaylight.currentDate) {
                view?.environment.lighting.resource = environment
            }
            let previous = displayed
            var settling: [(Entity, RoomItemState)] = []
            var sitting: [(Entity, RoomItemState, SIMD3<Float>, SIMD3<Float>)] = []
            var waking: [(Entity, RoomItemState, SIMD3<Float>)] = []
            let content = Entity()
            if var item = state.focusItem {
                (item.x, item.z) = (0, 0)
                if !item.kind.hangsOnWall { item.yaw = 0 }
                content.addChild(await SceneFactory.furniture(item, onFloor: true, cozy: parent.isCozyRoom, cutaway: parent.isCozyRoom))
                let size = item.kind.size
                aimCamera(at: [0, size.y / 2, 0], fitting: max(size.x, size.z) * 1.6, height: size.y * 1.4)
            } else {
            for item in state.items {
                    guard !Task.isCancelled else { return }
                    let furniture = await SceneFactory.furniture(item, elevation: RoomLayout.furnitureHeight(item, in: state.items), cozy: parent.isCozyRoom, cutaway: parent.mode == .decorate)
                    if roomHidden { furniture.components.set(OpacityComponent(opacity: 0)) }
                    if item.kind == .bed { DollRestPose.bedding(furniture, pose: .made, animated: false) }
                    content.addChild(furniture)
                }
                for var doll in state.dolls {
                    guard !Task.isCancelled else { return }
                    // 가구 위에 있는 인형은 그 윗면에 서고, 가구가 치워졌으면 바닥으로 내려온다.
                    let support = RoomLayout.seat(at: [doll.position.x, doll.position.z], in: state.items, sleepingBeds: Set(state.dolls.compactMap(\.restingBedID)), includingActivitySeats: doll.couchCompanionScale != nil)
                    doll.position.y = support.height
                    let model = await SceneFactory.doll(doll)
                    if doll.restingBedID == nil,
                       let seat = support.item,
                       seat.kind == .bed || seat.kind == .chair || doll.couchCompanionScale != nil {
                        var seatScale = model.scale
                        if let scale = doll.couchCompanionScale {
                            let width = model.visualBounds(relativeTo: model).extents.x
                            seatScale = SIMD3(repeating: min(scale, (scale < 0.7 ? 0.20 : 0.34) / max(width, 0.01)))
                        }
                        if doll.couchCompanionScale != nil, previous != nil,
                           previous?.dolls.first(where: { $0.id == doll.id })?.couchCompanionScale == nil,
                           let live = root.findEntity(named: "doll|\(doll.id)") {
                            let destination = doll.position
                            model.transform = live.transform
                            sitting.append((model, seat, destination, seatScale))
                        } else {
                            model.scale = seatScale
                            DollRestPose.sitting(model)
                            model.orientation = simd_quatf(angle: seat.yaw, axis: [0, 1, 0])
                            if seat.kind == .chair { DollRestPose.chairSeat(model, on: seat) }
                        }
                    }
                    if let bedID = doll.restingBedID, let bed = state.items.first(where: { $0.id == bedID && $0.kind == .bed }) {
                        if previous != nil && (previous?.dolls.first(where: { $0.id == doll.id })?.restingBedID == nil || approachingBeds.contains(doll.id)) {
                            approachingBeds.insert(doll.id)
                            if let live = root.findEntity(named: "doll|\(doll.id)") { model.transform = live.transform }
                            else if let old = previous?.dolls.first(where: { $0.id == doll.id }) { model.position = old.position }
                            settling.append((model, bed))
                        } else {
                            DollRestPose.sleeping(model, bed: bed, animated: false)
                            DollRestPose.bedding(content.findEntity(named: "item|\(bed.id)"), pose: .covered, animated: false)
                        }
                    }
                    if doll.restingBedID == nil,
                       let bedID = returningBeds[doll.id] ?? previous?.dolls.first(where: { $0.id == doll.id })?.restingBedID,
                       let bed = state.items.first(where: { $0.id == bedID }),
                       DollBedRoute.plan(from: doll.position, bed: bed, items: state.items) != nil {
                        let destination = doll.position
                        model.position = DollRestPose.bedPosition(bed)
                        DollRestPose.bedding(content.findEntity(named: "item|\(bed.id)"), pose: .covered, animated: false)
                        returningBeds[doll.id] = bedID
                        waking.append((model, bed, destination))
                    }
                    content.addChild(model)
                }
                if let selected = state.items.first(where: { $0.id == state.selectedItemID }), selected.kind.isMovable {
                    content.addChild(SceneFactory.selectionBox(selected))
                }
                if parent.isCozyRoom {
                    if parent.mode == .decorate { aimCamera(at: [0, 0.55, 0], fitting: 3.3, height: 2.9) }
                    else { aimCamera(at: [-0.10, 0.36, -0.18], fitting: 1.90, height: 3.0) }
                    content.addChild(CozyRoomLighting.sunlight())
                } else {
                    aimCamera(at: [0, parent.illustrationTargetY ?? 0.45, 0], fitting: parent.illustrationTargetY == nil ? 3.3 : 3.55, height: parent.illustrationTargetY == nil ? 3.1 : 2.9)
                }
            }
            guard !Task.isCancelled else { return }
            wander = nil
            root.children.removeAll()
            highlights = []
            content.orientation = simd_quatf(angle: orbitYaw, axis: [0, 1, 0])
            if parent.isCozyRoom {
                let date = RoomDaylight.currentDate
                let profile = RoomDaylight.at(date)
                await CozyRoomLighting.apply(profile, to: content)
                configureDaylight(profile)
                lastLightingProfile = profile
                lastLightingMinute = Int(date.timeIntervalSince1970 / 60)
            }
            guard !Task.isCancelled else { return }
            root.addChild(content)
            root.addChild(camera)
            root.addChild(light)


            displayed = state
            restingBodies = Dictionary(uniqueKeysWithValues: state.dolls.compactMap { doll in
                guard doll.restingBedID != nil, let body = content.findEntity(named: "doll|\(doll.id)")?.findEntity(named: "body") else { return nil }
                return (doll.id, body)
            })
            lastStaticProjection = nil
            configureAccessibility(content)
            parent.onSceneReady()
            for doll in state.dolls where doll.restingBedID != nil && !approachingBeds.contains(doll.id) { parent.onSleepSettled(doll.id) }
            for (model, seat, destination, scale) in sitting {
                await DollBedMotion.walkAndSit(model, seat: seat, destination: destination, scale: scale, items: state.items)
                guard !Task.isCancelled else { return }
            }
            for (model, bed, destination) in waking {
                await DollBedMotion.wakeAndReturn(model, bed: bed, bedding: content.findEntity(named: "item|\(bed.id)"), destination: destination, items: state.items)
                guard !Task.isCancelled else { return }
                if let id = Self.parse(model.name)?.id { returningBeds[id] = nil; parent.onSleepSettled(id) }
            }
            for (model, bed) in settling {
                await DollBedMotion.walkAndSleep(model, bed: bed, bedding: content.findEntity(named: "item|\(bed.id)"), items: state.items)
                if !Task.isCancelled, let id = Self.parse(model.name)?.id { approachingBeds.remove(id); parent.onSleepSettled(id) }

            }
            if !Task.isCancelled, parent.mode == .home {
                wander = RoomDollWander(content: content, states: state.dolls, items: state.items)
            }
        }

        private func updateDaylight() {
            guard parent.isCozyRoom, let content = root.children.first else { return }
            let date = RoomDaylight.currentDate
            let minute = Int(date.timeIntervalSince1970 / 60)
            guard minute != lastLightingMinute else { return }
            lastLightingMinute = minute
            let profile = RoomDaylight.at(date)
            if let previous = lastLightingProfile, previous.phase == profile.phase,
               previous.strength == profile.strength, previous.tint == profile.tint { return }
            lightingTask?.cancel()
            lightingTask = Task { [weak self, weak content] in
                guard let self, let content else { return }
                let environment = await CozyRoomLighting.environmentResource(at: date)
                guard !Task.isCancelled else { return }
                self.view?.environment.lighting.resource = environment
                self.configureDaylight(profile)
                await CozyRoomLighting.apply(profile, to: content)
                if !Task.isCancelled { self.lastLightingProfile = profile }
            }
        }

        private func configureDaylight(_ profile: RoomDaylight) {
            view?.environment.lighting.intensityExponent = profile.phase == .night ? 0.15 : 0.05
            light.light.color = UIColor(red: CGFloat(0.65 + 0.35 * profile.tint.x), green: CGFloat(0.65 + 0.35 * profile.tint.y), blue: CGFloat(0.65 + 0.35 * profile.tint.z), alpha: 1)
            light.light.intensity = 650 + 600 * profile.strength
        }

        private func finishPlacement() -> [UUID: SIMD3<Float>] {
            var positions: [UUID: SIMD3<Float>] = [:]
            let items = latest?.items ?? []
            for entity in root.children.first.map({ Array($0.children) }) ?? [] {
                guard let parsed = Self.parse(entity.name), parsed.isDoll else { continue }
                var point = entity.position
                let requested = latest?.dolls.first { $0.id == parsed.id }?.position
                let shown = displayed?.dolls.first { $0.id == parsed.id }?.position
                // 탭 배치의 새 장면이 아직 준비 중이면, 표시 전의 이전 좌표를 저장하지 않는다.
                if drag?.entity !== entity, requested != shown, let requested { point = requested }
                point.y = RoomLayout.seat(at: [point.x, point.z], in: items, sleepingBeds: Set(latest?.dolls.compactMap(\.restingBedID) ?? [])).height
                positions[parsed.id] = point
            }
            // SwiftUI 갱신 전에도 늦게 들어온 배치 터치를 즉시 차단한다.
            parent.canMoveDolls = false
            parent.movingDollID = nil
            // 완료 뒤 늦게 끝나는 끌기나 이전 장면의 생성 작업이 좌표를 되돌리지 않게 한다.
            renderTask?.cancel()
            drag = nil
            highlights.forEach { $0.removeFromParent() }
            highlights = []
            if var state = latest {
                for index in state.dolls.indices {
                    if let point = positions[state.dolls[index].id] { state.dolls[index].position = point }
                }
                latest = state
            }
            rendered = nil
            return positions
        }

        private func configureAccessibility(_ content: Entity) {
            guard let view else { return }
            accessibleEntities = content.children.compactMap { entity in
                let element = RoomAccessibilityElement(accessibilityContainer: view)
                element.accessibilityTraits = .button
                if entity.name == "board" {
                    element.accessibilityLabel = "메모보드, 방명록 열기"
                    element.activate = { [weak self] in self?.parent.onTapBoard() }
                } else if let parsed = Self.parse(entity.name), parsed.isDoll,
                          let doll = latest?.dolls.first(where: { $0.id == parsed.id }) {
                    element.accessibilityLabel = doll.name
                    if parent.mode == .home, doll.restingBedID == nil {
                        element.accessibilityHint = "길게 누른 뒤 끌어서 이동하거나 하단 휴지통에 놓아 방에서 뺄 수 있어요"
                        element.accessibilityCustomActions = [
                            UIAccessibilityCustomAction(name: "바닥의 빈자리로 옮기기") { [weak self] _ in
                                guard let self, let state = self.latest else { return false }
                                let spot = RoomLayout.dollSpot(avoiding: state.items, dolls: state.dolls.map(\.position))
                                return self.accessibleDrop(parsed.id, position: spot, store: false)
                            },
                            UIAccessibilityCustomAction(name: "방에서 빼기") { [weak self] _ in
                                self?.accessibleDrop(parsed.id, position: doll.position, store: true) ?? false
                            }
                        ]
                    }
                    element.activate = { [weak self] in
                        guard let self else { return }
                        if self.parent.mode == .home && self.parent.canMoveDolls { self.parent.onPickDoll(parsed.id) }
                        else { self.parent.onTapDoll(parsed.id) }
                    }
                } else if parent.mode == .home,
                          let parsed = Self.parse(entity.name), !parsed.isDoll,
                          item(parsed.id)?.kind == .desk {
                    element.accessibilityLabel = "책상, 함께 집중하기"
                    element.activate = { [weak self] in
                        guard let self, !self.parent.canMoveDolls else { return }
                        self.parent.onTapItem(parsed.id)
                    }
                } else if parent.mode == .home,
                          let parsed = Self.parse(entity.name), !parsed.isDoll,
                          let kind = item(parsed.id)?.kind, [.wall, .bed, .frame].contains(kind) {
                    element.accessibilityLabel = kind == .wall ? "창문, 같이 바깥 구경하기" : kind == .bed ? "침대, 재우기와 깨우기" : "액자, 사진과 AR"
                    element.activate = { [weak self] in
                        guard let self, !self.parent.canMoveDolls else { return }
                        self.parent.onDoubleTapItem(parsed.id)
                    }
                } else { return nil }
                return (entity, element)
            }
            view.isAccessibilityElement = false
            view.accessibilityElements = accessibleEntities.map(\.1)
            updateAccessibilityFrames()
        }

        private func accessibleDrop(_ id: UUID, position: SIMD3<Float>?, store: Bool) -> Bool {
            guard parent.mode == .home, parent.canLongPressDolls,
                  let doll = latest?.dolls.first(where: { $0.id == id }), doll.restingBedID == nil,
                  let position, parent.onDropDoll(id, position, store) else { return false }
            return true
        }

        private var lastAccessibilityUpdate = Date.distantPast
        private func updateAccessibilityFrames() {
            let now = Date.now
            guard now.timeIntervalSince(lastAccessibilityUpdate) >= 0.15 else { return }
            lastAccessibilityUpdate = now
            guard let view else { return }
            for (entity, element) in accessibleEntities {
                let size: SIMD3<Float>
                if let parsed = Self.parse(entity.name) {
                    size = parsed.isDoll ? [0.3, SceneFactory.dollHeight, 0.3] : (item(parsed.id)?.kind.size ?? [0.3, 0.3, 0.3])
                } else { size = [0.4, 0.4, 0.08] }
                var points: [CGPoint] = []
                for x: Float in [-1, 1] {
                    for y: Float in [-1, 1] {
                        for z: Float in [-1, 1] {
                            let corner = entity.convert(position: SIMD3<Float>(0, size.y / 2, 0) + size * SIMD3(x, y, z) / 2, to: nil)
                            if let point = view.project(corner) { points.append(point) }
                        }
                    }
                }
                guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
                      let minY = points.map(\.y).min(), let maxY = points.map(\.y).max() else { continue }
                let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                element.accessibilityFrameInContainerSpace = rect.insetBy(dx: -8, dy: -8)
            }
        }

        private func aimCamera(at target: SIMD3<Float>, fitting width: Float, height: Float) {
            aim = (target, width, height)
            fittedSize = .zero
            fitCamera()
        }

        /// 화면 비율에 맞춰 aim의 너비(m)와 높이(m)가 모두 보이는 거리로 카메라를 둔다.
        private func fitCamera() {
            guard let view, let aim, view.bounds.size != fittedSize, view.bounds.height > 0 else { return }
            fittedSize = view.bounds.size
            let aspect = Float(view.bounds.width / view.bounds.height)
            let tanHalf = tan(camera.camera.fieldOfViewInDegrees / 2 * .pi / 180)
            let horizontal = aim.width / 2 / (tanHalf * aspect)
            let vertical = aim.height / 2 / tanHalf
            let distance = max(horizontal, vertical)
            fitDistance = distance
            placeCamera()
        }

        private var overlayElapsed: TimeInterval = 0
        private var lastFurnitureRects: [String: CGRect] = [:]
        private func reportStaticScreenGeometry() {
            guard let view, let content = root.children.first else { return }
            let current = (camera: camera.transform, content: content.transform, size: view.bounds.size)
            if drag?.isDoll != false, let last = lastStaticProjection,
               last.camera == current.camera, last.content == current.content, last.size == current.size { return }
            lastStaticProjection = current
            reportDeskScreen()
            reportFurnitureScreen()
        }

        private func reportFurnitureScreen() {
            guard let view, let content = root.children.first, let state = displayed else { return }
            var rects: [String: CGRect] = [:]
            for item in state.items where item.kind.hasHomeInteraction {
                guard let entity = content.findEntity(named: "item|\(item.id)") else { continue }
                let points: [SIMD3<Float>]
                let key: String
                if item.kind == .wall {
                    key = "창문"; points = [[-0.92, 0.43, -0.28], [-0.92, 1.48, 0.38]]
                } else if item.kind == .desk || item.kind == .sofa {
                    key = item.kind == .sofa ? "소파" : item.kind.label
                    let size = item.kind.size
                    points = [-1 as Float, 1].flatMap { x in
                        [0 as Float, 1].flatMap { y in
                            [-1 as Float, 1].map { z in SIMD3(x * size.x / 2, y * size.y, z * size.z / 2) }
                        }
                    }
                } else {
                    key = item.kind.label
                    let size = item.kind.size
                    points = [[-size.x / 2, 0, -size.z / 2], [size.x / 2, size.y, size.z / 2]]
                }
                let screen = points.compactMap { view.project(entity.convert(position: $0, to: nil)) }
                if screen.count >= 2 {
                    let xs = screen.map(\.x), ys = screen.map(\.y)
                    let minX = xs.min()!, minY = ys.min()!
                    rects[key] = CGRect(x: minX, y: minY, width: max(44, xs.max()! - minX), height: max(44, ys.max()! - minY))
                }
            }
            if rects != lastFurnitureRects {
                lastFurnitureRects = rects
                parent.onFurnitureScreen(rects)
            }
        }

        private var lastDeskPoint: CGPoint?
        private func reportDeskScreen() {
            guard let view, let desk = latest?.items.first(where: { $0.kind == .desk }),
                  let entity = root.findEntity(named: "item|\(desk.id)"),
                  let point = view.project(entity.convert(position: [0.05, (FurnitureKind.desk.seatHeight ?? 0.47) + 0.04, 0.15], to: nil)) else {
                if lastDeskPoint != nil { lastDeskPoint = nil; parent.onDeskScreen(nil) }
                return
            }
            if let last = lastDeskPoint, hypot(last.x - point.x, last.y - point.y) < 1 { return }
            lastDeskPoint = point
            parent.onDeskScreen(point)
        }

        private func reportDollScreen() {
            guard let view else { return }
            let doll = root.children.first?.children.first { $0.name.hasPrefix("doll|") }
            guard let doll, let point = view.project(doll.position(relativeTo: nil) + [0, SceneFactory.dollHeight + 0.03, 0]) else {
                if lastDollPoint != nil {
                    lastDollPoint = nil
                    parent.onDollScreen(nil)
                }
                return
            }
            if let last = lastDollPoint, hypot(last.x - point.x, last.y - point.y) < 1 { return }
            lastDollPoint = point
            parent.onDollScreen(point)
        }

        private func placeCamera() {
            guard let aim else { return }
            let target = aim.target + shift
            let distance = fitDistance / zoom
            camera.camera.near = parent.isCozyRoom ? 0.01 : max(0.01, distance - 3)
            camera.camera.far = distance + 6
            // 좁은 화각에서는 카메라가 멀리 물러난다. 그림자 범위도 실제 방까지 닿아야 한다.
            light.shadow = DirectionalLightComponent.Shadow(maximumDistance: distance + 4, depthBias: 1)

            camera.look(at: target, from: target + cameraDirection * distance, relativeTo: nil)
        }

        @objc private func handleZoom(_ gesture: UIPinchGestureRecognizer) {
            guard drag == nil else { return }
            zoom = min(2.5, max(1, zoom * Float(gesture.scale)))
            gesture.scale = 1
            if zoom == 1 { shift = .zero }
            placeCamera()
        }

        /// 홈에서는 확대하지 않아도 한 손가락으로 둘러본다.
        @objc private func handleShift(_ gesture: UIPanGestureRecognizer) {
            guard let view, (zoom > 1 || (parent.mode == .home && !parent.canMoveDolls)), drag == nil, view.bounds.height > 0 else { return }
            let move = gesture.translation(in: view)
            gesture.setTranslation(.zero, in: view)
            moveCamera(by: move)
        }

        private func moveCamera(by move: CGPoint) {
            guard let view, view.bounds.height > 0, drag == nil else { return }
            let tanHalf = tan(camera.camera.fieldOfViewInDegrees / 2 * .pi / 180)
            let metersPerPoint = 2 * fitDistance / zoom * tanHalf / Float(view.bounds.height)
            let root2 = Float(0.5).squareRoot()
            let right = SIMD3<Float>(1, 0, -1) * root2
            let away = SIMD3<Float>(-1, 0, -1) * root2
            let dx = Float(move.x) * metersPerPoint
            let dy = Float(move.y) * metersPerPoint
            shift += away * dy - right * dx
            let limit: Float = parent.mode == .home ? 0.30 : 1
            shift = simd_clamp(shift, SIMD3(repeating: -limit), SIMD3(repeating: limit))
            placeCamera()
        }

        // MARK: 제스처

        /// 둘러보기와 인형 배치가 같은 드래그를 처리하지 않게 한다.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer is UILongPressGestureRecognizer {
                guard let view, let hit = target(at: gestureRecognizer.location(in: view)) else { return false }
                return canDrag(hit)
            }
            if gestureRecognizer === dollPan {
                guard parent.mode != .home || parent.canMoveDolls else { return false }
                guard let view, let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
                let location = pan.location(in: view), delta = pan.translation(in: view)
                guard let hit = target(at: CGPoint(x: location.x - delta.x, y: location.y - delta.y)) else { return false }
                return (hit.isDoll || parent.mode == .decorate) && canDrag(hit)
            }
            guard gestureRecognizer === shiftPan else { return true }
            if parent.mode == .home && parent.placement != nil && !parent.canMoveDolls { return false }
            guard (zoom > 1 || (parent.mode == .home && !parent.canMoveDolls)), drag == nil else { return false }
            if let view, let hit = target(at: gestureRecognizer.location(in: view)), canDrag(hit) {
                return false
            }
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            if gestureRecognizer === dollPan || other === dollPan { return false }
            return true
        }

        @objc private func handleRoomRotation(_ gesture: UIRotationGestureRecognizer) {
            guard drag == nil else { return }
            cameraDirection = simd_act(simd_quatf(angle: -Float(gesture.rotation), axis: [0, 1, 0]), cameraDirection)
            gesture.rotation = 0
            placeCamera()
        }

        @objc private func handleOrbit(_ gesture: UIPanGestureRecognizer) {
            guard let view else { return }
            orbitYaw += Float(gesture.translation(in: view).x) * 0.01
            gesture.setTranslation(.zero, in: view)
            root.children.first?.orientation = simd_quatf(angle: orbitYaw, axis: [0, 1, 0])
        }

        /// 두 손가락으로 쓸면 사진이 그 방향으로 옮겨진다.
        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view, parent.isPhotoEditing else { return }
            let move = gesture.translation(in: view)
            parent.onPan(CGSize(width: move.x / view.bounds.width, height: move.y / view.bounds.width))
            gesture.setTranslation(.zero, in: view)
        }

        @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard parent.isPhotoEditing else { return }
            parent.onPinch(gesture.scale)
            gesture.scale = 1
        }

        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view else { return }
            let point = gesture.location(in: view)
            let collisions = hits(at: point)
            if collisions.contains(where: { isBoard($0.entity) }) {
                parent.onTapBoard()
                return
            }
            if parent.mode == .home, parent.canMoveDolls {
                if let hit = target(at: point), hit.isDoll {
                    parent.onPickDoll(hit.id)
                } else if let id = parent.movingDollID, let entity = root.findEntity(named: "doll|\(id)"),
                          let spot = dollSpot(at: point, excluding: entity) {
                    recordDollMove(id, to: spot)
                    rendered = nil
                    if let latest { render(latest) }
                    parent.onFeel()
                }
                return
            }
            if parent.mode == .decorate {
                if let hit = target(at: point), !hit.isDoll { parent.onTapItem(hit.id) } else { parent.onTapItem(nil) }
                return
            }
            if let hit = target(at: point, includeFurniture: true) {
                if hit.isDoll { parent.onTapDoll(hit.id) }
                else if parent.mode == .home { parent.onTapItem(hit.id) }
            }
        }

        private func isBoard(_ entity: Entity?) -> Bool {
            var current = entity
            while let entity = current {
                if entity.name == "board" { return true }
                current = entity.parent
            }
            return false
        }

        @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let view, let hit = target(at: gesture.location(in: view), includeFurniture: true), !hit.isDoll else { return }
            parent.onDoubleTapItem(hit.id)
        }

        @objc private func handlePress(_ gesture: UIGestureRecognizer) {
            guard let view else { return }
            let point = gesture.location(in: view)
            switch gesture.state {
            case .began:
                let delta = (gesture as? UIPanGestureRecognizer)?.translation(in: view) ?? .zero
                beginDrag(at: CGPoint(x: point.x - delta.x, y: point.y - delta.y))
            case .changed: updateDrag(at: point)
            case .ended: endDrag(at: point, ended: true)
            case .cancelled, .failed: endDrag(at: point, ended: false)
            default: break
            }
        }

        private func beginDrag(at point: CGPoint) {
            guard drag == nil, let hit = target(at: point), canDrag(hit) else { return }
            if hit.isDoll, latest?.dolls.first(where: { $0.id == hit.id })?.restingBedID != nil {
                parent.onCannotMoveDoll(); return
            }
            // A pending rebuild must not replace the entity underneath the finger.
            renderTask?.cancel()
            hit.entity.stopAllAnimations(recursive: true)
            parent.onFeel()
            dragPoint = point; dropBlocked = false
            drag = Drag(entity: hit.entity, id: hit.id, isDoll: hit.isDoll, start: hit.entity.position)
            if hit.isDoll {
                hit.entity.position.y += lift
                holdOut(hit.entity)
                showSeatHighlights()
                parent.onPickDoll(hit.id)
                report(hit.entity)
            }
        }

        private var overRemovalTarget: Bool {
            guard parent.mode == .home, !parent.canMoveDolls, let view else { return false }
            return DollDropAction.isOverStorage(view.convert(dragPoint, to: nil), target: parent.dollRemovalTarget)
        }

        private func updateDrag(at point: CGPoint) {
            guard let drag else { return }
            dragPoint = point
            if drag.isDoll {
                drag.entity.isEnabled = !overRemovalTarget
                if !overRemovalTarget {
                    if let spot = dollSpot(at: point, excluding: drag.entity) {
                        drag.entity.position = spot + [0, lift, 0]
                        dropBlocked = false
                    } else { dropBlocked = true }
                }
                // Always report pointer changes, even over furniture that rejects placement.
                report(drag.entity)
            } else if let moving = item(drag.id), let floor = furniturePoint(at: point, for: moving) {
                let snapped = RoomLayout.snapped(floor, for: moving.kind, yaw: moving.yaw)
                if moving.kind.hangsOnWall {
                    var hung = moving; (hung.x, hung.z) = (snapped.x, snapped.y)
                    drag.entity.position = [snapped.x, moving.kind.hangingHeight, snapped.y]
                    drag.entity.orientation = simd_quatf(angle: RoomLayout.wall(of: hung).yaw, axis: [0, 1, 0])
                } else {
                    var placed = moving; (placed.x, placed.z) = (snapped.x, snapped.y)
                    drag.entity.position = [snapped.x, RoomLayout.furnitureHeight(placed, in: rendered?.items ?? []), snapped.y]
                }
            }
        }

        private func endDrag(at point: CGPoint, ended: Bool) {
            guard let drag else { return }
            dragPoint = point
            let action = DollDropAction.resolve(ended: ended, overStorage: overRemovalTarget, blocked: dropBlocked)
            self.drag = nil
            drag.entity.isEnabled = true
            parent.onFeel()
            highlights.forEach { $0.removeFromParent() }; highlights = []
            if drag.isDoll, parent.mode == .home, !parent.canMoveDolls {
                let position = drag.entity.position - [0, lift, 0]
                let accepted = action != .cancel && parent.onDropDoll(drag.id, position, action == .store)
                if accepted, action == .store {
                    latest?.dolls.removeAll { $0.id == drag.id }
                    drag.entity.removeFromParent()
                } else {
                    let destination = accepted ? position : drag.start
                    drag.entity.position = destination
                    if let index = latest?.dolls.firstIndex(where: { $0.id == drag.id }) {
                        latest?.dolls[index].position = destination
                    }
                }
                parent.onHoldDoll(nil)
            } else if !ended {
                drag.entity.position = drag.start
                if drag.isDoll { parent.onHoldDoll(nil) }
            } else if drag.isDoll {
                parent.onHoldDoll(nil)
                recordDollMove(drag.id, to: drag.entity.position - [0, lift, 0])
            } else if var moved = item(drag.id) {
                (moved.x, moved.z) = (drag.entity.position.x, drag.entity.position.z)
                if RoomLayout.overlaps(moved, in: rendered?.items ?? []) { drag.entity.position = drag.start }
                else { parent.onMoveItem(drag.id, [moved.x, moved.z]) }
            }
            rendered = nil
            if let latest { render(latest) }
        }

        #if DEBUG
        /// Exercises the actual raycasts and gesture lifecycle in an isolated Home fixture.
        private func auditDirectDrag() async -> [String] {
            var result: [String] = []
            func check(_ condition: Bool, _ name: String) { result.append("\(condition ? "PASS" : "FAIL"): \(name)") }
            func settle() async { try? await Task.sleep(for: .seconds(2)) }
            guard let view, let state = latest,
                  let doll = state.dolls.first(where: { $0.restingBedID == nil && $0.position.y < 0.1 }),
                  let bed = state.items.first(where: { $0.kind == .bed }) else { return ["FAIL: missing fixture"] }
            func pick() -> CGPoint? {
                guard let model = root.findEntity(named: "doll|\(doll.id)") else { return nil }
                let bounds = model.visualBounds(relativeTo: nil)
                return view.project(bounds.center)
            }
            guard let start = pick() else { return ["FAIL: project doll"] }
            beginDrag(at: start)
            check(drag?.id == doll.id, "long press picks awake doll")
            await settle()
            check(!parent.dollRemovalTarget.isEmpty, "home exposes trash target")
            let target = view.convert(CGPoint(x: parent.dollRemovalTarget.midX, y: parent.dollRemovalTarget.midY), from: nil)
            updateDrag(at: target)
            check(overRemovalTarget, "trash hover uses window coordinates")
            endDrag(at: target, ended: false)
            await settle()
            check(latest?.dolls.contains(where: { $0.id == doll.id }) == true, "cancel over trash keeps doll")
            if let sofa = state.items.first(where: { $0.kind == .sofa }),
               let screen = view.project([sofa.x, sofa.kind.seatHeight ?? 0.16, sofa.z]), let point = pick() {
                let original = latest?.dolls.first(where: { $0.id == doll.id })?.position
                beginDrag(at: point)
                updateDrag(at: screen)
                check(dropBlocked, "sofa rejects manual drop")
                endDrag(at: screen, ended: true)
                await settle()
                check(latest?.dolls.first(where: { $0.id == doll.id })?.position == original, "blocked sofa drop preserves original position")
            }
            if let chair = state.items.first(where: { $0.kind == .chair }),
               let screen = view.project([chair.x, chair.kind.seatHeight ?? 0.227, chair.z]), let point = pick() {
                beginDrag(at: point)
                updateDrag(at: screen)
                check(!dropBlocked, "desk chair accepts drop")
                endDrag(at: screen, ended: true)
                await settle()
                if let seated = root.findEntity(named: "doll|\(doll.id)") {
                    check(simd_dot(seated.orientation.act([0, 0, 1]), simd_quatf(angle: chair.yaw, axis: [0, 1, 0]).act([0, 0, 1])) > 0.99,
                          "desk chair doll faces desk with back visible")
                } else { check(false, "desk chair doll exists") }
            }
            guard let point = pick() else { return result + ["FAIL: repick"] }
            beginDrag(at: point)
            let foot = SIMD3<Float>(bed.x, RoomLayout.bedSeatHeight(covered: true), bed.z) + simd_quatf(angle: bed.yaw, axis: [0, 1, 0]).act([0, 0, 0.30])
            guard let footScreen = view.project(foot) else { return result + ["FAIL: project bed"] }
            updateDrag(at: footScreen)
            check(!dropBlocked, "bed foot accepts another doll while occupied")
            endDrag(at: footScreen, ended: true)
            await settle()
            if let placed = latest?.dolls.first(where: { $0.id == doll.id }) {
                check(RoomLayout.isBedSeat([placed.position.x, placed.position.z], on: bed), "bed drop persists")
            } else { check(false, "bed drop persists") }
            check(latest?.dolls.contains(where: { $0.restingBedID == bed.id }) == true, "sleeper remains in bed")
            guard let point = pick() else { return result + ["FAIL: repick bed doll"] }
            beginDrag(at: point)
            await settle()
            let trash = view.convert(CGPoint(x: parent.dollRemovalTarget.midX, y: parent.dollRemovalTarget.midY), from: nil)
            updateDrag(at: trash)
            if ProcessInfo.processInfo.arguments.contains("--hold-trash-preview") { return result }
            endDrag(at: trash, ended: true)
            await settle()
            check(latest?.dolls.contains(where: { $0.id == doll.id }) == false, "trash drop removes from room")
            return result
        }
        #endif

        /// SwiftUI 갱신을 기다리는 동안에도 재구성에 쓰는 좌표를 마지막 이동 위치로 유지한다.
        private func recordDollMove(_ id: UUID, to position: SIMD3<Float>) {
            if var snapshot = latest, let index = snapshot.dolls.firstIndex(where: { $0.id == id }) {
                snapshot.dolls[index].position = position
                latest = snapshot
            }
            parent.onMoveDoll(id, position)
        }

        /// 집거나 놓을 때 짧게 진동한다. 마이페이지에서 햅틱을 껐으면 울리지 않는다.
        private func canDrag(_ hit: (entity: Entity, id: UUID, isDoll: Bool)) -> Bool {
            switch parent.mode {
            case .home: hit.isDoll && (parent.canMoveDolls || parent.canLongPressDolls)
            case .decorate: hit.isDoll || (item(hit.id)?.kind.isMovable ?? false)
            case .view: false
            }
        }

        private func item(_ id: UUID) -> RoomItemState? {
            rendered?.items.first { $0.id == id }
        }

        /// 화면 좌표에 있는 인형이나 가구 엔티티. 이름이 "doll|UUID" 또는 "item|UUID"인 조상을 찾는다.
        private func target(at point: CGPoint, includeFurniture: Bool = false) -> (entity: Entity, id: UUID, isDoll: Bool)? {
            for hit in hits(at: point) {
                var entity: Entity? = hit.entity
                while let current = entity {
                    if let parsed = Self.parse(current.name) {
                        if parent.mode == .home, !parsed.isDoll, item(parsed.id)?.kind == .wall {
                            let local = current.convert(position: hit.position, from: nil)
                            // Same coordinates as the live window after its sill offset.
                            let z = local.z - 0.05
                            let archY: Float = 1.18
                            let inOpening = abs(local.x + 0.94) < 0.14 && abs(z) <= 0.33
                                && local.y >= 0.43
                                && (local.y <= archY || z * z + (local.y - archY) * (local.y - archY) <= 0.33 * 0.33)
                            guard inOpening else { return nil }
                        }
                        // 인형을 집을 때는 가구 충돌 면을 건너뛰고, 탭할 때는 가구도 고른다.
                        if parent.mode != .home || parsed.isDoll || includeFurniture {
                            return (current, parsed.id, parsed.isDoll)
                        }
                        break
                    }
                    entity = current.parent
                }
            }
            return nil
        }

        /// 좁은 화각의 방 카메라는 기본 raycast 범위(100m)보다 멀리 놓일 수 있다.
        private func hits(at point: CGPoint) -> [CollisionCastHit] {
            guard let view, let ray = view.ray(through: point) else { return [] }
            return view.scene.raycast(origin: ray.origin, direction: ray.direction,
                                      length: max(100, camera.camera.far + 1), query: .all)
                .sorted { $0.distance < $1.distance }
        }

        private static func parse(_ name: String) -> (id: UUID, isDoll: Bool)? {
            let parts = name.split(separator: "|")
            guard parts.count == 2, let id = UUID(uuidString: String(parts[1])) else { return nil }
            return (id, parts[0] == "doll")
        }

        private func furniturePoint(at point: CGPoint, for moving: RoomItemState) -> SIMD2<Float>? {
            if moving.kind == .lamp {
                for hit in hits(at: point) {
                    var entity: Entity? = hit.entity
                    while let current = entity, Self.parse(current.name) == nil { entity = current.parent }
                    guard let entity, let parsed = Self.parse(entity.name), !parsed.isDoll,
                          item(parsed.id)?.kind == .desk else { continue }
                    // 충돌 상자의 옆면 대신 실제 책상 높이 평면에 투영한다.
                    if let ray = view?.ray(through: point), ray.direction.y < 0 {
                        let height = FurnitureKind.desk.seatHeight ?? 0
                        let spot = ray.origin + ray.direction * ((height - ray.origin.y) / ray.direction.y)
                        return [spot.x, spot.z]
                    }
                }
            }
            return floorPoint(at: point)
        }

        private func floorPoint(at point: CGPoint) -> SIMD2<Float>? {
            guard let ray = view?.ray(through: point), ray.direction.y < 0 else { return nil }
            let hit = ray.origin + ray.direction * (-ray.origin.y / ray.direction.y)
            return [hit.x, hit.z]
        }

        /// 손가락 아래의 가구 윗면이나 바닥 위치. 가구를 먼저 맞히고, 없으면 바닥 평면을 쓴다.
        private func dollSpot(at point: CGPoint, excluding dragged: Entity) -> SIMD3<Float>? {
            let items = rendered?.items ?? []
            var xz: SIMD2<Float>?
            for hit in hits(at: point) {
                var entity: Entity? = hit.entity
                while let current = entity, Self.parse(current.name) == nil { entity = current.parent }
                guard let entity, entity !== dragged, let parsed = Self.parse(entity.name), !parsed.isDoll,
                      let kind = item(parsed.id)?.kind else { continue }
                if !kind.allowsDollPlacement && kind != .floor {
                    parent.onBlockedPlacement(kind)
                    return nil
                }
                guard kind.allowsDollPlacement else { continue }
                if kind == .chair, let chair = item(parsed.id) {
                    // Dropping anywhere on the chair uses its safe central seat,
                    // never a ray hit on the backrest or its outer edge.
                    xz = [chair.x, chair.z]
                } else if kind == .bed, let ray = view?.ray(through: point), ray.direction.y < 0 {
                    let height = RoomLayout.bedSeatHeight(covered: rendered?.dolls.contains(where: { $0.restingBedID == parsed.id }) == true)
                    let surface = ray.origin + ray.direction * ((height - ray.origin.y) / ray.direction.y)
                    xz = [surface.x, surface.z]
                } else { xz = [hit.position.x, hit.position.z] }
                break
            }
            guard let point = xz ?? floorPoint(at: point) else { return nil }
            let clamped = RoomLayout.clampedToFloor(point)
            if let blocked = RoomLayout.blockingDollPlacement(at: clamped, in: items) {
                parent.onBlockedPlacement(blocked.kind)
                return nil
            }
            parent.onBlockedPlacement(nil)
            return [clamped.x, RoomLayout.seat(at: clamped, in: items, sleepingBeds: Set(rendered?.dolls.compactMap(\.restingBedID) ?? [])).height, clamped.y]
        }

        /// 든 인형은 키우고 발밑에 원을 깔고, 나머지 인형은 흐리게 해서 어느 인형을 잡았는지 보이게 한다.
        /// 인형 재질은 투명도 0.5 아래를 그리지 않으므로 그보다 높게 흐린다.
        private func holdOut(_ entity: Entity) {
            entity.scale = [1.12, 1.12, 1.12]
            entity.addChild(SceneFactory.heldRing(below: lift))
            guard let content = root.children.first else { return }
            for other in content.children where other !== entity && other.name.hasPrefix("doll|") {
                other.components.set(OpacityComponent(opacity: 0.6))
            }
        }

        private func report(_ entity: Entity) {
            guard let screen = view?.project(entity.position(relativeTo: nil) + [0, 0.45, 0]) else { return }
            guard let id = drag?.id else { return }
            parent.onHoldDoll(Hold(screen: screen, position: entity.position - [0, lift, 0], id: id, isOverRemovalTarget: overRemovalTarget))
        }

        private func showSeatHighlights() {
            highlights = (rendered?.items ?? []).filter { $0.kind.allowsDollPlacement }.map { item in SceneFactory.seatHighlight(item, covered: rendered?.dolls.contains(where: { $0.restingBedID == item.id }) == true) }
            highlights.forEach { root.addChild($0) }
        }
    }
}

private final class RoomAccessibilityElement: UIAccessibilityElement {
    var activate: () -> Void = {}
    override func accessibilityActivate() -> Bool {
        activate()
        return true
    }
}

#Preview {
    RoomSceneView(items: RoomItem.starterRoom.map(\.state), mode: .home)
}

extension View {
    /// 3D 화면이 여러 개 쌓이면 맨 위 화면이 그려지지 않아서, 화면에 보일 때만 3D를 띄운다.
    /// 다른 화면이 위로 push되면 내려가고, 돌아오면 다시 그린다.
    func renderedOnlyWhileVisible(background: Color = Color.app.background) -> some View {
        modifier(VisibleOnly(background: background))
    }
}

private struct VisibleOnly: ViewModifier {
    let background: Color
    @State private var isVisible = false
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        ZStack {
            background
            if isVisible && scenePhase == .active { content }
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }
}
