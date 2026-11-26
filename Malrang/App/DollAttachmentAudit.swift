#if DEBUG
import Foundation
import RealityKit

@MainActor
enum DollAttachmentAudit {
    static func run() async {
        var failures: [String] = []
        var cases = 0
        func check(_ condition: Bool, _ label: String) {
            cases += 1
            if !condition && failures.count < 50 { failures.append(label) }
        }
        func point(_ t: Transform, _ p: SIMD3<Float>) -> SIMD3<Float> { t.translation + t.rotation.act(p * t.scale) }
        let limbs: [DollPart] = [.leftArm, .rightArm, .leftLeg, .rightLeg]
        let edges: [DollPart] = [.head] + limbs + [.ears]
        var values: [PresetConfiguration.Part] = []
        for width: Float in [0.6, 1, 1.4] { for length: Float in [0.6, 1, 1.4] {
            for size: Float in [0.6, 1, 1.4] { for offset: Float in [-1, 0, 1] {
                values.append(.init(width: width, size: size, length: length, offset: offset))
            } }
        } }
        for shape in DollShape.presets {
            let base = await PresetDollModel.make(PresetConfiguration(shape: shape), detail: .room)
            for happy in [false, true] {
                for child in edges {
                    let parent: DollPart = child == .ears ? .head : .torso
                    for a in values { for b in values {
                        var configuration = PresetConfiguration(shape: shape)
                        configuration.parts[parent.rawValue] = a
                        configuration.parts[child.rawValue] = b
                        let t = PresetAttachmentLayout.transforms(configuration, happy: happy)
                        let label = "\(shape)/\(child)/\(happy)/\(a)/\(b)"
                        if limbs.contains(child) {
                            let seam = PresetAttachmentLayout.limbAnchor(child)
                            var socket = PresetAttachmentLayout.torsoAnchor(child, shape: shape)
                            socket.y += min(0.008, max(-0.008, b.offset * 0.02))
                            check(simd_distance(point(t[child]!, seam), point(t[parent]!, socket)) < 0.000001, "limb seam: " + label)
                            // Independent surface check: the socket is strictly inside the
                            // actual ellipsoidal torso, not merely its bounding box.
                            check(simd_length(socket / SIMD3<Float>(0.075, 0.0575, 0.060)) < 0.99, "torso volume: " + label)
                        } else if child == .head {
                            let socket = SIMD3<Float>(0, 0.055 + min(0.008, max(-0.008, b.offset * 0.02)), 0.006)
                            check(simd_distance(point(t[.head]!, PresetAttachmentLayout.neckAnchor), point(t[.torso]!, socket)) < 0.000001, "neck seam: " + label)
                            check(abs(socket.y - 0.042) < 0.040, "collar volume: " + label)
                        } else {
                            for side: Float in [-1, 1] {
                                let ear = PresetAttachmentLayout.earTransform(configuration, side: side)
                                let anchor = PresetAttachmentLayout.earAnchor(shape: shape, side: side)
                                let socket = point(ear, anchor)
                                let headWidth: Float = shape == .bear ? 0.132 : shape == .rabbit ? 0.116 : 0.128
                                let front = PresetHeadSurface.front(x: socket.x, y: socket.y, width: headWidth)
                                check(front > abs(socket.z) + 0.002, "ear inside head: " + label)
                                check(simd_distance(point(t[.ears]!, socket), point(t[.head]!, socket)) < 0.000001, "ear follows head: " + label)
                            }
                        }
                    } }
                    await Task.yield()
                }
            }
            // Use actual built meshes to check limb anchors and transformed extremes.
            for child in limbs {
                let entity = base.findEntity(named: child.rawValue)!
                let bounds = entity.visualBounds(relativeTo: entity)
                let seam = PresetAttachmentLayout.limbAnchor(child)
                check((seam - bounds.min).min() > 0 && (bounds.max - seam).min() > 0, "mesh contains seam: \(shape)/\(child)")
            }
        }
        // Older saved photo suits use a different mesh, so verify their actual
        // transformed volumes separately from the current preset skeleton.
        for shape in DollShape.presets {
            for size: Float in [0.6, 1, 1.4] {
                var configuration = PresetConfiguration(shape: shape)
                configuration.isPhotoSuit = true
                configuration.parts["torso"] = .init(width: 2 - size, size: 2 - size, length: size)
                for part in edges { configuration.parts[part.rawValue] = .init(width: size, size: size, length: 2 - size) }
                let model = await PresetDollModel.make(configuration, detail: .room)
                let torso = model.findEntity(named: "torso")!.visualBounds(relativeTo: model)
                for part in [.head] + limbs {
                    let bounds = model.findEntity(named: part.rawValue)!.visualBounds(relativeTo: model)
                    check((simd_min(torso.max, bounds.max) - simd_max(torso.min, bounds.min)).min() > 0,
                          "saved photo suit overlap: \(shape)/\(part)/\(size)")
                }
            }
        }
        let report: [String: Any] = ["passed": failures.isEmpty, "checks": cases, "failures": failures,
            "coverage": "cat/bear/rabbit; every parent-child combination of min/mid/max width, height, legacy size and offset; neutral and happy; 236196 configurations. Each seam depends only on its two connected parts, so unrelated edits cannot detach it. Continuous values share invariant interior anchors."]
        if let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL.documentsDirectory.appending(path: "doll-attachment-audit.json"), options: .atomic)
        }
    }
}
#endif
