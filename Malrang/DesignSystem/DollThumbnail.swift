import CryptoKit
import SwiftUI

struct DollThumbnail: View {
    let data: Data
    var maxPixel = 420
    @State private var image: UIImage?
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 16 * 1024 * 1024
        cache.countLimit = 48
        return cache
    }()

    static func clearCache() { cache.removeAllObjects() }

    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFit() }
            else { Image(systemName: "teddybear").foregroundStyle(Color.a.soft) }
        }
        .onDisappear { image = nil }
        .task(id: data) {
            let key = "\(maxPixel)-\(SHA256.hash(data: data).description)" as NSString
            if let cached = Self.cache.object(forKey: key) { image = cached; return }
            let decoded = await ImageDownsampling.load(data, maxPixel: maxPixel)
            guard !Task.isCancelled else { return }
            image = decoded
            if let decoded, let cg = decoded.cgImage {
                Self.cache.setObject(decoded, forKey: key, cost: cg.bytesPerRow * cg.height)
            }
        }
    }
}
