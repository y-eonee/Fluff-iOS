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
    var onPickDoll: (UUID) -> Void = { _ in }
    var onMoveDoll: (UUID, SIMD3<Float>) -> Void = { _, _ in }
    var onMoveItem: (UUID, SIMD2<Float>) -> Void = { _, _ in }
    var onDoubleTapItem: (UUID) -> Void = { _ in }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(UIColor(Color.app.background))
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.render(SceneState(items: items, dolls: dolls, focusItem: focusItem))
        context.coordinator.play(touch)
    }

    struct SceneState: Equatable {
        var items: [RoomItemState]
        var dolls: [DollState]
        var focusItem: RoomItemState?
    }

    final class Coordinator: NSObject {
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
            view.scene.addAnchor(root)
            camera.camera.fieldOfViewInDegrees = 30
            light.light.intensity = 2500
            light.shadow = DirectionalLightComponent.Shadow(maximumDistance: 6, depthBias: 2)
            light.look(at: .zero, from: [1.5, 3, 2], relativeTo: nil)
            // 화면 크기가 정해지거나 바뀌면 카메라 거리를 다시 맞춘다.
            updateSubscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
                MainActor.assumeIsolated { self?.fitCamera() }
            }

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            view.addGestureRecognizer(tap)
            if parent.mode == .decorate {
                let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
                doubleTap.numberOfTapsRequired = 2
                tap.require(toFail: doubleTap)
                view.addGestureRecognizer(doubleTap)
            }
            if parent.mode != .view {
                let press = UILongPressGestureRecognizer(target: self, action: #selector(handlePress))
                press.minimumPressDuration = 0.35
                view.addGestureRecognizer(press)
            }
        }

        func render(_ state: SceneState) {
            latest = state
            guard state != rendered, drag == nil else { return }
            rendered = state
            renderTask?.cancel()
            renderTask = Task { await build(state) }
        }

        private func build(_ state: SceneState) async {
            let content = Entity()
            if var item = state.focusItem {
                (item.x, item.z) = (0, 0)
                content.addChild(await SceneFactory.furniture(item))
                let size = item.kind.size
                aimCamera(at: [0, size.y / 2, 0], fitting: max(size.x, size.z) * 1.6, height: size.y * 1.4)
            } else {
            for item in state.items {
                    content.addChild(await SceneFactory.furniture(item))
                }
                for doll in state.dolls {
                    content.addChild(await SceneFactory.doll(doll))
                }
                aimCamera(at: [0, 0.45, 0], fitting: 3.3, height: 3.1)
            }
            guard !Task.isCancelled else { return }
            root.children.removeAll()
            highlights = []
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
            let direction = simd_normalize(SIMD3<Float>(1, 0.9, 1))
            camera.look(at: aim.target, from: aim.target + direction * distance, relativeTo: nil)
        }

        private var lastTouch: DollTouch?

        func play(_ touch: DollTouch?) {
            guard let touch, touch != lastTouch else { return }
            lastTouch = touch
            guard let doll = root.findEntity(named: "doll|\(touch.dollID)") else { return }
            Task { await SceneFactory.squish(doll) }
        }

        // MARK: 제스처

        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view, let hit = target(at: gesture.location(in: view)), hit.isDoll, parent.mode != .decorate else { return }
            parent.onTapDoll(hit.id)
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
                drag = Drag(entity: hit.entity, id: hit.id, isDoll: hit.isDoll, start: hit.entity.position)
                if hit.isDoll {
                    hit.entity.position.y += lift
                    showSeatHighlights()
                    parent.onPickDoll(hit.id)
                }
            case .changed:
                guard let drag else { return }
                if drag.isDoll {
                    if let spot = dollSpot(at: point, excluding: drag.entity) {
                        drag.entity.position = spot + [0, lift, 0]
                    }
                } else if let kind = item(drag.id)?.kind, let floor = floorPoint(at: point) {
                    let snapped = RoomLayout.snapped(floor, for: kind)
                    drag.entity.position = [snapped.x, 0, snapped.y]
                }
            case .ended, .cancelled, .failed:
                guard let drag else { return }
                self.drag = nil
                highlights.forEach { $0.removeFromParent() }
                highlights = []
                if drag.isDoll {
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

        private func canDrag(_ hit: (entity: Entity, id: UUID, isDoll: Bool)) -> Bool {
            switch parent.mode {
            case .home: hit.isDoll
            case .decorate: !hit.isDoll && (item(hit.id)?.kind.isMovable ?? false)
            case .view: false
            }
        }

        private func item(_ id: UUID) -> RoomItemState? {
            rendered?.items.first { $0.id == id }
        }

        /// 화면 좌표에 있는 인형이나 가구 엔티티. 이름이 "doll|UUID" 또는 "item|UUID"인 조상을 찾는다.
        private func target(at point: CGPoint) -> (entity: Entity, id: UUID, isDoll: Bool)? {
            var entity = view?.entity(at: point)
            while let current = entity {
                if let parsed = Self.parse(current.name) {
                    return (current, parsed.id, parsed.isDoll)
                }
                entity = current.parent
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

        private func showSeatHighlights() {
            highlights = (rendered?.items ?? []).filter { $0.kind.seatHeight != nil }.map { SceneFactory.seatHighlight($0) }
            highlights.forEach { root.addChild($0) }
        }
    }
}

#Preview {
    RoomSceneView(items: RoomItem.starterRoom.map(\.state), mode: .home)
}
