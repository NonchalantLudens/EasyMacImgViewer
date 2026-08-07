import XCTest
@testable import EasyMacImgViewer

final class FolderScannerTests: XCTestCase {
    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("EasyMacImgViewerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func removeTempDir(_ dir: URL) {
        try? FileManager.default.removeItem(at: dir)
    }

    private func makeFiles(_ dir: URL, _ names: [String]) {
        for name in names {
            FileManager.default.createFile(atPath: dir.appendingPathComponent(name).path, contents: Data([0x00]))
        }
    }

    private func makeSubdirs(_ dir: URL, _ names: [String]) throws -> [URL] {
        try names.map {
            let url = dir.appendingPathComponent($0)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        }
    }

    func testScanFiltersAndSortsNaturally() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }

        for name in ["b.png", "a.jpg", "IMG_10.HEIC", "img_2.png", "notes.txt", "photo.MOV", "anim.gif", "photo.jpeg", "x.HEIC", ".DS_Store"] {
            FileManager.default.createFile(atPath: dir.appendingPathComponent(name).path, contents: Data([0x00]))
        }

        let files = await FolderScanner.scan(directory: dir, folderMode: false, primaryPreference: .edited)
        let names = files.map { $0.displayName }

        XCTAssertEqual(names, ["a.jpg", "anim.gif", "b.png", "img_2.png", "IMG_10.HEIC", "photo.jpeg", "x.HEIC"])
    }

    func testScanSkipsDirectoriesInFileMode() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }

        let subDir = dir.appendingPathComponent("img.png")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: dir.appendingPathComponent("real.png").path, contents: Data([0x00]))

        let files = await FolderScanner.scan(directory: dir, folderMode: false, primaryPreference: .edited)
        XCTAssertEqual(files.map { $0.displayName }, ["real.png"])
    }

    func testExtensionMatchingIsCaseInsensitive() {
        for ext in ["JPG", "Png", "HeIc", "TIF", "WebP", "DNG", "CR2", "NEF", "SVG"] {
            let url = URL(fileURLWithPath: "/tmp/photo.\(ext)")
            XCTAssertTrue(SupportedImageExtensions.isSupported(url), "expected \(ext) to be supported")
        }
    }

    func testNonImageExtensionsRejected() {
        for ext in ["mov", "mp4", "txt", "pdf", "docx", "zip", ""] {
            let url = URL(fileURLWithPath: "/tmp/photo.\(ext)")
            XCTAssertFalse(SupportedImageExtensions.isSupported(url), "expected \(ext) to be rejected")
        }
    }

    // MARK: - 照片文件夹识别

    func testFolderModeRecognizesPhotoNameDirectory() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        try makeSubdirs(dir, ["IMG_5111"])
        makeFiles(dir.appendingPathComponent("IMG_5111"), ["IMG_5111.HEIC", "IMG_5111.MOV"])

        let files = await FolderScanner.scan(directory: dir, folderMode: true, primaryPreference: .edited)
        XCTAssertEqual(files.count, 1)
        guard case .folder(let name, let imageURL) = files[0] else {
            return XCTFail("expected folder item")
        }
        XCTAssertEqual(name, "IMG_5111")
        XCTAssertEqual(imageURL.lastPathComponent, "IMG_5111.HEIC")
    }

    func testFolderModeRecognizesLivephotoSuffixDirectory() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        try makeSubdirs(dir, ["854d49e063bbfac470ba320c8707c5_livephoto"])
        makeFiles(dir.appendingPathComponent("854d49e063bbfac470ba320c8707c5_livephoto"), ["IMG_5046.HEIC", "IMG_5046.MOV"])

        let files = await FolderScanner.scan(directory: dir, folderMode: true, primaryPreference: .edited)
        XCTAssertEqual(files.count, 1)
        guard case .folder = files[0] else { return XCTFail("expected folder item") }
    }

    func testFolderModeRecognizesSingleImageDirectory() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        try makeSubdirs(dir, ["2c876bc4c882bc29dd09f1da3c4fe7bf"])
        makeFiles(dir.appendingPathComponent("2c876bc4c882bc29dd09f1da3c4fe7bf"), ["IMG_5108.JPG", "IMG_5108.MOV"])

        let files = await FolderScanner.scan(directory: dir, folderMode: true, primaryPreference: .edited)
        XCTAssertEqual(files.count, 1)
        guard case .folder = files[0] else { return XCTFail("expected folder item") }
    }

    func testFolderModeIgnoresNormalDirectoryWithMultipleImages() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        try makeSubdirs(dir, ["Kimi_Agent_科研实验方案"])
        makeFiles(dir.appendingPathComponent("Kimi_Agent_科研实验方案"), ["experiment_results.png", "test_images.png", "notes.txt"])

        let files = await FolderScanner.scan(directory: dir, folderMode: true, primaryPreference: .edited)
        XCTAssertTrue(files.isEmpty)
    }

    func testFolderModeIgnoresEmptyAndVideoOnlyDirectories() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        try makeSubdirs(dir, ["empty_dir", "video_only"])
        makeFiles(dir.appendingPathComponent("video_only"), ["clip.mov"])

        let files = await FolderScanner.scan(directory: dir, folderMode: true, primaryPreference: .edited)
        XCTAssertTrue(files.isEmpty)
    }

    func testEditedImageFolderPicksEditedPrimary() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        try makeSubdirs(dir, ["IMG_5102"])
        makeFiles(dir.appendingPathComponent("IMG_5102"), ["IMG_5102.JPG", "IMG_E5102.jpg", "IMG_5102.AAE"])

        let files = await FolderScanner.scan(directory: dir, folderMode: true, primaryPreference: .edited)
        XCTAssertEqual(files.count, 1)
        guard case .folder(_, let imageURL) = files[0] else { return XCTFail("expected folder item") }
        XCTAssertEqual(imageURL.lastPathComponent, "IMG_E5102.jpg")
    }

    func testEditedImageFolderPicksOriginalPrimaryWhenPreferred() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        try makeSubdirs(dir, ["IMG_5102"])
        makeFiles(dir.appendingPathComponent("IMG_5102"), ["IMG_5102.JPG", "IMG_E5102.jpg", "IMG_5102.AAE"])

        let files = await FolderScanner.scan(directory: dir, folderMode: true, primaryPreference: .original)
        XCTAssertEqual(files.count, 1)
        guard case .folder(_, let imageURL) = files[0] else { return XCTFail("expected folder item") }
        XCTAssertEqual(imageURL.lastPathComponent, "IMG_5102.JPG")
    }

    func testRenamedEditedFolderStillRecognizedByStemMerge() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        try makeSubdirs(dir, ["旅行照片"])
        makeFiles(dir.appendingPathComponent("旅行照片"), ["IMG_5102.JPG", "IMG_E5102.jpg", "IMG_5102.AAE"])

        let files = await FolderScanner.scan(directory: dir, folderMode: true, primaryPreference: .edited)
        XCTAssertEqual(files.count, 1)
        guard case .folder(let name, let imageURL) = files[0] else { return XCTFail("expected folder item") }
        XCTAssertEqual(name, "旅行照片")
        XCTAssertEqual(imageURL.lastPathComponent, "IMG_E5102.jpg")
    }

    func testTwoDifferentPhotosDirectoryIgnored() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        try makeSubdirs(dir, ["mixed"])
        makeFiles(dir.appendingPathComponent("mixed"), ["IMG_1001.HEIC", "IMG_1002.HEIC"])

        let files = await FolderScanner.scan(directory: dir, folderMode: true, primaryPreference: .edited)
        XCTAssertTrue(files.isEmpty)
    }

    func testMixedFileAndFolderItemsSortTogether() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        try makeSubdirs(dir, ["IMG_5100"])
        makeFiles(dir, ["IMG_5099.JPG"])
        makeFiles(dir.appendingPathComponent("IMG_5100"), ["IMG_5100.JPG"])
        makeFiles(dir, ["IMG_5101.JPG"])

        let files = await FolderScanner.scan(directory: dir, folderMode: true, primaryPreference: .edited)
        let names = files.map { $0.displayName }
        XCTAssertEqual(names, ["IMG_5099.JPG", "IMG_5100", "IMG_5101.JPG"])
        guard case .folder = files[1] else { return XCTFail("expected folder item at index 1") }
    }

    func testFileModeIgnoresPhotoFolders() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        try makeSubdirs(dir, ["IMG_5111"])
        makeFiles(dir.appendingPathComponent("IMG_5111"), ["IMG_5111.HEIC"])

        let files = await FolderScanner.scan(directory: dir, folderMode: false, primaryPreference: .edited)
        XCTAssertTrue(files.isEmpty)
    }
}
