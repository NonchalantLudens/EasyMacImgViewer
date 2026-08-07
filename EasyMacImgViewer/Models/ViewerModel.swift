import CoreGraphics
import Foundation
import Observation

enum ZoomMode: Equatable {
    case fit
    case actual
    case custom(CGFloat)
}

enum CanvasEdge: Equatable {
    case left
    case right
}

@MainActor
@Observable
final class ViewerModel {
    let url: URL

    private(set) var files: [ViewerItem] = []
    private(set) var index = 0
    private(set) var isLoading = true
    private(set) var loadFailed = false
    private(set) var staticImage: CGImage?
    private(set) var imageSize = CGSize.zero
    private(set) var animator: AnimatedImageController?
    private(set) var livePhoto: LivePhotoController?
    private(set) var isOrphanLivePhoto = false

    var zoomMode: ZoomMode = .fit
    private(set) var scale: CGFloat = 1
    var pan = CGSize.zero
    var viewSize = CGSize.zero
    var hoverEdge: CanvasEdge?
    var isMouseInside = false

    private var loadTask: Task<Void, Never>?
    private var zoomAnimationTask: Task<Void, Never>?

    nonisolated init(url: URL, defaults: UserDefaults = .standard) {
        self.url = url
        self.defaults = defaults
    }

    nonisolated(unsafe) let defaults: UserDefaults

    var currentItem: ViewerItem? {
        files.indices.contains(index) ? files[index] : nil
    }

    var currentURL: URL {
        currentItem?.imageURL ?? url
    }

    var canNavigate: Bool { files.count > 1 }
    var canGoPrevious: Bool { index > 0 }
    var canGoNext: Bool { index < files.count - 1 }
    var isAnimated: Bool { animator != nil }
    var displayImage: CGImage? { animator?.currentFrame ?? staticImage }
    var fileName: String { currentItem?.displayName ?? url.lastPathComponent }

    var folderModeEnabled: Bool {
        get { defaults.bool(forKey: "folderModeEnabled") }
        set {
            defaults.set(newValue, forKey: "folderModeEnabled")
            reloadPreservingSelection()
        }
    }

    var primaryPreference: PrimaryImagePreference {
        get {
            guard let raw = defaults.string(forKey: "primaryImagePreference"),
                  let value = PrimaryImagePreference(rawValue: raw) else { return .edited }
            return value
        }
        set {
            defaults.set(newValue.rawValue, forKey: "primaryImagePreference")
            reloadPreservingSelection()
        }
    }

    var fileSize: Int64? {
        guard let value = try? currentURL.resourceValues(forKeys: [.fileSizeKey]).fileSize else { return nil }
        return Int64(value)
    }

    var fitScale: CGFloat {
        guard imageSize.width > 0, imageSize.height > 0,
              viewSize.width > 0, viewSize.height > 0 else { return 1 }
        return min(1, viewSize.width / imageSize.width, viewSize.height / imageSize.height)
    }

    var effectiveScale: CGFloat {
        switch zoomMode {
        case .fit: return fitScale
        case .actual: return 1
        case .custom(let value): return value
        }
    }

    var scalePercent: Int {
        Int((effectiveScale * 100).rounded())
    }

    var isFullyVisible: Bool {
        guard imageSize.width > 0, imageSize.height > 0, viewSize.width > 0 else { return true }
        return imageSize.width * effectiveScale <= viewSize.width + 0.5
            && imageSize.height * effectiveScale <= viewSize.height + 0.5
    }

