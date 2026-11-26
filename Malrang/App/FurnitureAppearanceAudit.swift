#if DEBUG
import RealityKit
import SwiftUI

/// Real pixels from the same two renderers used by the editor and home.
/// Deliberately bright ink distinguishes an applied finish from the default model.
struct FurnitureAppearanceAudit: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> RoomRenderView {
        let home = ProcessInfo.processInfo.arguments.contains("--appearance-home")
        let view = RoomRenderView(adaptive: home)
        context.coordinator.task = Task { await context.coordinator.run(view, home: home) }
        return view
    }
    func updateUIView(_ view: RoomRenderView, context: Context) {}
    static func dismantleUIView(_ view: RoomRenderView, coordinator: Coordinator) {
        coordinator.task?.cancel(); view.shutdown()
    }
    @MainActor final class Coordinator {
        var task: Task<Void, Never>?
        func run(_ view: RoomRenderView, home: Bool) async {
            let output = URL.documentsDirectory.appending(path: home ? "AppearanceHome" : "AppearanceEditor")
            try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: output.appending(path: "report.json"))
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            let image = UIGraphicsImageRenderer(size: CGSize(width: 180, height: 120), format: format).image { c in
                UIColor.magenta.setFill(); c.fill(CGRect(x: 0, y: 0, width: 180, height: 120))
                UIColor(red: 0.6, green: 0, blue: 0.6, alpha: 1).setFill()
                c.fill(CGRect(x: 0, y: 0, width: 40, height: 120))
            }.pngData()!
            view.sceneBackground = .white
            view.environmentResource = await CozyRoomLighting.environmentResource(profile: .editor)
            view.lightingExponent = -0.1
            var rows: [[String: Any]] = []
            let full = ProcessInfo.processInfo.arguments.contains("--appearance-full")
            for kind in FurnitureKind.catalog {
                for finish in ["color", "photo"] {
                    for mirrored in (full && kind.isMovable ? [false, true] : [false]) {
                        for turn in (full && kind.isMovable ? Array(0..<4) : [0]) {
                            guard !Task.isCancelled else { return }
                            var item = RoomItemState(id: UUID(), kind: kind, x: 0, z: kind.hangsOnWall ? -0.96 : 0)
                            item.isMirrored = mirrored; item.yaw = Float(turn) * .pi / 2
                            if finish == "photo" { item.photoData = image; if kind == .wall { item.rightWallPhotoData = image } }
                            else { item.colorName = "#EE00EE"; if kind == .wall { item.rightWallColorName = "#EE00EE" } }
                            let model = await SceneFactory.furniture(item, cozy: true, cutaway: !home)
                            let anchor = AnchorEntity(world: .zero); anchor.addChild(model)
                            let bounds = model.visualBounds(relativeTo: nil)
                            let camera = PerspectiveCamera(); camera.camera.fieldOfViewInDegrees = 32
                            let distance = max(0.15, simd_length(bounds.extents) / 2) / sin(Float.pi * 32 / 360) * 1.18
                            camera.look(at: bounds.center, from: bounds.center + simd_normalize([1.1, 0.95, 1.6]) * distance, relativeTo: nil)
                            anchor.addChild(camera)
                            let light = DirectionalLight(); light.light.intensity = 2200
                            light.look(at: bounds.center, from: bounds.center + [-1, 3, 2], relativeTo: nil); anchor.addChild(light)
                            view.attach(anchor, camera: camera)
                            try? await Task.sleep(for: .milliseconds(350))
                            let snapshot: UIImage? = await withCheckedContinuation { c in view.snapshot { c.resume(returning: $0) } }
                            let key = "\(kind.rawValue)-\(finish)-\(turn)-\(mirrored)"
                            let count = snapshot.map(Self.inkPixels) ?? 0
                            rows.append(["case": key, "pixels": count, "visible": count >= 8])
                            if let bytes = snapshot?.pngData() { try? bytes.write(to: output.appending(path: key + ".png")) }
                            if let data = try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys]) {
                                try? data.write(to: output.appending(path: "progress.json"), options: .atomic)
                            }
                        }
                    }
                }
            }
            if let data = try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys]) {
                try? data.write(to: output.appending(path: "report.json"), options: .atomic)
            }
        }
        static func inkPixels(_ image: UIImage) -> Int {
            guard let cg = image.cgImage else { return 0 }
            let width = 320, height = 320
            var bytes = [UInt8](repeating: 0, count: width * height * 4)
            guard let context = CGContext(data: &bytes, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return 0 }
            context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
            return stride(from: 0, to: bytes.count, by: 4).filter { i in
                let r = Float(bytes[i]), g = Float(bytes[i+1]), b = Float(bytes[i+2])
                return r > 75 && b > 65 && g < min(r, b) * 0.65
            }.count
        }
    }
}
#endif
