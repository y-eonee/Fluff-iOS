import RealityKit
import UIKit

/// Sculpted, shared models with actual short pile, leaves and branching wood geometry.
enum WindowOrganicModels {
    struct Parts { let body: MeshResource; let detail: [MeshResource] }
    private static var cached: [Int: Parts] = [:]
    static func clearCache() { cached.removeAll() }

    static func cloud(_ variant: Int) async -> Parts { await parts(variant % 3, tree: false) }
    static func canopy(_ variant: Int) async -> Parts { await parts(10 + variant % 3, tree: true) }
    private static func parts(_ key: Int, tree: Bool) async -> Parts {
        if let value = cached[key] { return value }
        let variant = key % 10
        let lobes: [OrganicVolumeGeometry.Lobe]
        if tree {
            let stretch: Float = variant == 1 ? 1.18 : 1
            lobes = [
                .init(center: [0, 0.02, 0], radius: [0.27, 0.26 * stretch, 0.25]),
                .init(center: [-0.18, 0.10, 0.03], radius: [0.23, 0.25, 0.23]),
                .init(center: [0.17, 0.08, -0.03], radius: [0.24, 0.25, 0.22]),
                .init(center: [0.02, 0.27 * stretch, 0.01], radius: [0.21, 0.23, 0.21]),
                .init(center: [-0.06, -0.05, 0.18], radius: [0.23, 0.22, 0.19]),
                .init(center: [0.15, 0.23, 0.12], radius: [0.17, 0.18, 0.17]),
                .init(center: [-0.18, 0.23, -0.08], radius: [0.18, 0.18, 0.18])
            ]
        } else {
            let lift = Float(variant) * 0.025
            lobes = [
                .init(center: [0, -0.025, 0], radius: [0.43, 0.13, 0.19]),
                .init(center: [-0.19, 0.075 + lift, 0.01], radius: [0.22, 0.22, 0.20]),
                .init(center: [0.055, 0.15 - lift, -0.015], radius: [0.24, 0.255, 0.22]),
                .init(center: [0.29, 0.045, 0.015], radius: [0.20, 0.18, 0.18]),
                .init(center: [-0.35, 0.015, 0.045], radius: [0.14, 0.145, 0.15]),
                .init(center: [-0.07, 0.025, 0.145], radius: [0.22, 0.17, 0.13]),
                .init(center: [0.19, 0.04, 0.13], radius: [0.16, 0.14, 0.13])
            ]
        }
        let surface = await Task.detached(priority: .userInitiated) {
            OrganicVolumeGeometry.build(lobes: lobes, blend: tree ? 0.075 : 0.065, resolution: tree ? 72 : 80, seed: key)
        }.value
        let body = mesh(surface, name: tree ? "sculpted-canopy" : "continuous-cotton-cloud")
        let detail = tree ? leaves(on: surface, seed: variant) : [pile(on: surface, seed: variant)]
        let value = Parts(body: body, detail: detail)
        cached[key] = value
        return value
    }
    private static func mesh(_ surface: OrganicVolumeGeometry.Surface, name: String) -> MeshResource {
        var descriptor = MeshDescriptor(name: name)
        descriptor.positions = .init(surface.positions); descriptor.normals = .init(surface.normals)
        descriptor.textureCoordinates = .init(surface.uv); descriptor.primitives = .triangles(surface.indices)
        return try! MeshResource.generate(from: [descriptor])
    }
    private static func random(_ i: Int, _ seed: Int) -> Float {
        var value = UInt32(truncatingIfNeeded: i) &* 747796405 &+ UInt32(truncatingIfNeeded: seed) &* 2891336453
        value = ((value >> ((value >> 28) + 4)) ^ value) &* 277803737
        return Float((value ^ (value >> 22)) & 65535) / 65535
    }
    private static func samples(on surface: OrganicVolumeGeometry.Surface, count: Int, seed: Int) -> [(SIMD3<Float>, SIMD3<Float>)] {
        var cumulative: [Float] = [], area: Float = 0
        for i in stride(from: 0, to: surface.indices.count, by: 3) {
            let a = surface.positions[Int(surface.indices[i])], b = surface.positions[Int(surface.indices[i + 1])], c = surface.positions[Int(surface.indices[i + 2])]
            area += simd_length(simd_cross(b - a, c - a)) * 0.5
            cumulative.append(area)
        }
        return (0..<count).map { sample in
            let target = random(sample, seed + 33) * area
            var lower = 0, upper = cumulative.count - 1
            while lower < upper { let middle = (lower + upper) / 2; if cumulative[middle] < target { lower = middle + 1 } else { upper = middle } }
            let ids = (0..<3).map { Int(surface.indices[lower * 3 + $0]) }
            let r = sqrt(random(sample, seed + 97)), s = random(sample, seed + 129)
            let weights: [Float] = [1 - r, r * (1 - s), r * s]
            var p = SIMD3<Float>.zero, n = SIMD3<Float>.zero
            for i in 0..<3 { p += surface.positions[ids[i]] * weights[i]; n += surface.normals[ids[i]] * weights[i] }
            return (p, simd_normalize(n))
        }
    }
    private static func pile(on surface: OrganicVolumeGeometry.Surface, seed: Int) -> MeshResource {
        var fibers = OrganicVolumeGeometry.Surface()
        for (i, sample) in samples(on: surface, count: 4200, seed: seed).enumerated() {
            let (p, n) = sample
            let axis = simd_normalize(simd_cross(n, abs(n.y) < 0.9 ? SIMD3<Float>(0, 1, 0) : [1, 0, 0]))
            let tangent = axis * cos(Float(i)) + simd_cross(n, axis) * sin(Float(i))
            let length = 0.0015 + random(i, seed + 41) * 0.0025
            let start = UInt32(fibers.positions.count)
            fibers.positions += [p - tangent * 0.00045, p + tangent * 0.00045, p + n * length + tangent * 0.0008]
            fibers.normals += [n, n, n]; fibers.uv += [.zero, .zero, .zero]
            fibers.indices += [start, start + 1, start + 2, start + 2, start + 1, start]
        }
        return mesh(fibers, name: "cotton-cloud-short-pile")
    }
    private static func leaves(on surface: OrganicVolumeGeometry.Surface, seed: Int) -> [MeshResource] {
        var groups = Array(repeating: OrganicVolumeGeometry.Surface(), count: 3)
        for (i, sample) in samples(on: surface, count: 700, seed: seed + 91).enumerated() {
            let (position, n) = sample
            let axis = simd_normalize(simd_cross(n, abs(n.y) < 0.9 ? SIMD3<Float>(0, 1, 0) : [1, 0, 0]))
            let angle = random(i, seed + 77) * 2 * Float.pi
            let up = axis * cos(angle) + simd_cross(n, axis) * sin(angle), right = simd_cross(up, n)
            let length = 0.058 + random(i, seed + 31) * 0.040, width = length * 0.34
            let p = position + n * 0.002, group = i % 3, start = UInt32(groups[group].positions.count)
            // Smoothly curled leaves, with a rounded center vein instead of pyramid facets.
            let rows = 6, columns = 4
            for row in 0...rows { for column in 0...columns {
                let v = Float(row)/Float(rows), u = Float(column)/Float(columns)*2-1
                let shoulder = pow(max(0,sin(v * .pi)),0.7)
                let arch = sin(v * .pi) * (1-u*u) * length*0.13 + v*v*length*0.08
                let point = p + up*((v-0.5)*length) + right*(u*width*shoulder) + n*arch
                let normal = simd_normalize(n + right*(u*0.40) - up*(cos(v * .pi)*0.35 + v*0.12))
                groups[group].positions.append(point); groups[group].normals.append(normal)
                groups[group].uv.append([(u+1)*0.5,v])
                if row < rows && column < columns {
                    let a = start + UInt32(row*(columns+1)+column), b = a+UInt32(columns+1)
                    groups[group].indices += [a,b,a+1,a+1,b,b+1,a+1,b,a,b+1,b,a+1]
                }
            } }

        }
        return groups.enumerated().map { mesh($0.element, name: "layered-felt-leaves-\($0.offset)") }
    }
    static let branches: MeshResource = {
        var surface = OrganicVolumeGeometry.Surface()
        func branch(from: SIMD3<Float>, to: SIMD3<Float>, baseRadius: Float, tipRadius: Float, bend: Float) {
            let rows = 12, columns = 16
            let direction = simd_normalize(to - from)
            let side = simd_normalize(simd_cross(direction, abs(direction.z) < 0.9 ? SIMD3<Float>(0, 0, 1) : [1, 0, 0]))
            let other = simd_cross(direction, side), start = UInt32(surface.positions.count)
            for row in 0...rows {
                let t = Float(row) / Float(rows), center = simd_mix(from, to, SIMD3(repeating: t)) + side * sin(t * .pi) * bend
                for column in 0...columns {
                    let u = Float(column) / Float(columns), angle = u * 2 * .pi
                    let n = side * cos(angle) + other * sin(angle)
                    let radius = (baseRadius * (1 - t) + tipRadius * t) * (1 + 0.07 * sin(angle * 5 + t * 12))
                    surface.positions.append(center + n * radius); surface.normals.append(n); surface.uv.append([u, t * 3])
                    if row < rows && column < columns {
                        let a = start + UInt32(row * (columns + 1) + column), b = a + UInt32(columns + 1)
                        surface.indices += [a, b, a + 1, a + 1, b, b + 1]
                    }
                }
            }
        }
        branch(from: [0, 0, 0], to: [0.025, 0.88, 0], baseRadius: 0.055, tipRadius: 0.012, bend: -0.035)
        for (to, y) in [(SIMD3<Float>(-0.26, 0.72, 0.05), Float(0.35)), ([0.25, 0.78, -0.04], 0.43), ([0.02, 0.69, 0.23], 0.48)] {
            branch(from: [0, y, 0], to: to, baseRadius: 0.026, tipRadius: 0.008, bend: 0.025)
        }
        return mesh(surface, name: "tapered-curving-trunk-and-branches")
    }()
}
