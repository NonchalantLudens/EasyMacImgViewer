import SwiftUI

struct ErrorPlaceholder: View {
    let name: String

    var body: some View {
        ContentUnavailableView {
            Label("无法打开图像", systemImage: "exclamationmark.triangle")
        } description: {
            Text(name)
        }
    }
}
