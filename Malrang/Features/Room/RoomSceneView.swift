import Combine
import RealityKit
import SwiftUI

/// 위에서 비스듬히 내려다보는 3D 방.
/// 길게 눌러 끌기, 탭, 두 번 탭을 쓰려고 ARView(비 AR 모드)를 감싼다. RealityView에는 화면 좌표로 끌어 옮길 API가 없다.
struct RoomSceneView: UIViewRepresentable {
    enum Mode {
        /// 구경만 하고 인형 탭만 받는다 (친구 방)
        case view
        /// 인형을 탭하거나 길게 눌러 옮긴다 (내 방)
        case home
        /// 가구를 길게 눌러 옮기거나 두 번 탭해 꾸민다 (방 꾸미기)
        case decorate
    }

    var items: [RoomItemState]
    var dolls: [DollState] = []
    var mode = Mode.view
    /// 값이 있으면 방 없이 이 가구 하나만 가운데에 보여준다
    var focusItem: RoomItemState?
    /// 값이 바뀌면 그 인형이 말랑하게 눌린다 (멀티 룸에서 누가 만졌을 때)
    var touch: DollTouch?
    var onTapDoll: (UUID) -> Void = { _ in }
    /// 내 방(home)에서는 새 인형을 배치하는 동안에만 인형을 끌 수 있다.
    var canMoveDolls = true
    var onPickDoll: (UUID) -> Void = { _ in }
    /// 인형을 들고 있는 동안 화면 위치와 놓일 자리를 알린다. 놓으면 nil.
    var onHoldDoll: (Hold?) -> Void = { _ in }
    var onMoveDoll: (UUID, SIMD3<Float>) -> Void = { _, _ in }
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
    /// 첫 번째 인형 머리 위의 화면 좌표. 인형이 없으면 nil. 말풍선이 인형을 따라다니게 한다.
    var onDollScreen: (CGPoint?) -> Void = { _ in }

