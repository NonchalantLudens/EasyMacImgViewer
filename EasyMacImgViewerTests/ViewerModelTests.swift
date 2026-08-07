import CoreGraphics
import ImageIO
import XCTest
@testable import EasyMacImgViewer

@MainActor
final class ViewerModelTests: XCTestCase {
    private func makeTempDir(withNames names: [String], writeRealImages: Bool = false) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("EasyMacImgViewerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for name in names {
            let url = dir.appendingPathComponent(name)
            let ext = url.pathExtension.lowercased()
            if writeRealImages && ext == "png" {
                writeSolidPNG(to: url)
            } else if writeRealImages && ext == "jpg" {
                writeSolidJPEG(to: url)
            } else {
                FileManager.default.createFile(atPath: url.path, contents: Data([0x00]))
            }
        }
        return dir
    }

    private func writeSolidPNG(to url: URL) {
        let context = CGContext(
            data: nil,
            width: 40,
            height: 30,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 40, height: 30))
        let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }

    private func writeSolidJPEG(to url: URL) {
        let context = CGContext(
            data: nil,
            width: 40,
            height: 30,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 40, height: 30))
        let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.jpeg" as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }

    private func removeTempDir(_ dir: URL) {
        try? FileManager.default.removeItem(at: dir)
    }

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "EasyMacImgViewerTests-\(UUID().uuidString)")
    }

    private func makeModel(url: URL) -> ViewerModel {
        ViewerModel(url: url, defaults: defaults)
    }

    func testScansFolderAndFindsCurrentFileIndex() async throws {
        let dir = try makeTempDir(withNames: ["a.png", "b.png", "c.png"])
        defer { removeTempDir(dir) }

        let model = makeModel(url: dir.appendingPathComponent("c.png"))
        await model.load()

        XCTAssertEqual(model.files.map { $0.displayName }, ["a.png", "b.png", "c.png"])
        XCTAssertEqual(model.index, 2)
        XCTAssertEqual(model.currentURL.lastPathComponent, "c.png")
        XCTAssertEqual(model.fileName, "c.png")
    }

    func testNavigationBoundaries() async throws {
        let dir = try makeTempDir(withNames: ["a.png", "b.png", "c.png"])
        defer { removeTempDir(dir) }

        let model = makeModel(url: dir.appendingPathComponent("b.png"))
        await model.load()
        XCTAssertEqual(model.index, 1)
        XCTAssertTrue(model.canGoPrevious)
        XCTAssertTrue(model.canGoNext)

        model.navigate(by: -1)
        XCTAssertEqual(model.index, 0)
        XCTAssertFalse(model.canGoPrevious)
        XCTAssertTrue(model.canGoNext)

        model.navigate(by: -1)
        XCTAssertEqual(model.index, 0)

        model.navigate(by: 1)
        model.navigate(by: 1)
        XCTAssertEqual(model.index, 2)
        XCTAssertFalse(model.canGoNext)

        model.navigate(by: 1)
        XCTAssertEqual(model.index, 2)
    }

    func testLivePhotoDetected() async throws {
        let dir = try makeTempDir(withNames: ["IMG_0001.HEIC", "IMG_0001.MOV", "IMG_0002.HEIC"])
        defer { removeTempDir(dir) }

        let model = makeModel(url: dir.appendingPathComponent("IMG_0001.HEIC"))
        await model.load()

        XCTAssertNotNil(model.livePhoto)
        XCTAssertEqual(model.livePhoto?.videoURL.lastPathComponent, "IMG_0001.MOV")

        model.navigate(by: 1)
        XCTAssertNil(model.livePhoto)
    }

    func testLivePhotoDetectedFromJpgMovPair() async throws {
        let dir = try makeTempDir(withNames: ["IMG_5108.JPG", "IMG_5108.MOV", "IMG_5109.JPG"], writeRealImages: true)
        defer { removeTempDir(dir) }

        let model = makeModel(url: dir.appendingPathComponent("IMG_5108.JPG"))
        await model.load()

        XCTAssertFalse(model.loadFailed)
        XCTAssertNotNil(model.livePhoto)
        XCTAssertEqual(model.livePhoto?.videoURL.lastPathComponent, "IMG_5108.MOV")

        model.navigate(by: 1)
        XCTAssertNil(model.livePhoto)
        XCTAssertFalse(model.isOrphanLivePhoto)
    }

    func testLivePhotoDetectedWithHevcSuffix() async throws {
        let dir = try makeTempDir(withNames: ["IMG_1234.HEIC", "IMG_1234_HEVC.MOV"])
        defer { removeTempDir(dir) }

        let model = makeModel(url: dir.appendingPathComponent("IMG_1234.HEIC"))
        await model.load()

        XCTAssertNotNil(model.livePhoto)
        XCTAssertEqual(model.livePhoto?.videoURL.lastPathComponent, "IMG_1234_HEVC.MOV")
    }

    func testPlainImageIsNotOrphanLivePhoto() async throws {
        let dir = try makeTempDir(withNames: ["a.png"], writeRealImages: true)
        defer { removeTempDir(dir) }

        let model = makeModel(url: dir.appendingPathComponent("a.png"))
        await model.load()

        XCTAssertFalse(model.isOrphanLivePhoto)
        XCTAssertNil(model.livePhoto)
    }

    func testZoomClampsAndPans() async throws {
        let dir = try makeTempDir(withNames: ["a.png"], writeRealImages: true)
        defer { removeTempDir(dir) }

        let model = makeModel(url: dir.appendingPathComponent("a.png"))
        await model.load()
        XCTAssertFalse(model.loadFailed)
        XCTAssertEqual(model.imageSize, CGSize(width: 40, height: 30))

        model.setViewSize(CGSize(width: 100, height: 100))
        model.fit()
        XCTAssertEqual(model.zoomMode, .fit)
        XCTAssertEqual(model.scale, 1)

        model.zoom(by: 5, anchor: CGPoint(x: 50, y: 50))
        XCTAssertEqual(model.zoomMode, .custom(5))
        XCTAssertEqual(model.scale, 5)
        XCTAssertFalse(model.isFullyVisible)

        model.pan = CGSize(width: 9999, height: 9999)
        model.clampPan()
        XCTAssertEqual(model.pan.width, 50)
        XCTAssertEqual(model.pan.height, 25)

        model.pan = CGSize(width: -9999, height: -9999)
        model.clampPan()
        XCTAssertEqual(model.pan.width, -50)
        XCTAssertEqual(model.pan.height, -25)

        model.zoom(by: 1000, anchor: CGPoint(x: 50, y: 50))
        XCTAssertLessThanOrEqual(model.scale, 32)

        model.actual()
        XCTAssertEqual(model.zoomMode, .actual)
        XCTAssertEqual(model.scale, 1)

        model.toggleFitActual()
        XCTAssertEqual(model.zoomMode, .fit)
    }

    // MARK: - 照片文件夹模式

    func testOpensFileInsidePhotoFolderLocatesFolderItem() async throws {
        let dir = try makeTempDir(withNames: [])
        defer { removeTempDir(dir) }
        let photoDir = dir.appendingPathComponent("IMG_5111")
        try FileManager.default.createDirectory(at: photoDir, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: photoDir.appendingPathComponent("IMG_5111.HEIC").path, contents: Data([0x00]))
        FileManager.default.createFile(atPath: photoDir.appendingPathComponent("IMG_5111.MOV").path, contents: Data([0x00]))

        let model = makeModel(url: photoDir.appendingPathComponent("IMG_5111.HEIC"))
        model.folderModeEnabled = true
        await model.load()

        XCTAssertEqual(model.files.count, 1)
        guard case .folder(let name, _) = model.files[0] else {
            return XCTFail("expected folder item")
        }
        XCTAssertEqual(name, "IMG_5111")
        XCTAssertEqual(model.index, 0)
        XCTAssertEqual(model.currentURL.lastPathComponent, "IMG_5111.HEIC")
        XCTAssertEqual(model.fileName, "IMG_5111")
        XCTAssertNotNil(model.livePhoto)
    }

    func testOpensEditedFileInsideFolderUsesEditedPrimary() async throws {
        let dir = try makeTempDir(withNames: [])
        defer { removeTempDir(dir) }
        let photoDir = dir.appendingPathComponent("IMG_5102")
        try FileManager.default.createDirectory(at: photoDir, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: photoDir.appendingPathComponent("IMG_5102.JPG").path, contents: Data([0x00]))
        FileManager.default.createFile(atPath: photoDir.appendingPathComponent("IMG_E5102.jpg").path, contents: Data([0x00]))
        FileManager.default.createFile(atPath: photoDir.appendingPathComponent("IMG_5102.AAE").path, contents: Data([0x00]))

        let model = makeModel(url: photoDir.appendingPathComponent("IMG_5102.JPG"))
        model.folderModeEnabled = true
        await model.load()

        XCTAssertEqual(model.files.count, 1)
        XCTAssertEqual(model.currentURL.lastPathComponent, "IMG_E5102.jpg")
    }

    func testOriginalPreferencePicksOriginalPrimary() async throws {
        let dir = try makeTempDir(withNames: [])
        defer { removeTempDir(dir) }
        let photoDir = dir.appendingPathComponent("IMG_5102")
        try FileManager.default.createDirectory(at: photoDir, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: photoDir.appendingPathComponent("IMG_5102.JPG").path, contents: Data([0x00]))
        FileManager.default.createFile(atPath: photoDir.appendingPathComponent("IMG_E5102.jpg").path, contents: Data([0x00]))

        let model = makeModel(url: photoDir.appendingPathComponent("IMG_E5102.jpg"))
        model.folderModeEnabled = true
        model.primaryPreference = .original
        await model.load()

        XCTAssertEqual(model.currentURL.lastPathComponent, "IMG_5102.JPG")
    }

    func testPreferenceSwitchReloadsPreservingSelection() async throws {
        let dir = try makeTempDir(withNames: [])
        defer { removeTempDir(dir) }
        let photoDir = dir.appendingPathComponent("IMG_5102")
        try FileManager.default.createDirectory(at: photoDir, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: photoDir.appendingPathComponent("IMG_5102.JPG").path, contents: Data([0x00]))
        FileManager.default.createFile(atPath: photoDir.appendingPathComponent("IMG_E5102.jpg").path, contents: Data([0x00]))

        let model = makeModel(url: photoDir.appendingPathComponent("IMG_5102.JPG"))
        model.folderModeEnabled = true
        await model.load()
        XCTAssertEqual(model.currentURL.lastPathComponent, "IMG_E5102.jpg")

        model.primaryPreference = .original
        await waitForReload(of: model)
        XCTAssertEqual(model.currentURL.lastPathComponent, "IMG_5102.JPG")
        XCTAssertEqual(model.fileName, "IMG_5102")

        model.primaryPreference = .edited
        await waitForReload(of: model)
        XCTAssertEqual(model.currentURL.lastPathComponent, "IMG_E5102.jpg")
    }

    private func waitForReload(of model: ViewerModel) async {
        var attempts = 0
        while model.isLoading, attempts < 200 {
            try? await Task.sleep(for: .milliseconds(10))
            attempts += 1
        }
    }
}
