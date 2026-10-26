import RealityKit
import UIKit

/// Individually named, editable 3D body parts. No billboard is used for the preset body.
enum PresetDollModel {
    static func roundedEar(width: Float, height: Float, depth: Float) -> MeshResource {
        let rows = 32, columns = 48
        var positions: [SIMD3<Float>] = []
        var uv: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for row in 0...rows {
            let v = Float(row) / Float(rows)
            let angle = v * Float.pi
            let y = cos(angle)
            let radius = sin(angle)
            for column in 0...columns {
                let u = Float(column) / Float(columns)
                let theta = u * 2 * Float.pi
                positions.append([cos(theta) * radius * (1 - 0.60 * y) * width * 0.5,
                                  y * height * 0.5,
                                  sin(theta) * radius * depth * 0.5])
                uv.append([u, v])
                if row < rows && column < columns {
                    let a = UInt32(row * (columns + 1) + column), b = a + UInt32(columns + 1)
                    indices += [a, a + 1, b, a + 1, b + 1, b]
                }
            }
        }
        var mesh = MeshDescriptor(name: "padded-rounded-ear")
        mesh.positions = .init(positions); mesh.textureCoordinates = .init(uv)
        mesh.normals = .init(positions.map { simd_normalize(SIMD3<Float>($0.x / (width * width), $0.y / (height * height), $0.z / (depth * depth))) })
        mesh.primitives = .triangles(indices)
        return (try? MeshResource.generate(from: [mesh])) ?? .generateSphere(radius: width / 2)
    }
    // Elliptical sewn panels give the apron a flared hem instead of a box silhouette.
    private static func apronMesh() -> MeshResource {
        var points: [SIMD3<Float>] = []
        var uv: [SIMD2<Float>] = []
        var triangles: [UInt32] = []
        let rows = 20, columns = 64
        for row in 0...rows {
            let v = Float(row) / Float(rows)
            let width = 0.056 + 0.024 * pow(v, 0.7) - 0.004 * pow(max(0, (v - 0.85) / 0.15), 2)
            for column in 0...columns {
                let u = Float(column) / Float(columns), a = u * 2 * Float.pi
                points.append([cos(a) * width, 0.052 - v * 0.111, sin(a) * (0.059 + 0.006 * v)])
                uv.append([u, v])
                if row < rows && column < columns {
                    let i = UInt32(row * (columns + 1) + column), j = i + UInt32(columns + 1)
                    triangles += [i, i + 1, j, i + 1, j + 1, j]
                }
            }
        }
        var mesh = MeshDescriptor(name: "flared-cloth-apron")
        mesh.positions = .init(points); mesh.textureCoordinates = .init(uv); mesh.primitives = .triangles(triangles)
        mesh.normals = .init(points.map { simd_normalize(SIMD3<Float>($0.x / (0.075 * 0.075), 2.0, $0.z / (0.063 * 0.063))) })
        return (try? MeshResource.generate(from: [mesh])) ?? .generateSphere(radius: 0.065)
    }

