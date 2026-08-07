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

    func testScansFolderAndFindsCurrentFileIndex() async throws {
        let dir = try makeTempDir(withNames: ["a.png", "b.png", "c.png"])
        defer { removeTempDir(dir) }

        let model = ViewerModel(url: dir.appendingPathComponent("c.png"))
        await model.load()

        XCTAssertEqual(model.files.map { $0.lastPathComponent }, ["a.png", "b.png", "c.png"])
        XCTAssertEqual(model.index, 2)
        XCTAssertEqual(model.currentURL.lastPathComponent, "c.png")
    }

    func testNavigationBoundaries() async throws {
        let dir = try makeTempDir(withNames: ["a.png", "b.png", "c.png"])
        defer { removeTempDir(dir) }

        let model = ViewerModel(url: dir.appendingPathComponent("b.png"))
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

        let model = ViewerModel(url: dir.appendingPathComponent("IMG_0001.HEIC"))
        await model.load()

        XCTAssertNotNil(model.livePhoto)
        XCTAssertEqual(model.livePhoto?.videoURL.lastPathComponent, "IMG_0001.MOV")

        model.navigate(by: 1)
        XCTAssertNil(model.livePhoto)
    }

    func testLivePhotoDetectedFromJpgMovPair() async throws {
        let dir = try makeTempDir(withNames: ["IMG_5108.JPG", "IMG_5108.MOV", "IMG_5109.JPG"], writeRealImages: true)
        defer { removeTempDir(dir) }

        let model = ViewerModel(url: dir.appendingPathComponent("IMG_5108.JPG"))
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

        let model = ViewerModel(url: dir.appendingPathComponent("IMG_1234.HEIC"))
        await model.load()

        XCTAssertNotNil(model.livePhoto)
        XCTAssertEqual(model.livePhoto?.videoURL.lastPathComponent, "IMG_1234_HEVC.MOV")
    }

    func testPlainImageIsNotOrphanLivePhoto() async throws {
        let dir = try makeTempDir(withNames: ["a.png"], writeRealImages: true)
        defer { removeTempDir(dir) }

        let model = ViewerModel(url: dir.appendingPathComponent("a.png"))
        await model.load()

        XCTAssertFalse(model.isOrphanLivePhoto)
        XCTAssertNil(model.livePhoto)
    }

    func testZoomClampsAndPans() async throws {
        let dir = try makeTempDir(withNames: ["a.png"], writeRealImages: true)
        defer { removeTempDir(dir) }

        let model = ViewerModel(url: dir.appendingPathComponent("a.png"))
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
}
