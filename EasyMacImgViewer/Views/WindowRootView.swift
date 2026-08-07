import SwiftUI

struct WindowRootView: View {
    let target: ViewerTarget
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    @State private var model: ViewerModel?

    init(target: ViewerTarget) {
        self.target = target
        _model = State(initialValue: target.url.map { ViewerModel(url: $0) })
    }

    var body: some View {
        Group {
            if let model {
                ViewerView(model: model)
            } else {
                WelcomeView()
            }
        }
        .frame(minWidth: 640, minHeight: 480)
        .onReceive(NotificationCenter.default.publisher(for: OpenRequest.name)) { note in
            handle(urls: (note.object as? [URL]) ?? [])
        }
        .task {
            if let urls = AppDelegate.shared?.takePendingURLs() {
                handle(urls: urls)
            }
        }
    }

    private func handle(urls: [URL]) {
        if urls.isEmpty {
            openWindow(value: ViewerTarget.welcome)
            return
        }
        for url in urls {
            openWindow(value: ViewerTarget.file(url))
        }
        if target.url == nil {
            dismiss()
        }
    }
}
