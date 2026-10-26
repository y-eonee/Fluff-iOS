#if DEBUG
import Foundation
import RealityKit
import UIKit

/// Rebuild the editable model files without touching the user's room or photos.
enum CozyModelExporter {
    /// Exercise the bundled files and their recoloring without editing saved room state.
    static func auditIfRequested() async {
        guard ProcessInfo.processInfo.arguments.contains("--audit-cozy-models") else { return }
        var report: [String] = []
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
            state.colorName = nil
            let original = await CozyFurniture.make(state, photoMaterial: PhysicallyBasedMaterial())
            let untouched = !matches((original.findEntity(named: part)?.components[ModelComponent.self]?.materials.first as? CustomMaterial)?.baseColor.tint, expected)
            report.append("\(kind.rawValue): \(bundled && recolored && preserved && untouched ? "PASS" : "FAIL") bundled=\(bundled), recolor=\(recolored), actual=\(String(describing: material?.baseColor.tint)), trim=\(preserved), cache=\(untouched)")
        }
        try? report.joined(separator: "\n").write(to: URL.documentsDirectory.appending(path: "cozy-model-audit.txt"), atomically: true, encoding: .utf8)
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
                                                     usesWindowLighting: false, useBakedModels: false)
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
