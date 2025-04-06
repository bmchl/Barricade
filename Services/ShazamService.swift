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

class ShazamService: NSObject, SHSessionDelegate {
    static let shared = ShazamService()
    
    var lastResult: ShazamMatchResult?
        
    // SHSessionDelegate methods
    func session(_ session: SHSession, didFind match: SHMatch) {
        print("Audio matched!")
        lastResult = ShazamMatchResult(match: match)
    }
    
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        if let error = error {
            print("Error matching audio: \(error.localizedDescription)")
            lastResult = ShazamMatchResult(error: error)
        } else {
            print("No match found")
            lastResult = ShazamMatchResult(error: NSError(domain: "ShazamService", code: 1001, userInfo: [NSLocalizedDescriptionKey : "No match found"]))
        }
        
    }
    
    
    
    func matchAudioData(_ data: Data) async {
        // Check if running in a simulator
        #if targetEnvironment(simulator)
        print("Running in simulator - returning mock data")
        return mockShazamResult()
        #else
        
        do {
            // Create a ShazamKit session
            let session = SHSession()
            session.delegate = self
            
            // Create a file URL for the data
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFile = tempDirectory.appendingPathComponent("temp_audio.mp4")
            
            // Write the data to a temporary file
            try data.write(to: tempFile)
            
            // Create an AVAsset from the video file
            let asset = AVAsset(url: tempFile)
            
            // Using the built-in signature generator with AVAsset
            print("Generating signature from asset...")
            let signature = try await SHSignatureGenerator.signature(from: asset)
            print("Signature generated successfully with duration: \(signature.duration)")
            
            
            print("Matching signature...")
            session.match(signature)
        } catch {
            print("Error generating signature or matching: \(error.localizedDescription)")
            lastResult = ShazamMatchResult(error: error)
        }
        #endif
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