    struct Hold: Equatable {
        /// 인형 머리 위 화면 좌표
        var screen: CGPoint
        var position: SIMD3<Float>
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(isTransparent ? .clear : UIColor(Color.app.background))
        view.backgroundColor = .clear
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.render(SceneState(items: items, dolls: dolls, focusItem: focusItem, selectedItemID: selectedItemID))
        context.coordinator.play(touch)
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
        private var renderTask: Task<Void, Never>?
        private var drag: Drag?
        private var highlights: [Entity] = []
        private let lift: Float = 0.06
        private var aim: (target: SIMD3<Float>, width: Float, height: Float)?
        private var fittedSize = CGSize.zero
        private var updateSubscription: (any Cancellable)?
        private var orbitYaw: Float = 0
        private var lastDollPoint: CGPoint?
        private var roomHidden = false
        private var fitDistance: Float = 1
        /// 방을 두 손가락으로 확대한 정도와 옮긴 위치. 방을 잃어버리지 않게 범위를 제한한다.
        private var zoom: Float = 1
        private var shift = SIMD3<Float>.zero
        private weak var shiftPan: UIPanGestureRecognizer?
        private lazy var cameraDirection = simd_normalize(SIMD3<Float>(1, parent.illustrationTargetY == nil ? 0.9 : 0.85, 1))

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
            orbitYaw = parent.focusItem.map { $0.kind.isMovable && !$0.kind.hangsOnWall ? $0.yaw : 0 } ?? 0
            view.scene.addAnchor(root)
            camera.camera.fieldOfViewInDegrees = parent.illustrationTargetY == nil ? 30 : 4
            light.light.intensity = 2500
            light.shadow = DirectionalLightComponent.Shadow(maximumDistance: 6, depthBias: 2)
            light.look(at: .zero, from: [1.5, 3, 2], relativeTo: nil)
            // 화면 크기가 정해지거나 바뀌면 카메라 거리를 다시 맞춘다.
            updateSubscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.fitCamera()
                    self?.reportDollScreen()
                }
            }

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            view.addGestureRecognizer(tap)
            if parent.mode == .decorate {
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
                let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleZoom))
                let pan = UIPanGestureRecognizer(target: self, action: #selector(handleShift))
                shiftPan = pan
                [pinch, pan].forEach {
                    $0.delegate = self
                    view.addGestureRecognizer($0)
                }
            }
            if parent.mode != .view {
                let press = UILongPressGestureRecognizer(target: self, action: #selector(handlePress))
                press.minimumPressDuration = 0.35
                view.addGestureRecognizer(press)
            }
        }

        func render(_ state: SceneState) {
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
            let content = Entity()
            if var item = state.focusItem {
                (item.x, item.z) = (0, 0)
                if !item.kind.hangsOnWall { item.yaw = 0 }
                content.addChild(await SceneFactory.furniture(item, onFloor: true))
                let size = item.kind.size
                aimCamera(at: [0, size.y / 2, 0], fitting: max(size.x, size.z) * 1.6, height: size.y * 1.4)
            } else {
            for item in state.items {
                    let furniture = await SceneFactory.furniture(item)
                    if roomHidden { furniture.components.set(OpacityComponent(opacity: 0)) }
                    content.addChild(furniture)
                }
                for var doll in state.dolls {
                    // 가구 위에 있는 인형은 그 윗면에 서고, 가구가 치워졌으면 바닥으로 내려온다.
                    doll.position.y = RoomLayout.seat(at: [doll.position.x, doll.position.z], in: state.items).height
                    content.addChild(await SceneFactory.doll(doll))
                }
                let board = await SceneFactory.memoBoard()
                if roomHidden { board.components.set(OpacityComponent(opacity: 0)) }
                content.addChild(board)
                if let selected = state.items.first(where: { $0.id == state.selectedItemID }), selected.kind.isMovable {
                    content.addChild(SceneFactory.selectionBox(selected))
                }
                aimCamera(at: [0, parent.illustrationTargetY ?? 0.45, 0], fitting: parent.illustrationTargetY == nil ? 3.3 : 3.55, height: parent.illustrationTargetY == nil ? 3.1 : 2.9)
            }
            guard !Task.isCancelled else { return }
            root.children.removeAll()
            highlights = []
            content.orientation = simd_quatf(angle: orbitYaw, axis: [0, 1, 0])
            root.addChild(content)
            root.addChild(camera)
            root.addChild(light)
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
            let distance = max(aim.width / 2 / (tanHalf * aspect), aim.height / 2 / tanHalf)
            fitDistance = distance
            placeCamera()
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
            camera.camera.near = max(0.01, distance - 3)
            camera.camera.far = distance + 3
            camera.look(at: target, from: target + cameraDirection * distance, relativeTo: nil)
        }

        @objc private func handleZoom(_ gesture: UIPinchGestureRecognizer) {
            zoom = min(2.5, max(1, zoom * Float(gesture.scale)))
            gesture.scale = 1
            if zoom == 1 { shift = .zero }
            placeCamera()
        }

        /// 확대한 상태에서 쓸면 방의 다른 쪽을 볼 수 있다.
        @objc private func handleShift(_ gesture: UIPanGestureRecognizer) {
            guard let view, zoom > 1, drag == nil, view.bounds.height > 0 else { return }
            let move = gesture.translation(in: view)
            gesture.setTranslation(.zero, in: view)
            let tanHalf = tan(camera.camera.fieldOfViewInDegrees / 2 * .pi / 180)
            let metersPerPoint = 2 * fitDistance / zoom * tanHalf / Float(view.bounds.height)
            let root2 = Float(0.5).squareRoot()
            let right = SIMD3<Float>(1, 0, -1) * root2
            let away = SIMD3<Float>(-1, 0, -1) * root2
            let dx = Float(move.x) * metersPerPoint
            let dy = Float(move.y) * metersPerPoint
            shift += away * dy - right * dx
            shift = simd_clamp(shift, SIMD3(repeating: -1), SIMD3(repeating: 1))
            placeCamera()
        }

        private var lastTouch: DollTouch?

        func play(_ touch: DollTouch?) {
            guard let touch, touch != lastTouch else { return }
            lastTouch = touch
            guard let doll = root.findEntity(named: "doll|\(touch.dollID)") else { return }
            Task { await SceneFactory.squish(doll) }
        }

        // MARK: 제스처

        /// 확대했을 때만 한 손가락으로 방을 옮긴다. 인형이나 가구를 집어 든 동안에는 옮기지 않는다.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard gestureRecognizer === shiftPan else { return true }
            guard zoom > 1, drag == nil else { return false }
            if let view, let hit = target(at: gestureRecognizer.location(in: view)), canDrag(hit) {
                return false
            }
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
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
            if parent.mode == .decorate {
                if let hit = target(at: point), !hit.isDoll { parent.onTapItem(hit.id) } else { parent.onTapItem(nil) }
                return
            }
            if isBoard(view.entity(at: point)) {
                parent.onTapBoard()
            } else if let hit = target(at: point), hit.isDoll {
                parent.onTapDoll(hit.id)
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
            guard let view, let hit = target(at: gesture.location(in: view)), !hit.isDoll else { return }
            parent.onDoubleTapItem(hit.id)
        }

        @objc private func handlePress(_ gesture: UILongPressGestureRecognizer) {
            guard let view else { return }
            let point = gesture.location(in: view)
            switch gesture.state {
            case .began:
                guard let hit = target(at: point), canDrag(hit) else { return }
                hit.entity.stopAllAnimations()
                parent.onFeel()
                drag = Drag(entity: hit.entity, id: hit.id, isDoll: hit.isDoll, start: hit.entity.position)
                if hit.isDoll {
                    hit.entity.position.y += lift
                    holdOut(hit.entity)
                    showSeatHighlights()
                    parent.onPickDoll(hit.id)
                    report(hit.entity)
                }
            case .changed:
                guard let drag else { return }
                if drag.isDoll {
                    if let spot = dollSpot(at: point, excluding: drag.entity) {
                        drag.entity.position = spot + [0, lift, 0]
                        report(drag.entity)
                    }
                } else if let moving = item(drag.id), let floor = floorPoint(at: point) {
                    let snapped = RoomLayout.snapped(floor, for: moving.kind, yaw: moving.yaw)
                    if moving.kind.hangsOnWall {
                        var hung = moving
                        (hung.x, hung.z) = (snapped.x, snapped.y)
                        drag.entity.position = [snapped.x, moving.kind.hangingHeight, snapped.y]
                        drag.entity.orientation = simd_quatf(angle: RoomLayout.wall(of: hung).yaw, axis: [0, 1, 0])
                    } else {
                        drag.entity.position = [snapped.x, 0, snapped.y]
                    }
                }
            case .ended, .cancelled, .failed:
                guard let drag else { return }
                self.drag = nil
                parent.onFeel()
                highlights.forEach { $0.removeFromParent() }
                highlights = []
                if gesture.state != .ended {
                    drag.entity.position = drag.start
                    if drag.isDoll { parent.onHoldDoll(nil) }
                } else if drag.isDoll {
                    parent.onHoldDoll(nil)
                    parent.onMoveDoll(drag.id, drag.entity.position - [0, lift, 0])
                } else if var moved = item(drag.id) {
                    (moved.x, moved.z) = (drag.entity.position.x, drag.entity.position.z)
                    if RoomLayout.overlaps(moved, in: rendered?.items ?? []) {
                        drag.entity.position = drag.start
                    } else {
                        parent.onMoveItem(drag.id, [moved.x, moved.z])
                    }
                }
                // 멈췄던 춤 애니메이션을 되살리려고 다시 그린다.
                rendered = nil
                if let latest { render(latest) }
            default:
                break
            }
        }

        /// 집거나 놓을 때 짧게 진동한다. 마이페이지에서 햅틱을 껐으면 울리지 않는다.
        private func canDrag(_ hit: (entity: Entity, id: UUID, isDoll: Bool)) -> Bool {
            switch parent.mode {
            case .home: hit.isDoll && parent.canMoveDolls
            case .decorate: hit.isDoll || (item(hit.id)?.kind.isMovable ?? false)
            case .view: false
            }
        }

        private func item(_ id: UUID) -> RoomItemState? {
            rendered?.items.first { $0.id == id }
        }

        /// 화면 좌표에 있는 인형이나 가구 엔티티. 이름이 "doll|UUID" 또는 "item|UUID"인 조상을 찾는다.
        private func target(at point: CGPoint) -> (entity: Entity, id: UUID, isDoll: Bool)? {
            for hit in view?.hitTest(point) ?? [] {
                var entity: Entity? = hit.entity
                while let current = entity {
                    if let parsed = Self.parse(current.name) {
                        // 홈에서는 인형만 고른다. 가구의 충돌 면이 먼저 맞아도 집을 수 있다.
                        if parent.mode != .home || parsed.isDoll {
                            return (current, parsed.id, parsed.isDoll)
                        }
                        break
                    }
                    entity = current.parent
                }
            }
            return nil
        }

        private static func parse(_ name: String) -> (id: UUID, isDoll: Bool)? {
            let parts = name.split(separator: "|")
            guard parts.count == 2, let id = UUID(uuidString: String(parts[1])) else { return nil }
            return (id, parts[0] == "doll")
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
            for hit in view?.hitTest(point) ?? [] {
                var entity: Entity? = hit.entity
                while let current = entity, Self.parse(current.name) == nil { entity = current.parent }
                guard let entity, entity !== dragged, let parsed = Self.parse(entity.name), !parsed.isDoll,
                      let kind = item(parsed.id)?.kind, kind.seatHeight != nil else { continue }
                xz = [hit.position.x, hit.position.z]
                break
            }
            guard let point = xz ?? floorPoint(at: point) else { return nil }
            let clamped = RoomLayout.clampedToFloor(point)
            return [clamped.x, RoomLayout.seat(at: clamped, in: items).height, clamped.y]
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
            parent.onHoldDoll(Hold(screen: screen, position: entity.position - [0, lift, 0]))
        }

        private func showSeatHighlights() {
            highlights = (rendered?.items ?? []).filter { $0.kind.seatHeight != nil }.map { SceneFactory.seatHighlight($0) }
            highlights.forEach { root.addChild($0) }
        }
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

    func body(content: Content) -> some View {
        ZStack {
            background
            if isVisible { content }
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }
}
