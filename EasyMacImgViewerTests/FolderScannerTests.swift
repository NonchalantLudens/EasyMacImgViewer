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

    func testScanFiltersAndSortsNaturally() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }

        for name in ["b.png", "a.jpg", "IMG_10.HEIC", "img_2.png", "notes.txt", "photo.MOV", "anim.gif", "photo.jpeg", "x.HEIC", ".DS_Store"] {
            FileManager.default.createFile(atPath: dir.appendingPathComponent(name).path, contents: Data([0x00]))
        }

        let files = await FolderScanner.scan(directory: dir)
        let names = files.map { $0.lastPathComponent }

        XCTAssertEqual(names, ["a.jpg", "anim.gif", "b.png", "img_2.png", "IMG_10.HEIC", "photo.jpeg", "x.HEIC"])
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

    func testScanSkipsDirectories() async throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }

        let subDir = dir.appendingPathComponent("img.png")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: dir.appendingPathComponent("real.png").path, contents: Data([0x00]))

        let files = await FolderScanner.scan(directory: dir)
        XCTAssertEqual(files.map { $0.lastPathComponent }, ["real.png"])
    }
}
