import SwiftUI

struct ViewerToolbar: ToolbarContent {
    let model: ViewerModel
    @Binding var showSidebar: Bool

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button {
                showSidebar.toggle()
            } label: {
                Label("侧边栏", systemImage: "sidebar.left")
            }
            .keyboardShortcut("s", modifiers: [.command, .option])
            .help("显示/隐藏侧边栏 (⌘⌥S)")

            Button {
                OpenRequest.showPanel()
            } label: {
                Label("打开", systemImage: "folder")
            }
            .help("打开图像 (⌘O)")

            Button {
                model.navigate(by: -1)
            } label: {
                Label("上一张", systemImage: "chevron.left")
            }
            .disabled(!model.canGoPrevious)
            .help("上一张 (←)")

            Button {
                model.navigate(by: 1)
            } label: {
                Label("下一张", systemImage: "chevron.right")
            }
            .disabled(!model.canGoNext)
            .help("下一张 (→)")
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                model.zoomOut()
            } label: {
                Label("缩小", systemImage: "minus.magnifyingglass")
            }
            .help("缩小")

            Text("\(model.scalePercent)%")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 44)

            Button {
                model.zoomIn()
            } label: {
                Label("放大", systemImage: "plus.magnifyingglass")
            }
            .help("放大")

            Button {
                model.fit()
            } label: {
                Label("适合窗口", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .help("适合窗口 (⌘0)")

            Button {
                model.actual()
            } label: {
                Label("实际大小", systemImage: "1.magnifyingglass")
            }
            .help("实际大小 (⌘1)")

            if model.livePhoto != nil {
                Button {
                    model.livePhoto?.toggle()
                } label: {
                    Label(
                        model.livePhoto?.isPlaying == true ? "暂停" : "播放 Live Photo",
                        systemImage: model.livePhoto?.isPlaying == true ? "livephoto" : "livephoto.play"
                    )
                }
                .help("播放 / 暂停 Live Photo")
            }

            if model.isAnimated {
                Button {
                    model.animator?.toggle()
                } label: {
                    Label(
                        model.animator?.isPlaying == true ? "暂停" : "播放",
                        systemImage: model.animator?.isPlaying == true ? "pause.fill" : "play.fill"
                    )
                }
                .help("播放 / 暂停动画")
            }
        }
    }
}
