import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    nonisolated(unsafe) private(set) static var shared: AppDelegate?
    private var pendingURLs: [URL]?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        pendingURLs = urls
        DispatchQueue.main.async {
            OpenRequest.post(urls: urls)
        }
    }

    func takePendingURLs() -> [URL]? {
        let urls = pendingURLs
        pendingURLs = nil
        return urls
    }
}
