import AppKit
import Foundation
import UniformTypeIdentifiers

enum OpenRequest {
    static let name = Notification.Name("EasyMacImgViewer.openURLs")

    static func post(urls: [URL]) {
        NotificationCenter.default.post(name: name, object: urls)
    }

    @MainActor
    static func showPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.image, .rawImage]
        if panel.runModal() == .OK {
            post(urls: panel.urls)
        }
    }
}
