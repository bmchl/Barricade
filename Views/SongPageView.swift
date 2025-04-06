//
//  SongPageView.swift
//  Barricade
//
//  Created by Michael Banna on 2024-02-16.
//

import SwiftUI
import SwiftData
import AVKit

struct SongPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var song: Song
    @StateObject private var playerModel = PlayerModel()
    
    var body: some View {
        VStack {
            if !song.clips.isEmpty {
                VideoPlayer(player: playerModel.player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .onAppear {
                        // Configure audio session and start playing
                        playerModel.configureAudioSession()
                        playerModel.loadVideo(url: song.clips[0])
                    }
                    .onDisappear {
                        playerModel.cleanup()
                    }
            } else {
                Text("No video clips available")
                    .foregroundColor(.secondary)
            }
            
            Text(song.title)
                .font(.title)
                .padding(.top)
            
            if !song.artist.isEmpty {
                Text(song.artist)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Song Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ViewModel for handling video playback
class PlayerModel: ObservableObject {
    @Published var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var pictureInPictureController: AVPictureInPictureController?
    
    func loadVideo(url: URL) {
        player = AVPlayer(url: url)
        
        // Create a player layer (needed for PiP)
        playerLayer = AVPlayerLayer(player: player)
        
        // Setup PiP if available
        setupPictureInPicture()
        
        // Start playback
        player?.play()
    }
    
    func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Configure for movie playback with background audio support
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    func setupPictureInPicture() {
        guard let playerLayer = playerLayer, AVPictureInPictureController.isPictureInPictureSupported() else {
            print("Picture in Picture not supported")
            return
        }
        
        pictureInPictureController = AVPictureInPictureController(playerLayer: playerLayer)
        pictureInPictureController?.canStartPictureInPictureAutomaticallyFromInline = true
    }
    
    func cleanup() {
        player?.pause()
        player = nil
        pictureInPictureController = nil
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}

#Preview {
    SongPageView(song: .constant(placeholderSong))
        .modelContainer(for: Song.self, inMemory: true)
}
