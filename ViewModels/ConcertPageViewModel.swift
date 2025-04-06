//
//  ConcertPageViewModel.swift
//  Barricade
//
//  Created by Michael Banna on 2025-04-05.
//

import SwiftUI
import SwiftData

extension ConcertPageView {
    @Observable
    class ViewModel {
        private let shazamService: ShazamService
        
        var isDetecting = false
        var detectionResult: ShazamMatchResult?
        
        // Helper to find the current concert
        private var concert: Concert?
        
        init(shazamService: ShazamService = .shared) {
            self.shazamService = shazamService
        }
        
        func setConcert(_ concertRef: Concert) {
            self.concert = concertRef
        }
        
        @MainActor
        func processVideoData(_ data: Data, modelContext: ModelContext) async -> ShazamMatchResult {
            isDetecting = true
            
            // Use ShazamKit to detect song from the video data
            await shazamService.matchAudioData(data)
            detectionResult = shazamService.lastResult
            
            if ((detectionResult?.isSuccess) != nil), let songTitle = detectionResult?.songTitle {
                // Check if the song already exists in the setlist
                if let concert = findConcert(in: modelContext),
                   !concert.setlist.contains(where: { $0.title == songTitle }) {
                    // Create and add the new song to the setlist
                    let newSong = Song(title: songTitle)
                    
                    if let artist = detectionResult?.artist {
                        // Add artist information if available
                        newSong.artist = artist
                    }
                    
                    // Add the song to the concert setlist
                    concert.setlist.append(newSong)
                    
                    // Save changes to the model context
                    try? modelContext.save()
                }
            }
            
            isDetecting = false
            return detectionResult ?? ShazamMatchResult()
        }
        
        // Helper to find the current concert
        private func findConcert(in modelContext: ModelContext) -> Concert? {
            // If we have a reference to the concert, use it
            if let concert = self.concert {
                return concert
            }
            
            // Otherwise try to find it in the model context
            let descriptor = FetchDescriptor<Concert>()
            guard let concerts = try? modelContext.fetch(descriptor),
                  let concert = concerts.first else {
                return nil
            }
            return concert
        }
    }
}