    private static func footMesh() -> MeshResource {
        func rounded(_ value: Float, power: Float) -> Float {
            (value < 0 ? -1 : 1) * pow(abs(value), power)
        }
        var points: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = [], indices: [UInt32] = []
        let rows = 40, columns = 64
        for row in 0...rows {
            let v = Float(row) / Float(rows), a = v * Float.pi
            for column in 0...columns {
                let u = Float(column) / Float(columns), b = u * 2 * Float.pi
                let p = SIMD3<Float>(rounded(sin(a), power: 0.95) * rounded(cos(b), power: 0.95),
                                     rounded(cos(a), power: 0.95),
                                     rounded(sin(a), power: 0.95) * rounded(sin(b), power: 0.95))
                points.append(p * 0.5)
                normals.append(simd_normalize(SIMD3<Float>(rounded(p.x, power: 1.105263), rounded(p.y, power: 1.105263), rounded(p.z, power: 1.105263))))
                uv.append([u, v])
                if row < rows && column < columns {
                    let a = UInt32(row * (columns + 1) + column), b = a + UInt32(columns + 1)
                    indices += [a, a+1, b, a+1, b+1, b]
                }
            }
        }
        var mesh = MeshDescriptor(name: "soft-flat-soled-foot")
        mesh.positions = .init(points); mesh.normals = .init(normals)
        mesh.textureCoordinates = .init(uv); mesh.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [mesh])
    }

    private static func pocketMesh() -> MeshResource {
        var contour: [SIMD3<Float>] = [[-0.035, 0.025, 0], [0.035, 0.025, 0], [0.035, -0.007, 0]]
        for i in 0...12 {
            let a = Float(i) / 12 * Float.pi / 2
            contour.append([0.014 + cos(a) * 0.021, -0.007 - sin(a) * 0.021, 0])
        }
        contour.append([-0.014, -0.028, 0])
        for i in 0...12 {
            let a = Float(i) / 12 * Float.pi / 2
            contour.append([-0.014 - sin(a) * 0.021, -0.007 - cos(a) * 0.021, 0])
        }
        let rings = 8, count = contour.count
        var points: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], indices: [UInt32] = []
        for ring in 0...rings {
            let r = Float(ring) / Float(rings)
            for p in contour {
                let point = SIMD3<Float>(p.x * r, p.y * r, 0.004 * (1 - r * r))
                points.append(point)
                normals.append(simd_normalize(SIMD3<Float>(point.x * 6, point.y * 10, 1)))
            }
            if ring < rings {
                for i in 0..<count {
                    let a = UInt32(ring * count + i), b = UInt32(ring * count + (i + 1) % count)
                    let c = a + UInt32(count), d = b + UInt32(count)
                    indices += [a, b, c, b, d, c]
                }
            }
        }
        var mesh = MeshDescriptor(name: "padded-u-shaped-pocket")
        mesh.positions = .init(points); mesh.normals = .init(normals)
        mesh.textureCoordinates = .init(points.map { [$0.x / 0.07 + 0.5, $0.y / 0.051 + 0.5] })
        mesh.primitives = .triangles(indices)
        return (try? MeshResource.generate(from: [mesh])) ?? .generatePlane(width: 0.07, height: 0.05)
    }

    private static func headMesh(width: Float, photoOpening: Bool) -> MeshResource {
        var points: [SIMD3<Float>] = []
        var uv: [SIMD2<Float>] = []
        var normals: [SIMD3<Float>] = []
        var triangles: [UInt32] = []
        let rows = 48, columns = 64
        for row in 0...rows {
            let v = Float(row) / Float(rows), a = v * Float.pi
            let y = cos(a)
            for column in 0...columns {
                let u = Float(column) / Float(columns), b = u * 2 * Float.pi
                points.append(PresetHeadSurface.point(latitude: y, angle: b, width: width))
                normals.append(PresetHeadSurface.normal(latitude: y, angle: b, width: width))
                uv.append([u, v])
                if row < rows && column < columns {
                    let i = UInt32(row * (columns + 1) + column), j = i + UInt32(columns + 1)
                    triangles += [i, i + 1, j, i + 1, j + 1, j]
                }
            }
        }
        if photoOpening {
            triangles = stride(from: 0, to: triangles.count, by: 3).flatMap { i -> [UInt32] in
                let face = Array(triangles[i..<i + 3])
                let center = (points[Int(face[0])] + points[Int(face[1])] + points[Int(face[2])]) / 3
                return PresetFaceMesh.insideOpening(center) ? [] : face
            }
        }
        var mesh = MeshDescriptor(name: "stuffed-head-cheeks")
        mesh.normals = .init(normals)
        mesh.positions = .init(points); mesh.textureCoordinates = .init(uv); mesh.primitives = .triangles(triangles)
        return (try? MeshResource.generate(from: [mesh])) ?? .generateSphere(radius: 0.13)
    }
    private static func headFibers(width: Float, photoOpening: Bool) -> MeshResource? {
        var points: [SIMD3<Float>] = []
        var triangles: [UInt32] = []
        var fiberNormals: [SIMD3<Float>] = []
        let count = 42000
        for i in 0..<count {
            let y = 1 - 2 * (Float(i) + 0.5) / Float(count)
            let a = Float(i) * 2.3999632
            let p = PresetHeadSurface.point(latitude: y, angle: a, width: width)
            if photoOpening && PresetFaceMesh.insideOpening(p) { continue }
            let n = PresetHeadSurface.normal(latitude: y, angle: a, width: width)
            let tangent = simd_normalize(simd_cross(n, abs(n.y) > 0.9 ? SIMD3<Float>(1, 0, 0) : SIMD3<Float>(0, 1, 0)))
            let other = simd_cross(n, tangent)
            let length: Float = 0.0006 + Float((i * 37) % 97) / 97 * 0.0007
            for axis in [tangent, other] {
                let base = UInt32(points.count)
                points += [p - axis * 0.00013, p + axis * 0.00013, p + n * length + tangent * 0.00025]
                let tilt = Float((i * 53) % 101) / 100 - 0.5
                let fiberNormal = simd_normalize(n + axis * tilt * 0.65)
                fiberNormals += [fiberNormal, fiberNormal, fiberNormal]
                triangles += [base, base + 1, base + 2, base + 2, base + 1, base]
            }
        }
        var mesh = MeshDescriptor(name: "short-plush-pile")
        mesh.normals = .init(fiberNormals)
        mesh.positions = .init(points); mesh.primitives = .triangles(triangles)
        return try? MeshResource.generate(from: [mesh])
    }

    /// Fine pile follows the curved limbs and ears, rather than leaving smooth spheres.
    private static func roundPile() -> MeshResource? {
        var vertices: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for i in 0..<5000 {
            let y = 1 - 2 * (Float(i) + 0.5) / 5000
            let angle = Float(i) * 2.3999632
            let radius = sqrt(max(0, 1 - y * y))
            let n = SIMD3<Float>(cos(angle) * radius, y, sin(angle) * radius)
            let t = simd_normalize(simd_cross(n, abs(y) > 0.9 ? SIMD3<Float>(1, 0, 0) : SIMD3<Float>(0, 1, 0)))
            let p = n * 0.5
            let length: Float = 0.006 + Float((i * 37) % 97) / 97 * 0.006
            let base = UInt32(vertices.count)
            vertices += [p - t * 0.0014, p + t * 0.0014, p + n * length + t * 0.002]
            indices += [base, base + 1, base + 2, base + 2, base + 1, base]
        }
        var mesh = MeshDescriptor(name: "limb-short-pile")
        mesh.normals = .init(vertices.map { simd_normalize($0) })
        mesh.positions = .init(vertices); mesh.primitives = .triangles(indices)
        return try? MeshResource.generate(from: [mesh])
    }

    static func make(_ configuration: PresetConfiguration, happy: Bool = false) async -> Entity {
        if configuration.isPhotoSuit == true { return await PhotoSuitModel.make(configuration) }
        let root = Entity()
        let textile = await PresetTextile.textures()
        let texture = textile?.color
        let normal = textile?.normal
        let fur = configuration.shape == .bear ? "#D5B59D" : configuration.shape == .rabbit ? "#E3D7CF" : "#E1D8D2"
        let garment = configuration.shape == .bear ? "#C58B87" : configuration.shape == .rabbit ? "#9E8CA8" : "#94A58D"
        func material(_ hex: String, cloth: Bool = true) -> PhysicallyBasedMaterial {
            var m = PhysicallyBasedMaterial()
            m.baseColor = .init(tint: Palette.uiColor(hex), texture: cloth ? texture.map { .init($0) } : nil)
            if cloth, let normal { m.normal = .init(texture: .init(normal)) }
            m.roughness = .init(floatLiteral: 0.95)
            m.metallic = .init(floatLiteral: 0)
            m.textureCoordinateTransform.scale = [3.2, 3.2]
            if cloth { m.sheen = .init(tint: UIColor(white: 0.25, alpha: 1)) }
            return m
        }
        func apronMaterial(_ hex: String) -> PhysicallyBasedMaterial {
            var m = material(hex)
            m.textureCoordinateTransform.scale = [3, 3]
            m.sheen = .init(tint: UIColor(white: 0.12, alpha: 1))
            return m
        }
        let limbPile = roundPile()
        var groups: [DollPart: Entity] = [:]
        let armX: Float = configuration.shape == .cat ? 0.062 : 0.075
        let armY: Float = configuration.shape == .cat ? 0.087 : 0.112
        let origins: [DollPart: SIMD3<Float>] = [.head: [0, configuration.shape == .cat ? 0.228 : configuration.shape == .bear ? 0.251 : 0.248, 0], .torso: [0, configuration.shape == .cat ? 0.112 : 0.122, 0], .leftArm: [-armX, armY, 0.045], .rightArm: [armX, armY, 0.045], .leftLeg: [-0.042, 0.037, 0.020], .rightLeg: [0.042, 0.037, 0.020], .ears: [0, 0.245, 0]]
        for part in DollPart.allCases {
            let p = configuration.part(part)
            let group = Entity(); group.name = part.rawValue
            group.position = origins[part]! + SIMD3<Float>(0, p.offset * 0.05, 0)
            group.scale = [p.size * p.width, p.size * p.length, p.size]
            if part == .head && configuration.shape == .rabbit { group.scale.y *= 0.97 }
            if part == .torso { group.scale.x *= configuration.shape == .cat ? 0.88 : 1.08 }
            if configuration.shape == .cat && (part == .head || part == .ears) {
                group.orientation = simd_quatf(angle: -0.045, axis: [0, 0, 1])
            }
            root.addChild(group); groups[part] = group
        }
        func ball(_ name: String, _ part: DollPart, _ size: SIMD3<Float>, _ position: SIMD3<Float>, _ color: String, cloth: Bool = true) -> ModelEntity {
            let mesh: MeshResource = name == "foot"
                ? footMesh()
                : .generateSphere(radius: 0.5)
            let model = ModelEntity(mesh: mesh, materials: [material(color, cloth: cloth)])
            model.name = name; model.scale = size; model.position = position
            if ["paw", "shoulder", "foot", "floppy-ear", "round-ear", "body.fur", "neck.fur"].contains(name), let limbPile {
                let pile = ModelEntity(mesh: limbPile, materials: [material(color, cloth: false)])
                pile.name = "limb.short-pile"
                pile.components.set(DynamicLightShadowComponent(castsShadow: false)); model.addChild(pile)
            }
            groups[part]!.addChild(model)
            return model
        }
        func color(_ part: DollPart, _ fallback: String) -> String { configuration.part(part).color ?? fallback }
        let headWidth: Float = configuration.shape == .rabbit ? 0.116 : 0.128
        let head = ModelEntity(mesh: headMesh(width: headWidth, photoOpening: configuration.face != nil), materials: [material(color(.head, fur))])
        head.name = "head.fur"; groups[.head]!.addChild(head)
        if let pile = headFibers(width: headWidth, photoOpening: configuration.face != nil) {
            let fibers = ModelEntity(mesh: pile, materials: [material(color(.head, fur), cloth: false)])
            fibers.name = "head.short-pile"
            fibers.components.set(DynamicLightShadowComponent(castsShadow: false)); groups[.head]!.addChild(fibers)
        }
        _ = ball("body.fur", .torso, [0.15, 0.115, 0.12], .zero, fur)
        // A soft collar overlaps both sewn volumes, avoiding a pinched point below the chin.
        let neckWidth = min(1, configuration.part(.head).size * configuration.part(.head).width)
        _ = ball("neck.fur", .torso, [0.120 * neckWidth, 0.080, 0.108], [0, 0.042, 0.006], color(.head, fur))
        let apron = ModelEntity(mesh: apronMesh(), materials: [apronMaterial(color(.torso, garment))])
        apron.name = "apron"; apron.position = [0, -0.006, 0.005]; groups[.torso]!.addChild(apron)
        let pocketTint = configuration.shape == .bear ? "#CC9592" : configuration.shape == .rabbit ? "#A793B0" : "#9BAB92"
        var pocketEdgeMaterial = apronMaterial(color(.torso, garment))
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        Palette.uiColor(color(.torso, garment)).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        pocketEdgeMaterial.baseColor.tint = UIColor(red: red * 0.83, green: green * 0.83, blue: blue * 0.83, alpha: 1)
        let pocketEdge = ModelEntity(mesh: pocketMesh(), materials: [pocketEdgeMaterial])
        pocketEdge.name = "pocket.fold"; pocketEdge.scale = [1.045, 1.045, 1]
        pocketEdge.position = [0, -0.0235, 0.076]; groups[.torso]!.addChild(pocketEdge)
        let pocket = ModelEntity(mesh: pocketMesh(), materials: [apronMaterial(color(.torso, pocketTint))])
        pocket.position = [0, -0.023, 0.077]; groups[.torso]!.addChild(pocket)
        let thread = configuration.shape == .bear ? "#D4A59C" : configuration.shape == .rabbit ? "#BBAACB" : "#B4C0A4"
        for side: Float in [-1, 1] {
            for i in 0..<6 {
                _ = ball("pocket.stitch", .torso, [0.0011, 0.0022, 0.0010], [side * 0.030, -0.005 - Float(i) * 0.004, 0.081], thread)
            }
            for i in 0..<9 {
                let a = Float(i) / 9 * Float.pi / 2
                let stitch = ball("pocket.stitch", .torso, [0.0011, 0.0022, 0.0010],
                                  [side * (0.014 + cos(a) * 0.016), -0.030 - sin(a) * 0.016, 0.081], thread)
                stitch.orientation = simd_quatf(angle: -side * a, axis: [0,0,1])
            }
        }
        for i in 0..<8 {
            _ = ball("pocket.stitch", .torso, [0.0022, 0.0011, 0.0010], [-0.014 + Float(i) * 0.004, -0.046, 0.081], thread)
        }
        for i in 0..<17 {
            _ = ball("pocket.top-stitch", .torso, [0.0018, 0.0010, 0.0010], [-0.028 + Float(i) * 0.0035, -0.004, 0.080], thread)
        }
        for i in 0..<35 {
            let a = Float(i) / 34 * Float.pi
            _ = ball("hem.stitch", .torso, [0.0018, 0.0010, 0.0010], [cos(a) * 0.077, -0.059, sin(a) * 0.066 + 0.005], thread)
        }
        for x: Float in [-0.034, 0.034] {
            let strap = ModelEntity(mesh: .generateBox(size: [0.009, 0.031, 0.008], cornerRadius: 0.004), materials: [material("#FFF2D9")])
            strap.position = [x, 0.023, 0.064]; groups[.torso]!.addChild(strap)
            _ = ball("button", .torso, [0.015, 0.015, 0.009], [x, 0.010, 0.071], "#FFF2D9")
        }
        for part in [DollPart.leftArm, .rightArm] {
            let arm = PresetArmMesh.make(side: part == .leftArm ? -1 : 1, material: material(color(part, fur)))
            groups[part]!.addChild(arm)
            if happy { groups[part]!.position.y += 0.06 }
        }
        for part in [DollPart.leftLeg, .rightLeg] { _ = ball("foot", part, [0.083, 0.065, 0.092], .zero, color(part, fur)) }
        for side: Float in [-1, 1] {
            if configuration.shape == .bear {
                _ = ball("round-ear", .ears, [0.087, 0.09, 0.065], [side * 0.104, 0.083, -0.018], color(.ears, fur))
                _ = ball("ear-lining", .ears, [0.039, 0.044, 0.012], [side * 0.104, 0.083, 0.015], "#D4A9A4")
            } else {
                for ear in PresetEarMesh.make(shape: configuration.shape, side: side,
                                               fur: material(color(.ears, fur)), lining: material("#E8B4B5")) {
                    groups[.ears]!.addChild(ear)
                }
            }
        }
        if let data = configuration.face, let image = UIImage(data: data)?.cgImage,
           let texture = try? await TextureResource(image: image, options: .init(semantic: .color)) {
            var faceMaterial = UnlitMaterial(); faceMaterial.color = .init(tint: .white, texture: .init(texture))
            if let uiImage = UIImage(data: data), let mask = SceneFactory.opacityMask(of: uiImage),
               let opacity = try? await TextureResource(image: mask, options: .init(semantic: .raw)) {
                faceMaterial.blending = .transparent(opacity: .init(scale: 1, texture: .init(opacity)))
                faceMaterial.opacityThreshold = 0.1
            }
            let photoMesh = PresetFaceMesh.photo(aspect: Float(image.width) / Float(image.height),
                                                zoom: configuration.faceScale,
                                                offsetX: configuration.faceOffsetX ?? 0,
                                                offsetY: configuration.faceOffsetY ?? 0)
            let backing = ModelEntity(mesh: photoMesh, materials: [material("#FFF4E7")])
            backing.name = "face.lining"; backing.position.z = -0.001; groups[.head]!.addChild(backing)
            let face = ModelEntity(mesh: photoMesh, materials: [faceMaterial])
            face.name = "face.user-photo"; groups[.head]!.addChild(face)
            let rim = ModelEntity(mesh: PresetFaceMesh.rim(), materials: [material(color(.head, fur))])
            rim.name = "face.padded-opening"; groups[.head]!.addChild(rim)
            for i in 0..<80 {
                let a = Float(i) / 80 * 2 * Float.pi
                let stitch = ball("face.seam", .head, [0.0014, 0.0025, 0.0015],
                                  [cos(a) * 0.086, -0.008 + sin(a) * 0.077, 0.104], "#F1DEC8")
                stitch.orientation = simd_quatf(angle: a, axis: [0, 0, 1])
            }
        } else {
            let yOffset: Float = configuration.shape == .cat ? 0 : -0.005
            let isBear = configuration.shape == .bear
            func facePoint(_ x: Float, _ y: Float, muzzle: Bool = false) -> SIMD3<Float> {
                let yy = y + yOffset
                let z: Float
                if muzzle && isBear {
                    let disk = max(0, 1 - pow(x / 0.0395, 2) - pow((y + 0.031) / 0.0285, 2))
                    z = 0.093 + 0.006 * sqrt(disk)
                } else {
                    z = PresetEmbroidery.surfaceZ(x: x, y: yy, width: headWidth)
                }
                return [x, yy, z + 0.0012]
            }
            var thread = material("#523221", cloth: false)
            thread.roughness = 0.90
            if isBear { _ = ball("muzzle", .head, [0.079, 0.057, 0.012], [0, -0.031 + yOffset, 0.093], "#F0DBC0") }
            for side: Float in [-1, 1] {
                if happy {
                    let path = (0...24).map { i -> SIMD3<Float> in
                        let a = Float(i) / 24 * .pi
                        return facePoint(side * 0.042 + cos(a) * 0.011, -0.006 + sin(a) * 0.008)
                    }
                    groups[.head]!.addChild(PresetEmbroidery.line(path, radius: 0.0018, material: thread, name: "smiling-eye"))
                } else {
                    let x = side * (isBear ? 0.043 : configuration.shape == .cat ? 0.039 : 0.042)
                    let eye = ball("eye", .head, [0.0165, 0.020, 0.0045], facePoint(x, -0.014), "#523221", cloth: false)
                    eye.model?.materials = [thread]
                    eye.components.set(DynamicLightShadowComponent(castsShadow: false))
                }
                if let blush = await PresetBlush.make(side: side, headWidth: headWidth, yOffset: yOffset) { groups[.head]!.addChild(blush) }
                let path = (0...28).map { i -> SIMD3<Float> in
                    let a = Float(i) / 28 * .pi
                    return facePoint(side * (0.0081 - cos(a) * 0.0081), -0.038 - sin(a) * 0.006, muzzle: true)
                }
                groups[.head]!.addChild(PresetEmbroidery.line(path, radius: 0.0016, material: thread, name: "smile"))
            }
            let nose = ModelEntity(mesh: roundedEar(width: isBear ? 0.013 : 0.0095, height: 0.0060, depth: 0.0035), materials: [thread])
            nose.name = "nose"; nose.position = facePoint(0, -0.030, muzzle: true)
            nose.orientation = simd_quatf(angle: .pi, axis: [0,0,1]); groups[.head]!.addChild(nose)
            let stem = (0...8).map { facePoint(0, -0.032 - Float($0) * 0.0009, muzzle: true) }
            groups[.head]!.addChild(PresetEmbroidery.line(stem, radius: 0.0013, material: thread, name: "mouth.center-thread"))
        }
        // Fibers are visual detail; the underlying head handles selection and collisions.
        for group in root.children {
            for child in group.children where child.name != "head.short-pile" {
                child.generateCollisionShapes(recursive: false)
            }
        }
        return root
    }
}
