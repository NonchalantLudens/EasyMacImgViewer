import Foundation

enum SupportedImageExtensions {
    static let set: Set<String> = [
        "jpg", "jpeg", "jfif", "jpe",
        "png",
        "gif",
        "tiff", "tif",
        "bmp",
        "webp",
        "heic", "heif",
        "jxl",
        "svg",
        "icns",
        "j2k", "jp2",
        "cr2", "crw",
        "nef", "nrw",
        "arw", "sr2",
        "dng",
        "raf",
        "orf",
        "rw2",
        "pef",
        "srw",
        "3fr",
        "raw",
    ]

    static func isSupported(_ url: URL) -> Bool {
        set.contains(url.pathExtension.lowercased())
    }
}

enum FolderScanner {
    static func scan(directory: URL) async -> [URL] {
        await Task.detached(priority: .userInitiated) {
            let directory = directory.resolvingSymlinksInPath()
            let keys: [URLResourceKey] = [.isRegularFileKey, .isHiddenKey]
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            ) else {
                return []
            }
            var urls = contents.filter { url in
                guard SupportedImageExtensions.isSupported(url) else { return false }
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
                return values?.isRegularFile == true
            }
            urls.sort {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }
            return urls
        }.value
    }
}
