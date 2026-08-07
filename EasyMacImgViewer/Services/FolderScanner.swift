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

enum ViewerItem: Hashable {
    case file(URL)
    case folder(name: String, imageURL: URL)

    var displayName: String {
        switch self {
        case .file(let url): return url.lastPathComponent
        case .folder(let name, _): return name
        }
    }

    var imageURL: URL {
        switch self {
        case .file(let url): return url
        case .folder(_, let imageURL): return imageURL
        }
    }
}

enum PrimaryImagePreference: String {
    case edited
    case original
}

enum PhotoNaming {
    /// 剥离编辑版前缀："IMG_E5102" -> "IMG_5102"；非编辑版返回 nil
    static func baseStem(of stem: String) -> String? {
        guard stem.count > 4, stem.lowercased().hasPrefix("img_e") else { return nil }
        return String(stem.prefix(4) + stem.dropFirst(5))
    }

    static func isEditedStem(_ stem: String) -> Bool {
        stem.count > 4 && stem.lowercased().hasPrefix("img_e")
    }
}

enum FolderScanner {
    static func scan(directory: URL, folderMode: Bool, primaryPreference: PrimaryImagePreference) async -> [ViewerItem] {
        await Task.detached(priority: .userInitiated) {
            let directory = directory.resolvingSymlinksInPath()
            let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .isHiddenKey]
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            ) else {
                return []
            }
            var items: [ViewerItem] = []
            for url in contents {
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
                if values?.isRegularFile == true {
                    if SupportedImageExtensions.isSupported(url) {
                        items.append(.file(url))
                    }
                } else if folderMode, values?.isDirectory == true,
                          let primary = primaryImageURL(in: url, preference: primaryPreference) {
                    items.append(.folder(name: url.lastPathComponent, imageURL: primary))
                }
            }
            items.sort {
                $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
            }
            return items
        }.value
    }

    /// 判定目录是否为"照片文件夹"（iPhone 所有数据模式），并返回主图 URL
    static func primaryImageURL(in directory: URL, preference: PrimaryImagePreference) -> URL? {
        guard let subs = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        let files = subs.filter {
            (try? $0.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true
        }
        let images = files.filter { SupportedImageExtensions.isSupported($0) }
        guard !images.isEmpty else { return nil }

        let name = directory.lastPathComponent
        if !isPhotoLikeName(name) {
            let stems = Set(images.map { baseStem(of: $0.lastPathComponent) })
            guard stems.count == 1, files.count <= 4 else { return nil }
        }

        let sorted = images.sorted {
            $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
        }
        switch preference {
        case .edited:
            return sorted.first { PhotoNaming.isEditedStem(stem(of: $0)) } ?? sorted.first
        case .original:
            return sorted.first { !PhotoNaming.isEditedStem(stem(of: $0)) } ?? sorted.first
        }
    }

    static func isPhotoFolder(_ directory: URL) -> Bool {
        guard let subs = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return false
        }
        let hasSubdirectory = subs.contains {
            (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
        }
        guard !hasSubdirectory else { return false }
        return primaryImageURL(in: directory, preference: .edited) != nil
    }

    static func isPhotoLikeName(_ name: String) -> Bool {
        if name.range(of: "^IMG_[A-Za-z0-9_]+$", options: .regularExpression) != nil { return true }
        if name.lowercased().hasSuffix("_livephoto") { return true }
        return false
    }

    static func baseStem(of filename: String) -> String {
        let stem = stem(of: URL(fileURLWithPath: filename))
        return PhotoNaming.baseStem(of: stem) ?? stem
    }

    private static func stem(of url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }
}
