import SwiftUI

struct ViewerView: View {
    let model: ViewerModel
    @State private var showSidebar = false

    var body: some View {
        HStack(spacing: 0) {
            if showSidebar {
                SidebarView(model: model)
                    .transition(.move(edge: .leading))
            }
            canvas
        }
        .animation(.easeInOut(duration: 0.2), value: showSidebar)
        .focusedSceneValue(\.viewerModel, model)
        .toolbar { ViewerToolbar(model: model, showSidebar: $showSidebar) }
        .navigationTitle(model.fileName)
        .task { await model.load() }
    }

    private var canvas: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ImageCanvasView(model: model)
            if model.isLoading {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
            }
            if model.loadFailed {
                ErrorPlaceholder(name: model.fileName)
            }
            if model.canNavigate, model.isFullyVisible {
                if model.hoverEdge == .left {
                    EdgeChevron(direction: .left)
                }
                if model.hoverEdge == .right {
                    EdgeChevron(direction: .right)
                }
            }
            if let live = model.livePhoto, !live.isPlaying {
                VStack {
                    HStack {
                        Spacer()
                        LiveBadge { live.play() }
                    }
                    Spacer()
                }
                .padding(12)
            }
            if model.isOrphanLivePhoto {
                VStack {
                    Spacer()
                    Label("此照片可能是 Live Photo，但视频部分未随文件传输", systemImage: "livephoto.slash")
                        .font(.callout)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(.white.opacity(0.15)))
                        .padding(.bottom, 44)
                }
                .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) {
            if model.isMouseInside, !model.isLoading, model.files.count > 0 {
                InfoOverlay(model: model)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: model.isMouseInside)
    }
}

struct EdgeChevron: View {
    let direction: CanvasEdge

    var body: some View {
        HStack {
            if direction == .right {
                Spacer()
            }
            Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(.black.opacity(0.35), in: Circle())
            if direction == .left {
                Spacer()
            }
        }
        .padding(.horizontal, 18)
    }
}

struct LiveBadge: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: "livephoto.play")
                Text("Live").fontWeight(.semibold)
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.2)))
        }
        .buttonStyle(.plain)
        .help("播放 Live Photo")
    }
}
