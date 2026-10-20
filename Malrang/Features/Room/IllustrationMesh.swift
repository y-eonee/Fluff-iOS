import Foundation
import simd

/// Figma 원본의 면·색·선. 가구 뒷면은 같은 면 색으로 닫아 둔다.
struct IllustrationFace: Decodable {
    var vertices: [[Float]]
    var triangles: [UInt32]
    var color: String
    var stroke: Bool
    var custom: Bool
    var closed: Bool
    var photo: Bool
    var hiddenByPhoto: Bool
    var texture: String?
    var textureVertices: [[Float]]?
    var textureRegion: [Float]? = nil
}

struct IllustrationMesh {
    var color: String
    var custom: Bool
    var photo = false
    var hiddenByPhoto = false
    var texture: String?
    var positions: [SIMD3<Float>] = []
    var triangles: [UInt32] = []
    var uv: [SIMD2<Float>] = []

    static func build(_ faces: [IllustrationFace], usesArtwork: Bool = true) -> [IllustrationMesh] {
        var batches: [String: IllustrationMesh] = [:]
        for (layer, face) in faces.enumerated() {
            let textured = usesArtwork && face.texture != nil && face.textureVertices?.count == 4
            let points = (textured ? face.textureVertices! : face.vertices).map { SIMD3<Float>($0[0], $0[1], $0[2]) }
            guard points.count >= 2 else { continue }
            var normal = SIMD3<Float>(1, 0, 1)
            if points.count >= 3 {
                let cross = simd_cross(points[1] - points[0], points[2] - points[0])
                if simd_length(cross) > 0.000001 { normal = cross }
            }
            normal = simd_normalize(normal)
            if simd_dot(normal, [1, 0.85, 1]) < 0 { normal = -normal }
            // 원본 SVG에서 겹쳐 그린 체크무늬와 벽지의 그리기 순서를 유지한다.
            let offset = normal * Float(layer) * 0.00004
            if textured || !face.triangles.isEmpty {
                let key = (face.texture ?? face.color) + "|\(face.custom)|\(face.photo)|\(face.hiddenByPhoto)"
                var batch = batches[key] ?? IllustrationMesh(color: face.color, custom: face.custom, photo: face.photo, hiddenByPhoto: face.hiddenByPhoto, texture: face.texture)
                let base = UInt32(batch.positions.count)
                batch.positions += points.map { $0 + offset }
                batch.triangles += (textured ? [0, 1, 2, 0, 2, 3] : face.triangles).map { $0 + base }
                if textured {
                    // SVG의 첫 꼭짓점은 이미지 왼쪽 위다. RealityKit의 이미지
                    // 텍스처는 V=1이 위쪽이므로 뒤집어 연결해야 면의 모양이 맞는다.
                    let region = face.textureRegion ?? [0, 0, 1, 1]
                    let left = region[0], right = left + region[2]
                    let top = 1 - region[1], bottom = top - region[3]
                    batch.uv += [[left, top], [right, top], [right, bottom], [left, bottom]]
                } else {
                    let axes: (Int, Int) = abs(normal.y) > 0.5 ? (0, 2) : abs(normal.x) > abs(normal.z) ? (2, 1) : (0, 1)
                    let minU = points.map { $0[axes.0] }.min() ?? 0
                    let minV = points.map { $0[axes.1] }.min() ?? 0
                    let width = max(0.0001, (points.map { $0[axes.0] }.max() ?? 1) - minU)
                    let height = max(0.0001, (points.map { $0[axes.1] }.max() ?? 1) - minV)
                    batch.uv += points.map { [($0[axes.0] - minU) / width, 1 - ($0[axes.1] - minV) / height] }
                }
                batches[key] = batch
            }
        }
        return batches.keys.sorted().compactMap { batches[$0] }
    }
}
