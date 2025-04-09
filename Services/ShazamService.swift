//
//  ShazamService.swift
//  Barricade
//
//  Created by Michael Banna on 2025-04-05.
//

import Foundation
import ShazamKit
import AVFoundation

struct ShazamMatchResult: Identifiable {
    let id: UUID
    let songTitle: String?
    let artist: String?
    let artworkURL: URL?
    let appleMusicURL: URL?
    let error: Error?
    
//    // This one stays the same
//    init(
//        songTitle: String?,
//        artist: String?,
//        artworkURL: URL? = nil,
//        appleMusicURL: URL? = nil,
//        error: Error? = nil,
//        id: UUID = UUID()
//    ) {
//        self.songTitle = songTitle
//        self.artist = artist
//        self.artworkURL = artworkURL
//        self.appleMusicURL = appleMusicURL
//        self.error = error
//        self.id = id
//    }

    // Disambiguate with a label
    init(from match: SHMatch?, error: Error? = nil) {
        self.songTitle = match?.mediaItems.first?.title
        self.artist = match?.mediaItems.first?.artist
        self.artworkURL = match?.mediaItems.first?.artworkURL
        self.appleMusicURL = match?.mediaItems.first?.appleMusicURL
        self.error = error
        self.id = UUID()
    }
    
    var isSuccess: Bool {
        return songTitle != nil && error == nil
    }
}

class ShazamService: NSObject {
    static let shared = ShazamService()
    private var managedSession: SHManagedSession?
    
    func matchAudioData(_ data: Data, player: AVPlayer) async -> ShazamMatchResult {
        do {
            // Set up audio session for playback and recording
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)
            
            // Create a managed session which handles recording and matching
            print("🎤 Starting managed session with microphone...")
            let session = SHManagedSession()
            self.managedSession = session
            
            // Prepare the session (optional but reduces latency)
            await session.prepare()
            
            print("🎵 Listening for music...")
            
            // Start playing the video
            await player.seek(to: .zero)
            player.play()
            
            // Get the result from the managed session
            let result = await session.result()
            
            // Process the result
            switch result {
            case .match(let match):
                print("✅ Match found: \(match.mediaItems.first?.title ?? "Unknown")")
                return ShazamMatchResult(from: match)
                
            case .noMatch:
                print("❌ No match found")
                return ShazamMatchResult(from: nil, error: NSError(domain: "ShazamService",
                                                      code: 1001,
                                                      userInfo: [NSLocalizedDescriptionKey: "No match found"]))
                
            case .error(let error, _):
                print("❌ Error during matching: \(error.localizedDescription)")
                return ShazamMatchResult(from: nil, error: error)
            }
            
        } catch {
            print("Error processing audio: \(error.localizedDescription)")
            return ShazamMatchResult(from: nil, error: error)
        }
    }
    
    func stopDetection() {
        managedSession?.cancel()
        managedSession = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
//    // Return mock data for simulator testing
//    private func mockShazamResult() -> ShazamMatchResult {
//        return ShazamMatchResult(
//            songTitle: "Sweetener (Simulator Mock)",
//            artist: "Ariana Grande",
//            artworkURL: URL(string: "https://example.com/artwork.jpg"),
//            appleMusicURL: URL(string: "https://music.apple.com/example")
//        )
//    }
}
