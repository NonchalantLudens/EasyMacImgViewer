import AppKit
import SwiftUI

enum CanvasGeometry {
    static func imageRect(imageSize: CGSize, scale: CGFloat, pan: CGSize, in viewSize: CGSize) -> CGRect {
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(
            x: (viewSize.width - width) / 2 + pan.width,
            y: (viewSize.height - height) / 2 + pan.height,
            width: width,
            height: height
        )
    }
}

struct ImageCanvasView: NSViewRepresentable {
    let model: ViewerModel

    func makeNSView(context: Context) -> CanvasNSView {
        CanvasNSView(model: model)
    }

    func updateNSView(_ nsView: CanvasNSView, context: Context) {
        _ = model.displayImage
        _ = model.livePhoto?.isPlaying
        nsView.model = model
        nsView.syncState()
    }

    static func dismantleNSView(_ nsView: CanvasNSView, coordinator: ()) {
        nsView.cleanup()
    }
}

final class CanvasNSView: NSView {
    weak var model: ViewerModel?

    private var keyMonitor: Any?
    private var isPanning = false
    private var lastDrag = NSPoint.zero
    private var lastViewSize = CGSize.zero

    init(model: ViewerModel) {
        self.model = model
        super.init(frame: .zero)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                self?.handleKeyEvent(event) ?? event
            }
            DispatchQueue.main.async { [weak self] in
                self?.window?.makeFirstResponder(self)
            }
        } else {
            removeKeyMonitor()
        }
    }

    func cleanup() {
        removeKeyMonitor()
        model?.livePhoto?.teardown()
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard let model, let window, window.isKeyWindow else { return event }
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command) {
            return event
        }
        switch event.keyCode {
        case 123: model.navigate(by: -1); return nil
        case 124: model.navigate(by: 1); return nil
        case 49: model.navigate(by: 1); return nil
        default: return event
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    override func layout() {
        super.layout()
        if bounds.size != lastViewSize {
            lastViewSize = bounds.size
            model?.setViewSize(bounds.size)
        }
        syncState()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let model, let image = model.displayImage else { return }
        let rect = CanvasGeometry.imageRect(
            imageSize: model.imageSize,
            scale: model.effectiveScale,
            pan: model.pan,
            in: bounds.size
        )
        NSGraphicsContext.current?.cgContext.interpolationQuality = .high
        NSGraphicsContext.current?.cgContext.draw(image, in: rect)
    }

    func syncState() {
        guard let model else { return }
        if let live = model.livePhoto, live.isPlaying {
            let layer = live.playerLayer
            if layer.superlayer !== self.layer {
                self.layer?.addSublayer(layer)
            }
            layer.frame = CanvasGeometry.imageRect(
                imageSize: model.imageSize,
                scale: model.effectiveScale,
                pan: model.pan,
                in: bounds.size
            )
            layer.videoGravity = .resizeAspect
        } else {
            model.livePhoto?.playerLayer.removeFromSuperlayer()
        }
        needsDisplay = true
    }

    override func scrollWheel(with event: NSEvent) {
        guard let model, imageSizeValid(model) else { return }
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command) else { return }
        let factor: CGFloat
        if event.hasPreciseScrollingDeltas {
            factor = pow(1.01, event.scrollingDeltaY)
        } else {
            factor = pow(1.08, event.scrollingDeltaY)
        }
        guard factor != 1 else { return }
        model.zoom(by: factor, anchor: convert(event.locationInWindow, from: nil))
    }

    override func magnify(with event: NSEvent) {
        guard let model, imageSizeValid(model) else { return }
        model.zoom(by: 1 + event.magnification, anchor: convert(event.locationInWindow, from: nil))
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        guard let model else { return }
        if event.clickCount == 2 {
            model.toggleFitActual()
            return
        }
        let point = convert(event.locationInWindow, from: nil)
        if model.isFullyVisible {
            if model.canNavigate && point.x < bounds.width * 0.12 {
                model.navigate(by: -1)
            } else if model.canNavigate && point.x > bounds.width * 0.88 {
                model.navigate(by: 1)
            }
        } else {
            isPanning = true
            lastDrag = point
            NSCursor.closedHand.set()
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard isPanning, let model else { return }
        let point = convert(event.locationInWindow, from: nil)
        model.pan = CGSize(
            width: model.pan.width + (point.x - lastDrag.x),
            height: model.pan.height + (point.y - lastDrag.y)
        )
        model.clampPan()
        lastDrag = point
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if isPanning {
            isPanning = false
            updateCursor(at: convert(event.locationInWindow, from: nil))
        }
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        updateCursor(at: point)
        guard let model else { return }
        if model.isFullyVisible && model.canNavigate {
            if point.x < bounds.width * 0.12 {
                model.hoverEdge = .left
            } else if point.x > bounds.width * 0.88 {
                model.hoverEdge = .right
            } else {
                model.hoverEdge = nil
            }
        } else {
            model.hoverEdge = nil
        }
    }

    override func mouseEntered(with event: NSEvent) {
        model?.isMouseInside = true
    }

    override func mouseExited(with event: NSEvent) {
        isPanning = false
        model?.isMouseInside = false
        model?.hoverEdge = nil
        NSCursor.arrow.set()
    }

    private func imageSizeValid(_ model: ViewerModel) -> Bool {
        model.imageSize.width > 0 && model.imageSize.height > 0
    }

    private func updateCursor(at point: NSPoint) {
        guard let model else {
            NSCursor.arrow.set()
            return
        }
        if isPanning {
            NSCursor.closedHand.set()
        } else if !model.isFullyVisible {
            NSCursor.openHand.set()
        } else if model.canNavigate && (point.x < bounds.width * 0.12 || point.x > bounds.width * 0.88) {
            NSCursor.pointingHand.set()
        } else {
            NSCursor.arrow.set()
        }
    }
}
