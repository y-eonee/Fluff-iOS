#if DEBUG
import RealityKit
import SwiftUI

/// Produces bundled catalog art from exactly the models used in the room.
struct FurnitureThumbnailExporter: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: CGRect(x: 0, y: 0, width: 512, height: 384), cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.isOpaque = false; view.backgroundColor = .clear
        view.environment.background = .color(.clear)
        view.renderOptions = [.disableMotionBlur, .disableDepthOfField, .disableGroundingShadows]
        context.coordinator.task = Task { @MainActor in
            let output = URL.documentsDirectory.appending(path: "FurnitureCatalog", directoryHint: .isDirectory)
            try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: output.appending(path: "complete.txt"))
            if let environment = await CozyRoomLighting.environmentResource(at: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!) { view.environment.lighting.resource = environment }
            view.environment.lighting.intensityExponent = 0.3
            var report: [String] = []
            for kind in FurnitureKind.allCases where kind.isMovable {
                guard !Task.isCancelled else { return }
                let model = await CozyFurniture.make(RoomItemState(id: UUID(), kind: kind, x: 0, z: 0), photoMaterial: PhysicallyBasedMaterial(), usesWindowLighting: false)
                for child in Array(model.children) where child.name == "contact-shadow" { child.removeFromParent() }
                let bounds = model.visualBounds(relativeTo: model)
                let anchor = AnchorEntity(world: .zero); anchor.addChild(model)
                let camera = PerspectiveCamera(); camera.camera.fieldOfViewInDegrees = 32
                let radius = max(0.10, simd_length(bounds.extents) / 2)
                let distance = radius / sin(Float(32) * .pi / 360) * 1.22
                let direction = simd_normalize(SIMD3<Float>(1.1, 0.85, 1.6))
                camera.look(at: bounds.center, from: bounds.center + direction * distance, relativeTo: nil)
                anchor.addChild(camera)
                let light = DirectionalLight(); light.light.intensity = 2200
                light.look(at: bounds.center, from: bounds.center + [-2, 3, 4], relativeTo: nil); anchor.addChild(light)
                view.scene.anchors.removeAll(); view.scene.addAnchor(anchor)
                try? await Task.sleep(for: .milliseconds(700))
                let snapshot: UIImage? = await withCheckedContinuation { continuation in view.snapshot(saveToHDR: false) { continuation.resume(returning: $0) } }
                if let snapshot {
                    let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = false
                    let projected = [-1 as Float, 1].flatMap { x in [-1 as Float, 1].flatMap { y in [-1 as Float, 1].compactMap { z in
                        view.project(bounds.center + bounds.extents / 2 * SIMD3(x, y, z))
                    } } }
                    let xs = projected.map(\.x), ys = projected.map(\.y)
                    let crop = CGRect(x: xs.min() ?? 0, y: ys.min() ?? 0, width: (xs.max() ?? 512) - (xs.min() ?? 0), height: (ys.max() ?? 384) - (ys.min() ?? 0)).insetBy(dx: -12, dy: -12).intersection(view.bounds)
                    let image = UIGraphicsImageRenderer(size: crop.size, format: format).image { _ in
                        snapshot.draw(in: CGRect(x: -crop.minX, y: -crop.minY, width: view.bounds.width, height: view.bounds.height))
                    }
                    if let data = image.pngData() { try? data.write(to: output.appending(path: "furniture_\(kind.rawValue).png")); report.append(kind.rawValue) }
                }
            }
            try? report.joined(separator: "\n").write(to: output.appending(path: "complete.txt"), atomically: true, encoding: .utf8)
        }
        return view
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) { coordinator.task?.cancel(); uiView.scene.anchors.removeAll() }
    @MainActor final class Coordinator { var task: Task<Void, Never>? }
}
#endif
