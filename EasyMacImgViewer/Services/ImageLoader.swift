import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum DecodeResult {
    case still(CGImage)
    case animated(frames: [CGImage], delays: [Double])
    case failed
}

enum ImageLoader {
    static func decode(from url: URL) async -> DecodeResult {
        await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithURL(
                url as CFURL,
                [kCGImageSourceShouldCache: false] as CFDictionary
            ) else {
                return .failed
            }

            if isAnimated(source) {
                let count = CGImageSourceGetCount(source)
                var frames: [CGImage] = []
                var delays: [Double] = []
                for i in 0..<count {
                    if let frame = CGImageSourceCreateImageAtIndex(
                        source,
                        i,
                        [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
                    ) {
                        frames.append(frame)
                    }
                    delays.append(delay(at: i, in: source))
                }
                if frames.count > 1 {
                    return .animated(frames: frames, delays: delays)
                }
            }

            let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
            if let image = CGImageSourceCreateImageAtIndex(source, 0, options) {
                let orientation = readOrientation(at: 0, in: source)
                return .still(applyingOrientation(image, orientation))
            }

            if let nsImage = NSImage(contentsOf: url),
               let cg = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                return .still(cg)
            }
            return .failed
        }.value
    }

    private static func isAnimated(_ source: CGImageSource) -> Bool {
        guard CGImageSourceGetCount(source) > 1 else { return false }
        let type = CGImageSourceGetType(source) as String?
        return type == UTType.gif.identifier || type == "org.webmproject.webp"
    }

    private static func delay(at index: Int, in source: CGImageSource) -> Double {
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] else {
            return 0.1
        }
        if let gif = props[kCGImagePropertyGIFDictionary] as? [CFString: Any],
           let value = gif[kCGImagePropertyGIFDelayTime] as? Double {
            return value
        }
        if let webp = props[kCGImagePropertyWebPDictionary] as? [CFString: Any],
           let value = webp[kCGImagePropertyWebPDelayTime] as? Double {
            return value * 0.01
        }
        return 0.1
    }

    private static func readOrientation(at index: Int, in source: CGImageSource) -> CGImagePropertyOrientation {
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let raw = props[kCGImagePropertyOrientation] as? UInt32,
              let orientation = CGImagePropertyOrientation(rawValue: raw) else {
            return .up
        }
        return orientation
    }

    static func applyingOrientation(_ image: CGImage, _ orientation: CGImagePropertyOrientation) -> CGImage {
        guard orientation != .up else { return image }
        let rotated = (orientation == .left || orientation == .right
            || orientation == .leftMirrored || orientation == .rightMirrored)
        let width = rotated ? image.height : image.width
        let height = rotated ? image.width : image.height
        let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return image
        }
        let tx = CGFloat(image.width)
        let ty = CGFloat(image.height)
        let transform: CGAffineTransform
        switch orientation {
        case .up: transform = .identity
        case .upMirrored: transform = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: tx, ty: 0)
        case .down: transform = CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: tx, ty: ty)
        case .downMirrored: transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: ty)
        case .leftMirrored: transform = CGAffineTransform(a: 0, b: 1, c: 1, d: 0, tx: 0, ty: 0)
        case .right: transform = CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: tx)
        case .rightMirrored: transform = CGAffineTransform(a: 0, b: -1, c: -1, d: 0, tx: ty, ty: tx)
        case .left: transform = CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: ty, ty: 0)
        }
        context.concatenate(transform)
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return context.makeImage() ?? image
    }
}
