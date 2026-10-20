import AppKit
import ImageIO

// 원본 PNG를 축소하지 않고 가구별로 묶는다. 실행: swift scripts/build_illustration_atlas.swift Malrang/Resources
struct Entry: Encodable {
    let texture: String
    let rect: [Float]
}
struct Tile {
    let name: String
    let image: CGImage
    var x = 0
    var y = 0
}
let resources = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let output = resources.appendingPathComponent("IllustrationAtlases", isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let faces = try JSONSerialization.jsonObject(with: Data(contentsOf: resources.appendingPathComponent("RoomIllustration.json"))) as! [String: [[String: Any]]]
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let bitmap = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
func save(_ image: CGImage, name: String) throws {
    let url = output.appendingPathComponent(name + ".png")
    let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("PNG 저장 실패: \(name)") }
}
var entries: [String: Entry] = [:]
for kind in faces.keys.sorted() {
    let names = Set(faces[kind]!.compactMap { $0["texture"] as? String })
    var tiles: [Tile] = []
    for name in names {
        let url = resources.appendingPathComponent("IllustrationTextures/\(name).png")
        let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
        let image: CGImage = CGImageSourceCreateImageAtIndex(source, 0, nil)!
        tiles.append(Tile(name: name, image: image))
    }
    tiles.sort { a, b in
        if a.image.height == b.image.height { return a.name < b.name }
        return a.image.height > b.image.height
    }
    guard !tiles.isEmpty else { continue }
    let gutter = 4
    var area: Int = 0
    var widest: Int = 0
    for tile in tiles {
        let w = tile.image.width + gutter * 2
        let h = tile.image.height + gutter * 2
        area += w * h
        widest = max(widest, w)
    }
    let width = ((max(widest, Int(Double(area).squareRoot().rounded(.up))) + 63) / 64) * 64
    var x = 0, y = 0, rowHeight = 0
    for index in tiles.indices {
        let w = tiles[index].image.width + gutter * 2, h = tiles[index].image.height + gutter * 2
        if x + w > width { x = 0; y += rowHeight; rowHeight = 0 }
        tiles[index].x = x + gutter
        tiles[index].y = y + gutter
        x += w
        rowHeight = max(rowHeight, h)
    }
    let height = ((y + rowHeight + 3) / 4) * 4
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: space, bitmapInfo: bitmap)!
    context.interpolationQuality = .none
    let name = "illustration_atlas_\(kind)"
    for tile in tiles {
        context.draw(tile.image, in: CGRect(x: tile.x, y: height - tile.y - tile.image.height, width: tile.image.width, height: tile.image.height))
        let left = Float(tile.x) / Float(width)
        let top = Float(tile.y) / Float(height)
        let w = Float(tile.image.width) / Float(width)
        let h = Float(tile.image.height) / Float(height)
        entries[tile.name] = Entry(texture: name, rect: [left, top, w, h])
    }
    try save(context.makeImage()!, name: name)
    // 투명도 마스크도 미리 만들어 앱 진입 시 픽셀 변환을 생략한다.
    let pixels = context.data!.assumingMemoryBound(to: UInt8.self)
    for i in stride(from: 0, to: width * height * 4, by: 4) {
        let alpha = pixels[i + 3]
        pixels[i] = alpha; pixels[i + 1] = alpha; pixels[i + 2] = alpha; pixels[i + 3] = 255
    }
    try save(context.makeImage()!, name: name + "_opacity")
    print("\(kind): \(tiles.count) images → \(width)×\(height) atlas")
}
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
try encoder.encode(entries).write(to: resources.appendingPathComponent("RoomIllustrationAtlas.json"))
print("Packed \(entries.count) original images without resizing")