    func load() async {
        loadTask?.cancel()
        isLoading = true
        loadFailed = false
        files = []
        index = 0
        resetImageState()
        let target = url
        let folderMode = folderModeEnabled
        let preference = primaryPreference
        let scanDirectory = Self.scanDirectory(for: target, folderMode: folderMode)
        loadTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let scanned = await FolderScanner.scan(
                directory: scanDirectory,
                folderMode: folderMode,
                primaryPreference: preference
            )
            guard !Task.isCancelled else { return }
            self.files = scanned
            self.index = Self.locate(target, in: scanned) ?? 0
            await self.decodeCurrent()
        }
        await loadTask?.value
    }

    func navigate(by delta: Int) {
        navigate(to: index + delta)
    }

    func navigate(to newIndex: Int) {
        guard files.indices.contains(newIndex) else { return }
        index = newIndex
        reloadCurrent()
    }

    func reloadPreservingSelection() {
        let previousName = fileName
        let previousImageURL = currentURL
        let folderMode = folderModeEnabled
        let preference = primaryPreference
        let scanDirectory = Self.scanDirectory(for: url, folderMode: folderMode)
        loadTask?.cancel()
        resetImageState()
        loadTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let scanned = await FolderScanner.scan(
                directory: scanDirectory,
                folderMode: folderMode,
                primaryPreference: preference
            )
            guard !Task.isCancelled else { return }
            self.files = scanned
            self.index = scanned.firstIndex {
                $0.displayName == previousName || $0.imageURL == previousImageURL
            } ?? 0
            await self.decodeCurrent()
        }
    }

    /// 文件夹模式下，若打开的文件位于"照片文件夹"内，扫描其父目录以把文件夹作为列表项
    private static func scanDirectory(for target: URL, folderMode: Bool) -> URL {
        let base = target.deletingLastPathComponent()
        guard folderMode, FolderScanner.isPhotoFolder(base) else { return base }
        return base.deletingLastPathComponent()
    }

    private func reloadCurrent() {
        loadTask?.cancel()
        resetImageState()
        loadTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.decodeCurrent()
        }
    }

    private static func locate(_ target: URL, in items: [ViewerItem]) -> Int? {
        let canonical = target.resolvingSymlinksInPath()
        if let index = items.firstIndex(where: { $0.imageURL == canonical }) {
            return index
        }
        let stem = canonical.deletingPathExtension().lastPathComponent
        if let index = items.firstIndex(where: {
            if case .file(let url) = $0 { return url.deletingPathExtension().lastPathComponent == stem }
            return false
        }) {
            return index
        }
        let directoryName = canonical.deletingLastPathComponent().lastPathComponent
        if let index = items.firstIndex(where: {
            if case .folder(let name, _) = $0 { return name == directoryName }
            return false
        }) {
            return index
        }
        return nil
    }

    func zoomIn() {
        animateZoom(by: 1.25, anchor: CGPoint(x: viewSize.width / 2, y: viewSize.height / 2))
    }

    func zoomOut() {
        animateZoom(by: 0.8, anchor: CGPoint(x: viewSize.width / 2, y: viewSize.height / 2))
    }

    func animateZoom(by factor: CGFloat, anchor: CGPoint) {
        guard imageSize.width > 0, imageSize.height > 0 else { return }
        let startScale = effectiveScale
        let targetScale = min(max(startScale * factor, 0.02), 32)
        guard targetScale != startScale else { return }
        let startPan = pan
        let center = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        let contentX = (anchor.x - center.x - startPan.width) / startScale
        let contentY = (anchor.y - center.y - startPan.height) / startScale
        let targetPan = CGSize(
            width: anchor.x - center.x - contentX * targetScale,
            height: anchor.y - center.y - contentY * targetScale
        )
        zoomAnimationTask?.cancel()
        let duration: TimeInterval = 0.18
        let startTime = Date()
        zoomAnimationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(startTime)
                let t = min(max(elapsed / duration, 0), 1)
                let eased = 1 - pow(1 - t, 3)
                self.scale = startScale + (targetScale - startScale) * eased
                self.zoomMode = .custom(self.scale)
                self.pan = CGSize(
                    width: startPan.width + (targetPan.width - startPan.width) * eased,
                    height: startPan.height + (targetPan.height - startPan.height) * eased
                )
                if t >= 1 { break }
                try? await Task.sleep(for: .milliseconds(16))
            }
            if !Task.isCancelled {
                self.scale = targetScale
                self.zoomMode = .custom(targetScale)
                self.pan = targetPan
                self.clampPan()
            }
        }
    }

    func zoom(by factor: CGFloat, anchor: CGPoint) {
        guard imageSize.width > 0, imageSize.height > 0 else { return }
        let newScale = min(max(scale * factor, 0.02), 32)
        guard newScale != scale else { return }
        let center = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        let contentX = (anchor.x - center.x - pan.width) / scale
        let contentY = (anchor.y - center.y - pan.height) / scale
        scale = newScale
        zoomMode = .custom(newScale)
        pan = CGSize(
            width: anchor.x - center.x - contentX * newScale,
            height: anchor.y - center.y - contentY * newScale
        )
        clampPan()
    }

    func fit() {
        zoomMode = .fit
        scale = fitScale
        pan = .zero
    }

    func actual() {
        zoomMode = .actual
        scale = 1
        pan = .zero
    }

    func toggleFitActual() {
        if zoomMode == .fit {
            actual()
        } else {
            fit()
        }
    }

    func setViewSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        viewSize = size
        if zoomMode == .fit {
            scale = fitScale
        }
        clampPan()
    }

    func clampPan() {
        guard imageSize.width > 0, imageSize.height > 0 else {
            pan = .zero
            return
        }
        if isFullyVisible {
            pan = .zero
            return
        }
        let contentWidth = imageSize.width * scale
        let contentHeight = imageSize.height * scale
        let maxX = max(0, (contentWidth - viewSize.width) / 2)
        let maxY = max(0, (contentHeight - viewSize.height) / 2)
        pan = CGSize(
            width: min(max(pan.width, -maxX), maxX),
            height: min(max(pan.height, -maxY), maxY)
        )
    }

    private func resetImageState() {
        isLoading = true
        loadFailed = false
        staticImage = nil
        animator = nil
        imageSize = .zero
        livePhoto?.teardown()
        livePhoto = nil
        isOrphanLivePhoto = false
        zoomMode = .fit
        scale = 1
        pan = .zero
    }

    private func decodeCurrent() async {
        let target = currentURL
        if let videoURL = LivePhotoPairer.pairedVideoURL(for: target) {
            livePhoto = LivePhotoController(videoURL: videoURL)
        } else if LivePhotoPairer.isLivePhotoContainer(target) {
            isOrphanLivePhoto = true
        }
        let result = await ImageLoader.decode(from: target)
        guard !Task.isCancelled else { return }
        isLoading = false
        switch result {
        case .still(let image):
            staticImage = image
            imageSize = CGSize(width: image.width, height: image.height)
        case .animated(let frames, let delays):
            let animator = AnimatedImageController(frames: frames, delays: delays)
            self.animator = animator
            imageSize = CGSize(width: frames.first?.width ?? 0, height: frames.first?.height ?? 0)
        case .failed:
            loadFailed = true
        }
    }
}
