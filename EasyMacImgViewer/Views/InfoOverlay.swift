import Foundation
import SwiftUI

struct InfoOverlay: View {
    let model: ViewerModel

    var body: some View {
        HStack(spacing: 12) {
            Text(model.fileName)
                .lineLimit(1)
                .fontWeight(.medium)
            if model.files.count > 0 {
                Text("\(model.index + 1) / \(model.files.count)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            if model.imageSize.width > 0 {
                Text("\(Int(model.imageSize.width)) × \(Int(model.imageSize.height))")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            if let size = model.fileSize {
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .foregroundStyle(.secondary)
            }
        }
        .font(.callout)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.15)))
    }
}
