// 실행: xcrun swiftc -parse-as-library Malrang/Features/Room/IllustrationMesh.swift scripts/render_furniture_illustration.swift -o /tmp/RenderFurnitureIllustration
// /tmp/RenderFurnitureIllustration <저장소 경로> <출력 경로>
import AppKit
import SceneKit

@main struct RenderFurnitureIllustration {
    static func color(_ hex: String) -> NSColor {
        let value = hex == "white" ? 0xFFFFFF : UInt32(hex.dropFirst(), radix: 16) ?? 0x8E6A5C
        return NSColor(srgbRed: CGFloat((value >> 16) & 255) / 255, green: CGFloat((value >> 8) & 255) / 255,
                       blue: CGFloat(value & 255) / 255, alpha: 1)
    }

    static func entity(_ faces: [IllustrationFace]) -> SCNNode {
        let root = SCNNode()
        for batch in IllustrationMesh.build(faces) {
            let source = SCNGeometrySource(vertices: batch.positions.map { SCNVector3($0) })
            let uv = SCNGeometrySource(textureCoordinates: batch.uv.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) })
            let geometry = SCNGeometry(sources: [source, uv], elements: [SCNGeometryElement(indices: batch.triangles, primitiveType: .triangles)])
            let material = SCNMaterial()
            material.lightingModel = .constant
            if let name = batch.texture {
                let url = URL(fileURLWithPath: CommandLine.arguments[1]).appendingPathComponent("Malrang/Resources/IllustrationTextures/\(name).png")
                material.diffuse.contents = NSImage(contentsOf: url)
            } else {
                material.diffuse.contents = color(batch.color)
            }
            material.isDoubleSided = true
            geometry.materials = [material]
            root.addChildNode(SCNNode(geometry: geometry))
        }
        return root
    }

    static func render(_ root: SCNNode, size: CGSize, target: SIMD3<Float>, scale: Double, paper: Bool = false) -> NSImage {
        let scene = SCNScene()
        if paper { scene.background.contents = color("#FFFFF4") }
        scene.rootNode.addChildNode(root)
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = scale
        camera.simdPosition = target + [5, 4.25, 5]
        camera.look(at: SCNVector3(target))
        scene.rootNode.addChildNode(camera)
        let renderer = SCNRenderer(device: nil, options: nil)
        renderer.scene = scene
        renderer.pointOfView = camera
        return renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
    }

    static func save(_ image: NSImage, to url: URL) throws {
        let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
        try bitmap.representation(using: .png, properties: [:])!.write(to: url)
    }

    static func main() throws {
        let repository = URL(fileURLWithPath: CommandLine.arguments[1])
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let data = try Data(contentsOf: repository.appendingPathComponent("Malrang/Resources/RoomIllustration.json"))
        let source = try JSONDecoder().decode([String: [IllustrationFace]].self, from: data)
        let kinds = ["bed", "desk", "shelf", "chair", "sofa", "rugRound", "rugSquare", "plant", "frame", "lamp"]
        let labels = ["침대", "책상", "선반", "의자", "소파", "원형 러그", "사각 러그", "화분", "액자", "조명"]
        let canvas = NSImage(size: NSSize(width: 1200, height: 1400))
        canvas.lockFocus()
        NSColor(srgbRed: 1, green: 1, blue: 0.96, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: 1200, height: 1400).fill()
        for (index, kind) in kinds.enumerated() {
            let node = entity(source[kind]!)
            let bounds = node.boundingBox
            let low = SIMD3<Float>(Float(bounds.min.x), Float(bounds.min.y), Float(bounds.min.z))
            let high = SIMD3<Float>(Float(bounds.max.x), Float(bounds.max.y), Float(bounds.max.z))
            let extent = high - low
            let image = render(node, size: CGSize(width: 480, height: 360), target: (low + high) / 2,
                               scale: Double(max(extent.x, extent.y, extent.z)) * 0.7)
            try save(image, to: output.appendingPathComponent("furniture_\(kind).png"))
            let x = CGFloat(index % 3) * 400
            let y = 1400 - CGFloat(index / 3 + 1) * 350
            image.draw(in: NSRect(x: x, y: y + 35, width: 400, height: 300))
            (labels[index] as NSString).draw(at: NSPoint(x: x + 170, y: y + 12), withAttributes: [.font: NSFont.systemFont(ofSize: 20), .foregroundColor: color("#6B4A3E")])
        }
        canvas.unlockFocus()
        try save(canvas, to: output.appendingPathComponent("furniture-preview.png"))
        let room = SCNNode()
        for (kind, x, z) in [("wall", Float(0), Float(0)), ("floor", 0, 0), ("bed", -0.5996, -0.22), ("desk", 0.4105, -0.7995),
                             ("chair", 0.54, 0.0201), ("plant", -0.8425, 0.6975), ("rugRound", 0.2118, 0.2119), ("frame", -0.598, -0.9775), ("shelf", 0.4316, -0.9185)] {
            let node = entity(source[kind]!)
            node.simdPosition = [x, kind == "shelf" ? 1.038 : kind == "frame" ? 0.866 : 0, z]
            room.addChildNode(node)
        }
        try save(render(room, size: CGSize(width: 1200, height: 1100), target: [0, 0.65, 0], scale: 1.65, paper: true),
                 to: output.appendingPathComponent("room-preview.png"))
        let turns = NSImage(size: NSSize(width: 1200, height: 400))
        turns.lockFocus()
        color("#FFFFF4").setFill()
        NSRect(x: 0, y: 0, width: 1200, height: 400).fill()
        for turn in 0..<4 {
            let node = entity(source["bed"]!)
            node.eulerAngles.y = CGFloat(turn) * .pi / 2
            render(node, size: CGSize(width: 300, height: 300), target: [0, 0.29, 0], scale: 0.85)
                .draw(in: NSRect(x: turn * 300, y: 60, width: 300, height: 300))
            ("\(turn * 90)°" as NSString).draw(at: NSPoint(x: turn * 300 + 120, y: 30),
                withAttributes: [.font: NSFont.systemFont(ofSize: 20), .foregroundColor: color("#6B4A3E")])
        }
        turns.unlockFocus()
        try save(turns, to: output.appendingPathComponent("rotation-preview.png"))
        print("Rendered 10 furniture thumbnails and room preview")
    }
}
