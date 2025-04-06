//
//  ShazamService.swift
//  Barricade
//
//  Created by Michael Banna on 2025-04-05.
//

import Foundation
import ShazamKit
import AVFoundation

struct ShazamMatchResult {
    let songTitle: String?
    let artist: String?
    let artworkURL: URL?
    let appleMusicURL: URL?
    let error: Error?
    
    init(match: SHMatch? = nil, error: Error? = nil) {
        self.songTitle = match?.mediaItems.first?.title
        self.artist = match?.mediaItems.first?.artist
        self.artworkURL = match?.mediaItems.first?.artworkURL
        self.appleMusicURL = match?.mediaItems.first?.appleMusicURL
        self.error = error
    }
    
    // Custom initializer for creating mock results
    init(songTitle: String?, artist: String?, artworkURL: URL? = nil, 
         appleMusicURL: URL? = nil, error: Error? = nil) {
        self.songTitle = songTitle
        self.artist = artist
        self.artworkURL = artworkURL
        self.appleMusicURL = appleMusicURL
        self.error = error
    }
    
    var isSuccess: Bool {
        return songTitle != nil && error == nil
    }
}

class ShazamService: NSObject {
    static let shared = ShazamService()
    
    private var managedSession: SHManagedSession?
    private var player: AVPlayer?
    
    // Updated to return the player for UI display
    func matchAudioData(_ data: Data) async -> (AVPlayer?, ShazamMatchResult) {
        // Check if running in a simulator
        #if targetEnvironment(simulator)
        print("Running in simulator - returning mock data")
        return (nil, mockShazamResult())
        #else
        
        do {
            // Create a temporary file from the video data
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFile = tempDirectory.appendingPathComponent("temp_audio.mp4")
            try data.write(to: tempFile)
            
            // Log the video file details
            let asset = AVAsset(url: tempFile)
            let duration = try await asset.load(.duration)
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            print("📹 Video duration: \(duration.seconds) seconds")
            print("🔊 Audio tracks count: \(audioTracks.count)")
            
            // Set up player to play the video
            let playerItem = AVPlayerItem(asset: asset)
            self.player = AVPlayer(playerItem: playerItem)
            
            // Set up audio session for playback and recording
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)
            
            // Create a managed session which handles recording and matching
            print("🎤 Starting managed session with microphone...")
            let session = SHManagedSession()
            self.managedSession = session
            
            // Prepare the session (optional but reduces latency)
            try await session.prepare()
            
            // Play the video
            print("▶️ Playing video...")
            player?.play()
            
            print("🎵 Listening for music...")
            
            // Get the result from the managed session
            let result = await session.result()
            
            // Process the result
            switch result {
            case .match(let match):
                print("✅ Match found: \(match.mediaItems.first?.title ?? "Unknown")")
                return (player, ShazamMatchResult(match: match))
                
            case .noMatch:
                print("❌ No match found")
                return (player, ShazamMatchResult(error: NSError(domain: "ShazamService", 
                                                      code: 1001, 
                                                      userInfo: [NSLocalizedDescriptionKey: "No match found"])))
                
            case .error(let error, _):
                print("❌ Error during matching: \(error.localizedDescription), code: \((error as NSError).code)")
                return (player, ShazamMatchResult(error: error))
            }
            
        } catch {
            print("Error processing audio: \(error.localizedDescription)")
            return (nil, ShazamMatchResult(error: error))
        }
        #endif
    }
    
    func stopPlayback() {
        // Stop the player and clean up
        player?.pause()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        managedSession?.cancel()
        managedSession = nil
    }
    
    // Return mock data for simulator testing
    private func mockShazamResult() -> ShazamMatchResult {
        return ShazamMatchResult(
            songTitle: "Sweetener (Simulator Mock)",
            artist: "Ariana Grande",
            artworkURL: URL(string: "https://example.com/artwork.jpg"),
            appleMusicURL: URL(string: "https://music.apple.com/example")
        )
    }
}
