//
//  VideoDetectionViewModel.swift
//  Barricade
//
//  Created by Michael Banna on 2025-04-08.
//

import SwiftUI
import AVKit
import SwiftData
import ShazamKit

extension VideoDetectionView {
    @Observable
    class ViewModel {
        var player: AVPlayer?
        var isDetecting = false
        var detectedSong: String?
        var detectedArtist: String?
        var error: Error?
        var noMatchFound = false
        private(set) var currentMatchResult: ShazamMatchResult?

        private let shazamService = ShazamService.shared
        private var detectionTask: Task<Void, Never>?
        private var videoURL: URL?

        @MainActor
        func setup(videoURL: URL) {
            self.videoURL = videoURL
            self.player = AVPlayer(url: videoURL)
        }

        @MainActor
        func startDetection(
            videoData: Data,
            concert: Concert,
            onSongDetected: ((ShazamMatchResult) -> Void)?
        ) {
            isDetecting = true

            guard let player = self.player else {
                print("Error: No player available")
                return
            }

            detectionTask = Task {
                let result = await shazamService.matchAudioData(videoData, player: player)

                await MainActor.run {
                    isDetecting = false

                    if result.isSuccess, let songTitle = result.songTitle {
                        self.detectedSong = songTitle
                        self.detectedArtist = result.artist
                        self.currentMatchResult = result
                        self.player?.isMuted = false
                    } else {
                        self.noMatchFound = true
                        self.detectedSong = nil
                        self.detectedArtist = nil
                        self.error = result.error
                        self.currentMatchResult = result

                        if let error = result.error {
                            print("Song detection failed: \(error.localizedDescription)")
                        } else {
                            print("No match found for the song")
                        }
                    }
                }
            }
        }

        @MainActor
        func stopDetection() {
            detectionTask?.cancel()
            player?.pause()
            player = nil
            shazamService.stopDetection()
        }
    }
}
