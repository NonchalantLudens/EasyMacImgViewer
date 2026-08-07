import AVFoundation
import CoreGraphics
import Foundation
import ImageIO

enum LivePhotoPairer {
    static func pairedVideoURL(for imageURL: URL) -> URL? {
        guard SupportedImageExtensions.isSupported(imageURL) else { return nil }
        let imageURL = imageURL.resolvingSymlinksInPath()
        let stem = imageURL.deletingPathExtension().lastPathComponent
        let directory = imageURL.deletingLastPathComponent()
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return nil
        }
        let videos = contents.filter {
            let ext = $0.pathExtension.lowercased()
            return ext == "mov" || ext == "mp4"
        }
        let imageIdentifier = contentIdentifier(of: imageURL)
        return match(stem: stem, videos: videos, imageIdentifier: imageIdentifier) { videoURL in
            videoContentIdentifier(videoURL)
        }
    }

    static func isLivePhotoContainer(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        guard ext == "heic" || ext == "heif" else { return false }
        return contentIdentifier(of: url) != nil
    }

    static func match(
        stem: String,
        videos: [URL],
        imageIdentifier: String?,
        videoIdentifierOf: (URL) -> String?
    ) -> URL? {
        if let exact = videos.first(where: {
            $0.deletingPathExtension().lastPathComponent.compare(stem, options: .caseInsensitive) == .orderedSame
        }) {
            return exact
        }
        let hevcStem = stem + "_HEVC"
        if let hevc = videos.first(where: {
            $0.deletingPathExtension().lastPathComponent.compare(hevcStem, options: .caseInsensitive) == .orderedSame
        }) {
            return hevc
        }
        // 编辑版主图（IMG_E5102）回退匹配原始命名视频（IMG_5102.MOV）
        if let baseStem = PhotoNaming.baseStem(of: stem) {
            if let exact = videos.first(where: {
                $0.deletingPathExtension().lastPathComponent.compare(baseStem, options: .caseInsensitive) == .orderedSame
            }) {
                return exact
            }
            let baseHevcStem = baseStem + "_HEVC"
            if let hevc = videos.first(where: {
                $0.deletingPathExtension().lastPathComponent.compare(baseHevcStem, options: .caseInsensitive) == .orderedSame
            }) {
                return hevc
            }
        }
        if let imageIdentifier {
            for video in videos {
                if videoIdentifierOf(video) == imageIdentifier {
                    return video
                }
            }
        }
        return nil
    }

    static func contentIdentifier(of imageURL: URL) -> String? {
        guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil) else { return nil }
        if let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
           let maker = properties[kCGImagePropertyMakerAppleDictionary] as? [String: Any],
           let value = maker["ContentIdentifier"] as? String {
            return value
        }
        guard let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil) else { return nil }
        var found: String?
        CGImageMetadataEnumerateTagsUsingBlock(metadata, nil, nil) { path, tag in
            let pathString = path as String
            if pathString.lowercased().contains("contentidentifier") {
                found = CGImageMetadataTagCopyValue(tag) as? String
                return true
            }
            return false
        }
        return found
    }

    static func videoContentIdentifier(_ videoURL: URL) -> String? {
        let asset = AVAsset(url: videoURL)
        for item in asset.metadata {
            if item.identifier == .quickTimeMetadataContentIdentifier,
               let value = item.stringValue {
                return value
            }
        }
        return nil
    }
}
