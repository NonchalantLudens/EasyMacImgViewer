import AVFoundation
import Foundation
import Observation
import QuartzCore

@MainActor
@Observable
final class LivePhotoController {
    let videoURL: URL
    private(set) var isPlaying = false
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    let playerLayer = AVPlayerLayer()

    init(videoURL: URL) {
        self.videoURL = videoURL
        playerLayer.videoGravity = .resizeAspect
    }

    func toggle() {
        isPlaying ? pause() : play()
    }

    func play() {
        if player == nil {
            setup()
        }
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        isPlaying = false
    }

    func teardown() {
        pause()
        playerLayer.removeFromSuperlayer()
        playerLayer.player = nil
        player = nil
        looper = nil
    }

    private func setup() {
        let item = AVPlayerItem(url: videoURL)
        let player = AVQueuePlayer(playerItem: item)
        self.player = player
        looper = AVPlayerLooper(player: player, templateItem: item)
        playerLayer.player = player
    }
}
