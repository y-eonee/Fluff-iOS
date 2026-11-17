#if DEBUG
import Foundation
import RealityKit
import UIKit
import Metal

/// Rebuild the editable model files without touching the user's room or photos.
enum CozyModelExporter {
    /// Exercise the bundled files and their recoloring without editing saved room state.
    static func auditIfRequested() async {
        guard ProcessInfo.processInfo.arguments.contains("--audit-cozy-models") else { return }
        var report: [String] = []
        for cutaway in [false, true] {
            let panel = CozyRoomShell.panel(size: [0.055, 2.04], center: [-1.025, 0], cutaway: cutaway)
            let expected: Float = cutaway ? 1.493096 : CozyRoomShell.cornerHeight
            report.append("room.shell.\(cutaway ? "cutaway" : "interior"): \(abs(panel.bounds.extents.y - expected) < 0.001 ? "PASS" : "FAIL")")
        }
        let floor = await CozyFurniture.make(RoomItemState(id: UUID(), kind: .floor, x: 0, z: 0), photoMaterial: PhysicallyBasedMaterial())
        report.append("room.floor.singleSurface: \(floor.children.filter { $0.components[ModelComponent.self] != nil }.count == 1 ? "PASS" : "FAIL")")
        if let device = MTLCreateSystemDefaultDevice(), let library = device.makeDefaultLibrary() {
            let names = ["cozyFabric", "cozyCopyColor", "cozyExtractLight", "cozyCompositeLight", "plushExtractLight", "plushCompositeLight"]
            for name in names {
                report.append("metal.\(name): \(library.makeFunction(name: name) != nil ? "PASS" : "FAIL")")
            }
            report.append("metal.roomBloomPipeline: \(CozyBloom(device: device) != nil ? "PASS" : "FAIL")")
            report.append("metal.presetBloomPipeline: \(CozyBloom(device: device, preset: true) != nil ? "PASS" : "FAIL")")
        } else { report.append("metal.defaultLibrary: FAIL") }
        let parts: [(FurnitureKind, String)] = [(.bed, "duvet"), (.desk, "desktop"), (.chair, "backrest"), (.sofa, "seat"), (.shelf, "shelf"), (.frame, "frame"), (.lamp, "shade"), (.rugRound, "rug")]
        for (kind, part) in parts {
            var state = RoomItemState(id: UUID(), kind: kind, x: 0, z: 0)
            state.colorName = "#55AADD"
            let model = await CozyFurniture.make(state, photoMaterial: PhysicallyBasedMaterial())
            let tinted = model.findEntity(named: part)
            let material = tinted?.components[ModelComponent.self]?.materials.first as? CustomMaterial
            let expected = Palette.uiColor("#55AADD")
            let recolored = matches(material?.baseColor.tint, expected)
            let bundled = Bundle.main.url(forResource: "cozy_" + kind.rawValue, withExtension: "reality") != nil
            var preserved = true
            if kind == .bed {
                let fold = model.findEntity(named: "duvet.fold")
                preserved = !matches((fold?.components[ModelComponent.self]?.materials.first as? CustomMaterial)?.baseColor.tint, expected)
            }
            if kind == .bed, let duvet = model.findEntity(named: "duvet"), let fold = model.findEntity(named: "duvet.fold") {
                // The room first makes the bed, leaving its foot clear for sitting.
                // Compare the cycle against that pose, not the unposed exported mesh.
                DollRestPose.bedding(model, pose: .made, animated: false)
                let blanketBounds = duvet.visualBounds(relativeTo: model)
                report.append("bedding.fullLength: \(blanketBounds.max.z >= state.kind.size.z / 2 - 0.01 ? "PASS" : "FAIL")")
                let original = duvet.transform
                let originalFold = fold.transform
                let childCount = model.children.count
                DollRestPose.bedding(model, pose: .open, animated: false)
                let opened = duvet.scale.z < original.scale.z && duvet.position.y > original.translation.y
                DollRestPose.bedding(model, pose: .covered, animated: false)
                let covered = duvet.position.y > original.translation.y && fold.position.y > originalFold.translation.y
                DollRestPose.bedding(model, pose: .made, animated: false)
                let restored = duvet.transform == original && fold.transform == originalFold
                let reused = model.children.count == childCount && model.findEntity(named: "duvet") === duvet
                report.append("bedding: \(opened && covered && restored && reused ? "PASS" : "FAIL") open=\(opened), cover=\(covered), restore=\(restored), reuse=\(reused)")
            }
            if kind == .bed {
                let scene = Entity(); scene.addChild(model)
                DollRestPose.bedding(model, pose: .covered, animated: false)
                for shape in [DollShape.cat, .bear, .rabbit] {
                    let doll = await SceneFactory.doll(DollState(id: UUID(), name: "audit", imageData: Data(), filling: .fluffy, position: .zero, preset: PresetConfiguration(shape: shape)))
                    scene.addChild(doll)
                    DollRestPose.sleeping(doll, bed: state, animated: false)
                    if let head = doll.findEntity(named: "head"), let torso = doll.findEntity(named: "torso"), let duvet = model.findEntity(named: "duvet") {
                        let headBounds = head.visualBounds(relativeTo: scene)
                        let torsoBounds = torso.visualBounds(relativeTo: scene)
                        let coverBounds = duvet.visualBounds(relativeTo: scene)
                        let covered = torsoBounds.max.y < coverBounds.max.y && torsoBounds.max.z < 0.28
                        let visible = headBounds.max.y > coverBounds.max.y && headBounds.center.z < coverBounds.min.z
                        let pillowTop = model.findEntity(named: "pillow")?.visualBounds(relativeTo: scene).max.y ?? 0
                        let mattressTop = model.findEntity(named: "mattress")?.visualBounds(relativeTo: scene).max.y ?? 0
                        let headboardFront = model.findEntity(named: "headboard")?.visualBounds(relativeTo: scene).max.z ?? -1
                        // A soft pillow supports the head's centre; requiring
                        // the entire head AABB above its highest corner forced
                        // the previous detached-head pose.
                        let clear = headBounds.min.y >= mattressTop && headBounds.center.y >= pillowTop - 0.02
                            && headBounds.min.z >= headboardFront
                        report.append("sleep.\(shape.rawValue): \(covered && visible && clear ? "PASS" : "FAIL") head=\(headBounds.min)...\(headBounds.max), torso=\(torsoBounds.min)...\(torsoBounds.max), duvet=\(coverBounds.min)...\(coverBounds.max)")
                        if let hood = doll.findEntity(named: "head.fur"), let collar = doll.findEntity(named: "neck.fur") {
                            let h = hood.visualBounds(relativeTo: scene), n = collar.visualBounds(relativeTo: scene)
                            let connected = h.min.x <= n.max.x && h.max.x >= n.min.x
                                && h.min.y <= n.max.y && h.max.y >= n.min.y
                                && h.min.z <= n.max.z && h.max.z >= n.min.z
                            report.append("sleep.\(shape.rawValue).neckConnected: \(connected ? "PASS" : "FAIL")")
                        } else { report.append("sleep.\(shape.rawValue).neckConnected: FAIL missing sewn geometry") }
                    }
                    doll.removeFromParent()
                }
            }
            state.colorName = nil
            let original = await CozyFurniture.make(state, photoMaterial: PhysicallyBasedMaterial())
            let untouched = !matches((original.findEntity(named: part)?.components[ModelComponent.self]?.materials.first as? CustomMaterial)?.baseColor.tint, expected)
            let defaultMaterial = original.findEntity(named: part)?.components[ModelComponent.self]?.materials.first as? CustomMaterial
            let paletteDefault = matches(defaultMaterial?.baseColor.tint, Palette.uiColor(CozyFurniture.defaultColor(for: kind, cutaway: false)))
            if kind == .bed {
                let footboard = original.findEntity(named: "footboard")?.components[ModelComponent.self]?.materials.first as? CustomMaterial
                let fabric = matches(footboard?.baseColor.tint, Palette.uiColor(CozyRoomPalette.ivory)) && (footboard?.custom.value.y ?? -1) >= 0
                report.append("bed.footboard.fabric: \(fabric ? "PASS" : "FAIL")")
            }
            if kind == .chair {
                let interiorLeg = original.findEntity(named: "leg")?.components[ModelComponent.self]?.materials.first as? CustomMaterial
                report.append("chair.interior.timberLeg: \(matches(interiorLeg?.baseColor.tint, Palette.uiColor("#A17450")) && (interiorLeg?.custom.value.y ?? 0) < 0 ? "PASS" : "FAIL")")
                var pinkChair = state; pinkChair.colorName = "#FF99BB"
                let cutaway = await CozyFurniture.make(pinkChair, photoMaterial: PhysicallyBasedMaterial(), cutaway: true)
                let leg = cutaway.findEntity(named: "leg")?.components[ModelComponent.self]?.materials.first as? CustomMaterial
                let back = cutaway.findEntity(named: "backrest")?.components[ModelComponent.self]?.materials.first as? CustomMaterial
                report.append("chair.cutaway.timberLeg: \(matches(leg?.baseColor.tint, Palette.uiColor("#DEB883")) && (leg?.custom.value.y ?? 0) < 0 ? "PASS" : "FAIL")")
                report.append("chair.cutaway.customUpholstery: \(matches(back?.baseColor.tint, Palette.uiColor("#FF99BB")) ? "PASS" : "FAIL")")
            }
            if kind == .chair, let defaultMaterial { report += auditBatching(material: defaultMaterial) }
            report.append("\(kind.rawValue): \(bundled && recolored && preserved && untouched && paletteDefault ? "PASS" : "FAIL") bundled=\(bundled), recolor=\(recolored), actual=\(String(describing: material?.baseColor.tint)), trim=\(preserved), cache=\(untouched), paletteDefault=\(paletteDefault)")
        }
        try? report.joined(separator: "\n").write(to: URL.documentsDirectory.appending(path: "cozy-model-audit.txt"), atomically: true, encoding: .utf8)
    }

    /// Regression: temporary MeshResource wrapper addresses must never group
    /// a chair leg's cylinder with its spherical foot.
    private static func auditBatching(material: CustomMaterial) -> [String] {
        let root = Entity()
        for index in 0..<8 {
            let mesh: MeshResource = index.isMultiple(of: 2)
                ? .generateSphere(radius: 0.05) : .generateCylinder(height: 0.3, radius: 0.02)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.name = "part-\(index)"
            entity.position.x = Float(index) * 0.1
            entity.scale = SIMD3(repeating: 0.5)
            root.addChild(entity)
        }
        let expectedBounds = root.visualBounds(relativeTo: root)
        FurnitureInstances.batch(root, kind: .chair)
        let clone = root.clone(recursive: true)
        let models = clone.children.filter { $0.components[ModelComponent.self] != nil }
        let actualBounds = clone.visualBounds(relativeTo: clone)
        let positionsValid = simd_length(actualBounds.min - expectedBounds.min) < 0.001
            && simd_length(actualBounds.max - expectedBounds.max) < 0.001
        let shapeHeights = models.compactMap { $0.components[ModelComponent.self]?.mesh.bounds.extents.y }.sorted()
        let geometryValid = shapeHeights.count == 2 && abs(shapeHeights[0] - 0.05) < 0.001 && abs(shapeHeights[1] - 0.15) < 0.001
        let namesKept = (0..<8).allSatisfy { clone.findEntity(named: "part-\($0)") != nil }
        return [
            "batch.distinctGeometry: \(geometryValid && clone.components[FurnitureInstances.Counts.self]?.batchedModels == 6 ? "PASS" : "FAIL")",
            "batch.cloneTransforms: \(positionsValid && namesKept ? "PASS" : "FAIL")",
            "batch.stableShadowGeometry: \(models.count == 2 && models.allSatisfy { $0.components[MeshInstancesComponent.self] == nil } ? "PASS" : "FAIL")"
        ]
    }

    private static func matches(_ color: UIColor?, _ expected: UIColor) -> Bool {
        guard let color else { return false }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        var er: CGFloat = 0, eg: CGFloat = 0, eb: CGFloat = 0, ea: CGFloat = 0
        guard color.getRed(&r, green: &g, blue: &b, alpha: &a), expected.getRed(&er, green: &eg, blue: &eb, alpha: &ea) else { return false }
        return abs(r-er) < 0.005 && abs(g-eg) < 0.005 && abs(b-eb) < 0.005
    }

    static func exportIfRequested() async {
        guard ProcessInfo.processInfo.arguments.contains("--export-cozy-models") else { return }
        let directory = URL.documentsDirectory.appending(path: "CozyModels", directoryHint: .isDirectory)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let kinds: [FurnitureKind] = [.bed, .desk, .chair, .sofa, .shelf, .frame, .lamp, .rugRound]
            var report: [String] = []
            for kind in kinds {
                let state = RoomItemState(id: UUID(), kind: kind, x: 0, z: 0)
                let model = await CozyFurniture.make(state, photoMaterial: PhysicallyBasedMaterial(),
                                                     usesWindowLighting: false, useBakedModels: false, cutaway: true)
                model.name = "cozy_" + kind.rawValue
                let url = directory.appending(path: model.name + ".reality")
                try await model.write(to: url)
                let reloaded = try await Entity(contentsOf: url)
                let bounds = reloaded.visualBounds(relativeTo: reloaded)
                guard bounds.extents.x > 0, bounds.extents.y > 0, bounds.extents.z > 0 else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                report.append("\(model.name): reloaded, bounds \(bounds.extents)")
            }
            try report.joined(separator: "\n").write(to: directory.appending(path: "validation.txt"), atomically: true, encoding: .utf8)
        } catch {
            try? String(describing: error).write(to: directory.appending(path: "export-error.txt"), atomically: true, encoding: .utf8)
        }
    }
}
#endif
