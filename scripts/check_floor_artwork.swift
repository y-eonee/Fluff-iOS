// xcrun swiftc -parse-as-library Malrang/Features/Room/FloorArtwork.swift scripts/check_floor_artwork.swift -o /tmp/check-floor-artwork
import CoreGraphics
import Foundation
import ImageIO

@main struct FloorArtworkChecks {
    static func pixels(_ image: CGImage) -> [UInt8] {
        var result = [UInt8](repeating: 0, count: image.width * image.height * 4)
        result.withUnsafeMutableBytes { bytes in
            let context = CGContext(data: bytes.baseAddress, width: image.width, height: image.height,
                                    bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return result
    }

    static func main() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let resources = root.appendingPathComponent("Malrang/Resources")
        let json = try Data(contentsOf: resources.appendingPathComponent("RoomIllustration.json"))
        let models = try JSONSerialization.jsonObject(with: json) as! [String: [[String: Any]]]
        let faces = models["floor"]!
        precondition(faces.count == 3 && faces.allSatisfy { $0["custom"] as? Bool == true })
        for face in faces {
            let name = face["texture"] as! String
            let url = resources.appendingPathComponent("IllustrationTextures/\(name).png")
            let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
            let original = pixels(image)
            let blue = pixels(FloorArtwork.recolored(image, tint: [0.35, 0.67, 0.9])!)
            let red = pixels(FloorArtwork.recolored(image, tint: [0.9, 0.4, 0.5])!)
            var fillCount = 0, inkCount = 0
            for i in stride(from: 0, to: original.count, by: 4) {
                precondition(original[i + 3] == blue[i + 3] && original[i + 3] == red[i + 3], "Changed cutout")
                guard original[i + 3] == 255 else { continue }
                if original[i + 2] < original[i + 1] && Int(original[i]) - Int(original[i + 1]) >= 18 {
                    precondition((0..<3).allSatisfy { abs(Int(original[i + $0]) - Int(blue[i + $0])) <= 1 }, "Changed brown outline")
                    inkCount += 1
                } else if original[i] > 220 {
                    precondition(blue[i + 2] > blue[i] && red[i] > red[i + 2], "Uncolored floor fill")
                    fillCount += 1
                }
            }
            precondition(fillCount > 100 && inkCount > 10, "Missing floor face or outline")
            precondition(pixels(image) == original, "Mutated original artwork")
            print("Passed \(name): entire fill recolored; outline, transparency, and original preserved")
        }
    }
}
