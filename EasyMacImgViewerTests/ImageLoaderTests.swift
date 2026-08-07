import CoreGraphics
import ImageIO
import XCTest
@testable import EasyMacImgViewer

final class ImageLoaderTests: XCTestCase {
    private func makeTempFile(_ name: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("EasyMacImgViewerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(name)
    }

    private func solidImage(width: Int, height: Int) -> CGImage {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    private func write(_ image: CGImage, to url: URL, uti: String, orientation: UInt32? = nil) {
        let destination = CGImageDestinationCreateWithURL(url as CFURL, uti as CFString, 1, nil)!
        var props: [CFString: Any] = [:]
        if let orientation {
            props[kCGImagePropertyOrientation] = orientation
        }
        if props.isEmpty {
            CGImageDestinationAddImage(destination, image, nil)
        } else {
            CGImageDestinationAddImage(destination, image, props as CFDictionary)
        }
        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }

    func testDecodesPNG() async throws {
        let url = try makeTempFile("test.png")
        defer { try? FileManager.default.removeItem(at: url) }
        write(solidImage(width: 40, height: 30), to: url, uti: "public.png")

        let result = await ImageLoader.decode(from: url)
        guard case .still(let image) = result else {
            return XCTFail("expected still image, got \(result)")
        }
        XCTAssertEqual(image.width, 40)
        XCTAssertEqual(image.height, 30)
    }

    func testOrientationRightApplied() async throws {
        let url = try makeTempFile("rotated.jpg")
        defer { try? FileManager.default.removeItem(at: url) }
        write(solidImage(width: 20, height: 10), to: url, uti: "public.jpeg", orientation: 6)

        let result = await ImageLoader.decode(from: url)
        guard case .still(let image) = result else {
            return XCTFail("expected still image, got \(result)")
        }
        XCTAssertEqual(image.width, 10)
        XCTAssertEqual(image.height, 20)
    }

    func testOrientationDownApplied() async throws {
        let url = try makeTempFile("rotated-down.jpg")
        defer { try? FileManager.default.removeItem(at: url) }
        write(solidImage(width: 20, height: 10), to: url, uti: "public.jpeg", orientation: 3)

        let result = await ImageLoader.decode(from: url)
        guard case .still(let image) = result else {
            return XCTFail("expected still image, got \(result)")
        }
        XCTAssertEqual(image.width, 20)
        XCTAssertEqual(image.height, 10)
    }

    func testOrientationLeftApplied() async throws {
        let url = try makeTempFile("rotated-left.jpg")
        defer { try? FileManager.default.removeItem(at: url) }
        write(solidImage(width: 20, height: 10), to: url, uti: "public.jpeg", orientation: 8)

        let result = await ImageLoader.decode(from: url)
        guard case .still(let image) = result else {
            return XCTFail("expected still image, got \(result)")
        }
        XCTAssertEqual(image.width, 10)
        XCTAssertEqual(image.height, 20)
    }

    func testCorruptFileFails() async throws {
        let url = try makeTempFile("broken.jpg")
        defer { try? FileManager.default.removeItem(at: url) }
        FileManager.default.createFile(atPath: url.path, contents: Data([0x00, 0x01, 0x02, 0x03]))

        let result = await ImageLoader.decode(from: url)
        if case .failed = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("expected failure, got \(result)")
        }
    }
}
