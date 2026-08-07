import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
final class AnimatedImageController {
    private let frames: [CGImage]
    private let delays: [Double]
    private(set) var index = 0
    private(set) var isPlaying = true
    private var tickTask: Task<Void, Never>?

    var currentFrame: CGImage { frames[index] }

    init(frames: [CGImage], delays: [Double]) {
        self.frames = frames
        self.delays = delays
        scheduleTick()
    }

    func toggle() {
        isPlaying ? pause() : resume()
    }

    func pause() {
        isPlaying = false
        tickTask?.cancel()
    }

    func resume() {
        guard !isPlaying else { return }
        isPlaying = true
        scheduleTick()
    }

    private func advance() {
        guard frames.count > 0 else { return }
        index = (index + 1) % frames.count
        scheduleTick()
    }

    private func scheduleTick() {
        tickTask?.cancel()
        guard frames.count > 0 else { return }
        let delay = max(0.03, min(5.0, delays[min(index, delays.count - 1)]))
        tickTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self, self.isPlaying else { return }
            self.advance()
        }
    }
}
