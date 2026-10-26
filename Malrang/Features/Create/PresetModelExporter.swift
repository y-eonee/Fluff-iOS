#if DEBUG
import Foundation
import RealityKit
import UIKit

enum PresetModelExporter {
    static func exportIfRequested() async {
        guard ProcessInfo.processInfo.arguments.contains("--export-preset-models") else { return }
        let directory = URL.documentsDirectory.appending(path: "PresetModels", directoryHint: .isDirectory)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var report: [String] = []
            for shape in DollShape.presets {
                let configuration = PresetConfiguration(shape: shape)
                let model = await PresetDollModel.make(configuration)
                model.name = "preset_" + shape.rawValue
                let url = directory.appending(path: model.name + ".reality")
                try await model.write(to: url)
                let restored = try await Entity(contentsOf: url)
                let bounds = restored.visualBounds(relativeTo: restored)
                guard DollPart.allCases.allSatisfy({ restored.findEntity(named: $0.rawValue) != nil }),
                      bounds.extents.x > 0, bounds.extents.y > 0, bounds.extents.z > 0 else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                if shape != .bear {
                    guard let ears = restored.findEntity(named: DollPart.ears.rawValue),
                          ears.children.filter({ $0.name == "ear.padded-rim" }).count == 2,
                          ears.children.filter({ $0.name == "ear.inset-lining" }).count == 2,
                          ears.children.filter({ $0.name == "ear.sewn-back" }).count == 2 else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                }
                var edited = configuration
                edited.parts[DollPart.head.rawValue] = .init(width: 1.2, size: 0.9, length: 1.1, offset: 0.1, color: "#F3B7C8")
                edited.parts[DollPart.ears.rawValue] = .init(width: 0.85, size: 1, length: 1.15, offset: 0.1, color: "#FFF4E9")
                edited.face = UIImage(systemName: "face.smiling.fill")?.pngData()
                edited.faceScale = 1.6; edited.faceOffsetX = 0.25; edited.faceOffsetY = -0.2
                let decoded = try JSONDecoder().decode(PresetConfiguration.self, from: JSONEncoder().encode(edited))
                guard decoded == edited else { throw CocoaError(.fileReadCorruptFile) }
                let customized = await PresetDollModel.make(decoded)
                guard let head = customized.findEntity(named: DollPart.head.rawValue),
                      abs(head.scale.x - 1.08) < 0.001,
                      let ears = customized.findEntity(named: DollPart.ears.rawValue),
                      abs(ears.scale.x - 0.85) < 0.001, abs(ears.scale.y - 1.15) < 0.001,
                      customized.findEntity(named: "face.user-photo") != nil,
                      customized.findEntity(named: "face.seam") != nil,
                      customized.findEntity(named: "eye") == nil else { throw CocoaError(.fileReadCorruptFile) }
                report.append("\(model.name): PASS — reload, 7 editable parts, dimensions \(bounds.extents), head/ear customization and photo placement round trip")
            }
            try report.joined(separator: "\n").write(to: directory.appending(path: "validation.txt"), atomically: true, encoding: .utf8)
        } catch {
            try? String(describing: error).write(to: directory.appending(path: "export-error.txt"), atomically: true, encoding: .utf8)
        }
    }
}
#endif
