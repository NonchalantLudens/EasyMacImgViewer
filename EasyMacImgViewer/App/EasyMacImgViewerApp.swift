import SwiftUI

struct ViewerTarget: Hashable, Codable {
    let url: URL?

    static let welcome = ViewerTarget(url: nil)

    static func file(_ url: URL) -> ViewerTarget {
        ViewerTarget(url: url)
    }
}

struct ViewerModelKey: FocusedValueKey {
    typealias Value = ViewerModel
}

extension FocusedValues {
    var viewerModel: ViewerModel? {
        get { self[ViewerModelKey.self] }
        set { self[ViewerModelKey.self] = newValue }
    }
}

struct ViewerCommands: Commands {
    @FocusedValue(\.viewerModel) private var viewerModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("打开…") { OpenRequest.showPanel() }
                .keyboardShortcut("o")
        }
        CommandMenu("显示") {
            Button("适合窗口") { viewerModel?.fit() }
                .keyboardShortcut("0")
            Button("实际大小") { viewerModel?.actual() }
                .keyboardShortcut("1")
            Divider()
            Button("放大") { viewerModel?.zoomIn() }
                .keyboardShortcut("+")
            Button("缩小") { viewerModel?.zoomOut() }
                .keyboardShortcut("-")
        }
    }
}

@main
struct EasyMacImgViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup(for: ViewerTarget.self) { target in
            WindowRootView(target: target.wrappedValue)
        } defaultValue: {
            .welcome
        }
        .defaultSize(width: 1080, height: 720)
        .windowToolbarStyle(.unified)
        .commands {
            ViewerCommands()
        }
    }
}
