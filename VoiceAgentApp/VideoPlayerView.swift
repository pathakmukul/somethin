import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: UIViewRepresentable {
    @Binding var isAgentActive: Bool
    
    // Load videos from bundle
    private var idleVideoURL: URL? {
        Bundle.main.url(forResource: "idle", withExtension: "mp4")
    }
    
    private var talkVideoURL: URL? {
        Bundle.main.url(forResource: "Talk", withExtension: "mp4")
    }
    
    class Coordinator: NSObject {
        var parent: VideoPlayerView
        var playerLooper: AVPlayerLooper?
        var queuePlayer: AVQueuePlayer?
        var currentVideoURL: URL?
        
        init(_ parent: VideoPlayerView) {
            self.parent = parent
        }
        
        func setupPlayer(for videoURL: URL?) -> AVQueuePlayer {
            guard let url = videoURL else {
                print("VideoPlayerView: Could not load video URL")
                return AVQueuePlayer()
            }
            
            let asset = AVAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            
            let queuePlayer = AVQueuePlayer(playerItem: playerItem)
            playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
            
            return queuePlayer
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        // Start with idle video
        let player = context.coordinator.setupPlayer(for: idleVideoURL)
        context.coordinator.queuePlayer = player
        context.coordinator.currentVideoURL = idleVideoURL
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)
        
        // Store the layer for later updates
        view.layer.name = "videoContainer"
        
        player.play()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Determine which video should be playing
        let targetVideoURL = isAgentActive ? talkVideoURL : idleVideoURL
        
        // Only switch if video changed
        if context.coordinator.currentVideoURL != targetVideoURL {
            context.coordinator.currentVideoURL = targetVideoURL
            
            // Create new player for the new video
            let newPlayer = context.coordinator.setupPlayer(for: targetVideoURL)
            context.coordinator.queuePlayer = newPlayer
            
            // Update the player layer
            if let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer {
                playerLayer.player = newPlayer
            }
            
            newPlayer.play()
        }
        
        // Update frame
        if let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer {
            playerLayer.frame = uiView.bounds
        }
    }
}