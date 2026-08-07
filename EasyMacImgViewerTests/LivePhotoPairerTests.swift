import XCTest
@testable import EasyMacImgViewer

final class LivePhotoPairerTests: XCTestCase {
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

    func testFindsPairedVideoWithDifferentCase() throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        makeFiles(dir, ["IMG_1234.HEIC", "IMG_1234.MOV"])

        let paired = LivePhotoPairer.pairedVideoURL(for: dir.appendingPathComponent("IMG_1234.HEIC"))
        XCTAssertEqual(paired?.lastPathComponent, "IMG_1234.MOV")
    }

    func testJpgWithPairedMovPairs() throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        makeFiles(dir, ["IMG_5108.JPG", "IMG_5108.MOV"])

        let paired = LivePhotoPairer.pairedVideoURL(for: dir.appendingPathComponent("IMG_5108.JPG"))
        XCTAssertEqual(paired?.lastPathComponent, "IMG_5108.MOV")
    }

    func testPngWithPairedMovPairs() throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        makeFiles(dir, ["IMG_0001.png", "IMG_0001.mov"])

        XCTAssertEqual(LivePhotoPairer.pairedVideoURL(for: dir.appendingPathComponent("IMG_0001.png"))?.lastPathComponent, "IMG_0001.mov")
    }

    func testHevcSuffixPatternPairs() throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        makeFiles(dir, ["IMG_1234.HEIC", "IMG_1234_HEVC.MOV"])

        let paired = LivePhotoPairer.pairedVideoURL(for: dir.appendingPathComponent("IMG_1234.HEIC"))
        XCTAssertEqual(paired?.lastPathComponent, "IMG_1234_HEVC.MOV")
    }

    func testHevcSuffixPatternCaseInsensitive() throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        makeFiles(dir, ["IMG_1234.heic", "IMG_1234_hevc.mov"])

        let paired = LivePhotoPairer.pairedVideoURL(for: dir.appendingPathComponent("IMG_1234.heic"))
        XCTAssertEqual(paired?.lastPathComponent, "IMG_1234_hevc.mov")
    }

    func testNoPairedVideoReturnsNil() throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        makeFiles(dir, ["IMG_0001.HEIC"])

        XCTAssertNil(LivePhotoPairer.pairedVideoURL(for: dir.appendingPathComponent("IMG_0001.HEIC")))
    }

    func testDifferentStemDoesNotPair() throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        makeFiles(dir, ["IMG_0001.HEIC", "IMG_0002.MOV"])

        XCTAssertNil(LivePhotoPairer.pairedVideoURL(for: dir.appendingPathComponent("IMG_0001.HEIC")))
    }

    func testNonHevcSuffixDoesNotPair() throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        makeFiles(dir, ["IMG_0001.HEIC", "IMG_0001_2.MOV", "IMG_0001_final.MOV"])

        XCTAssertNil(LivePhotoPairer.pairedVideoURL(for: dir.appendingPathComponent("IMG_0001.HEIC")))
    }

    func testNonImageFileReturnsNil() {
        let url = URL(fileURLWithPath: "/tmp/photo.mov")
        XCTAssertNil(LivePhotoPairer.pairedVideoURL(for: url))
    }

    func testEditedVersionPairsWithOriginalVideo() throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        makeFiles(dir, ["IMG_E5102.jpg", "IMG_5102.MOV"])

        let paired = LivePhotoPairer.pairedVideoURL(for: dir.appendingPathComponent("IMG_E5102.jpg"))
        XCTAssertEqual(paired?.lastPathComponent, "IMG_5102.MOV")
    }

    func testEditedVersionHevcSuffixPairsWithOriginalVideo() throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        makeFiles(dir, ["IMG_E5102.HEIC", "IMG_5102_HEVC.MOV"])

        let paired = LivePhotoPairer.pairedVideoURL(for: dir.appendingPathComponent("IMG_E5102.HEIC"))
        XCTAssertEqual(paired?.lastPathComponent, "IMG_5102_HEVC.MOV")
    }

    func testMatchPreferenceOrder() {
        let videos = [
            URL(fileURLWithPath: "/tmp/IMG_1234_HEVC.MOV"),
            URL(fileURLWithPath: "/tmp/IMG_1234.MOV"),
            URL(fileURLWithPath: "/tmp/IMG_1234_2.MOV"),
        ]
        let matched = LivePhotoPairer.match(stem: "IMG_1234", videos: videos, imageIdentifier: nil) { _ in nil }
        XCTAssertEqual(matched?.lastPathComponent, "IMG_1234.MOV")
    }

    func testMatchFallsBackToHevcPattern() {
        let videos = [
            URL(fileURLWithPath: "/tmp/IMG_1234_HEVC.MOV"),
            URL(fileURLWithPath: "/tmp/IMG_1234_2.MOV"),
        ]
        let matched = LivePhotoPairer.match(stem: "IMG_1234", videos: videos, imageIdentifier: nil) { _ in nil }
        XCTAssertEqual(matched?.lastPathComponent, "IMG_1234_HEVC.MOV")
    }

    func testMatchFallsBackToContentIdentifier() {
        let video = URL(fileURLWithPath: "/tmp/renamed-video.MOV")
        let videos = [video]
        let matched = LivePhotoPairer.match(
            stem: "IMG_1234",
            videos: videos,
            imageIdentifier: "680453CB-AFB4-42B0-919A-F7020404BE29"
        ) { url in
            url == video ? "680453CB-AFB4-42B0-919A-F7020404BE29" : nil
        }
        XCTAssertEqual(matched, video)
    }

    func testMatchIdentifierMismatchReturnsNil() {
        let videos = [URL(fileURLWithPath: "/tmp/renamed-video.MOV")]
        let matched = LivePhotoPairer.match(
            stem: "IMG_1234",
            videos: videos,
            imageIdentifier: "AAAA-BBBB"
        ) { _ in "CCCC-DDDD" }
        XCTAssertNil(matched)
    }

    func testMatchNoCandidatesReturnsNil() {
        XCTAssertNil(LivePhotoPairer.match(stem: "IMG_1234", videos: [], imageIdentifier: "x") { _ in "x" })
    }

    func testNonLiveContainerReportsFalse() throws {
        let dir = try makeTempDir()
        defer { removeTempDir(dir) }
        makeFiles(dir, ["IMG_0001.png"])
        XCTAssertFalse(LivePhotoPairer.isLivePhotoContainer(dir.appendingPathComponent("IMG_0001.png")))
    }

    func testPngIsNotLivePhotoContainer() {
        let url = URL(fileURLWithPath: "/tmp/photo.png")
        XCTAssertFalse(LivePhotoPairer.isLivePhotoContainer(url))
    }
}
