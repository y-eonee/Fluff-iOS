import ImageIO
import UIKit

nonisolated enum ImageDownsampling {
    /// ImageIO decodes only the requested resolution, including EXIF rotation and alpha.
    static func image(_ data: Data, maxPixel: Int) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixel
              ] as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }

    static func aspectRatio(_ data: Data) -> Float {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
              let height = properties[kCGImagePropertyPixelHeight] as? NSNumber else { return 1 }
        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
        let ratio = width.floatValue / max(1, height.floatValue)
        return (5...8).contains(orientation) ? 1 / max(0.0001, ratio) : ratio
    }

    @concurrent static func load(_ data: Data, maxPixel: Int) async -> UIImage? {
        image(data, maxPixel: maxPixel)
    }
}
