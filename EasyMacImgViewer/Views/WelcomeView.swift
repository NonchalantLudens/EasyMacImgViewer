import SwiftUI

struct WelcomeView: View {
    var body: some View {
        ContentUnavailableView {
            Label("EasyMacImgViewer", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("打开图片开始浏览")
        } actions: {
            Button("打开…") { OpenRequest.showPanel() }
                .keyboardShortcut("o")
        }
        .frame(minWidth: 560, minHeight: 400)
    }
}
