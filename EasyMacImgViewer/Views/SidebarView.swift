import AppKit
import ImageIO
import SwiftUI

@MainActor
enum ThumbnailLoader {
    private static let cache = NSCache<NSURL, CGImage>()

    static func load(_ url: URL) async -> CGImage? {
        let key = url as NSURL
        if let cached = cache.object(forKey: key) { return cached }
        let image: CGImage? = await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let options = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 256,
            ] as CFDictionary
            return CGImageSourceCreateThumbnailAtIndex(source, 0, options)
        }.value
        if let image {
            cache.setObject(image, forKey: key)
        }
        return image
    }
}

enum SidebarDisplayMode: String {
    case thumbnail
    case compact
}

struct SidebarView: View {
    let model: ViewerModel
    @AppStorage("sidebarDisplayMode") private var displayMode = SidebarDisplayMode.thumbnail

    var body: some View {
        VStack(spacing: 0) {
            List(Array(model.files.enumerated()), id: \.element) { index, item in
                SidebarRow(item: item, isSelected: index == model.index, displayMode: displayMode)
                    .contentShape(Rectangle())
                    .onTapGesture { model.navigate(to: index) }
            }
            .listStyle(.sidebar)
            .scrollIndicators(.visible)

            Divider()

            HStack(spacing: 4) {
                Button {
                    displayMode = .thumbnail
                } label: {
                    Image(systemName: "photo.on.rectangle")
                }
                .buttonStyle(.borderless)
                .help("缩略图视图")
                .opacity(displayMode == .thumbnail ? 1 : 0.4)

                Button {
                    displayMode = .compact
                } label: {
                    Image(systemName: "list.bullet")
                }
                .buttonStyle(.borderless)
                .help("列表视图")
                .opacity(displayMode == .compact ? 1 : 0.4)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(width: 240)
        .background(.regularMaterial)
    }
}

struct SidebarRow: View {
    let item: ViewerItem
    let isSelected: Bool
    let displayMode: SidebarDisplayMode
    @State private var thumbnail: CGImage?

    var body: some View {
        HStack(spacing: 8) {
            if displayMode == .thumbnail {
                Group {
                    if let thumbnail {
                        Image(decorative: thumbnail, scale: 1)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.quaternary)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: iconName)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
            } else {
                Image(systemName: iconName)
                    .foregroundStyle(.secondary)
            }
            Text(item.displayName)
                .lineLimit(1)
                .truncationMode(.middle)
                .font(.callout)
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .task {
            thumbnail = await ThumbnailLoader.load(item.imageURL)
        }
    }

    private var iconName: String {
        switch item {
        case .file: return "photo"
        case .folder: return "folder"
        }
    }
}
