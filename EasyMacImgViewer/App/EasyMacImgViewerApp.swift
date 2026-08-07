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

enum AppLanguage: String, CaseIterable {
    case system
    case zhHans = "zh-Hans"
    case en = "en"

    var locale: Locale {
        switch self {
        case .system: return Locale.current
        case .zhHans: return Locale(identifier: "zh-Hans")
        case .en: return Locale(identifier: "en")
        }
    }
}

struct ViewerCommands: Commands {
    @FocusedValue(\.viewerModel) private var viewerModel
    @AppStorage("appLanguage") private var languageRaw = AppLanguage.system.rawValue

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("打开…") { OpenRequest.showPanel() }
                .keyboardShortcut("o")
        }
        CommandGroup(after: .sidebar) {
            Button("适合窗口") { viewerModel?.fit() }
                .keyboardShortcut("0")
            Button("实际大小") { viewerModel?.actual() }
                .keyboardShortcut("1")
            Divider()
            Button("放大") { viewerModel?.zoomIn() }
                .keyboardShortcut("+")
            Button("缩小") { viewerModel?.zoomOut() }
                .keyboardShortcut("-")
            Divider()
            if let model = viewerModel {
                Toggle("将照片文件夹识别为图像（iPhone 所有数据）", isOn: Binding(
                    get: { model.folderModeEnabled },
                    set: { model.folderModeEnabled = $0 }
                ))
                Toggle("照片文件夹优先显示编辑版本", isOn: Binding(
                    get: { model.primaryPreference == .edited },
                    set: { model.primaryPreference = $0 ? .edited : .original }
                ))
            }
            Divider()
            Picker("界面语言", selection: $languageRaw) {
                Text("跟随系统").tag(AppLanguage.system.rawValue)
                Text("中文").tag(AppLanguage.zhHans.rawValue)
                Text("English").tag(AppLanguage.en.rawValue)
            }
        }
    }
}

@main
struct EasyMacImgViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("appLanguage") private var languageRaw = AppLanguage.system.rawValue

    var body: some Scene {
        WindowGroup(for: ViewerTarget.self) { target in
            WindowRootView(target: target.wrappedValue)
        } defaultValue: {
            .welcome
        }
        .defaultSize(width: 1080, height: 720)
        .windowToolbarStyle(.unified)
        .environment(\.locale, (AppLanguage(rawValue: languageRaw) ?? .system).locale)
        .commands {
            ViewerCommands()
        }
    }
}
