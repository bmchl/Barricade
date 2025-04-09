//
//  ConcertPageViewModel.swift
//  Barricade
//
//  Created by Michael Banna on 2025-04-05.
//

import SwiftUI
import SwiftData
import AVFoundation

extension ConcertPageView {
    @Observable
    class ViewModel {
        private let shazamService: ShazamService
        
        var isDetecting = false
        var detectionResult: ShazamMatchResult?
        var currentPlayer: AVPlayer?
        
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

            let result = await shazamService.matchAudioData(data, player: currentPlayer!)
            self.detectionResult = result
            
            return result
        }
        
        func stopDetection() {
            isDetecting = false
            shazamService.stopDetection()
            currentPlayer = nil
        }
        
        private func findConcert(in modelContext: ModelContext) -> Concert? {
            if let concert = self.concert {
                return concert
            }
            
            let descriptor = FetchDescriptor<Concert>()
            guard let concerts = try? modelContext.fetch(descriptor),
                  let concert = concerts.first else {
                return nil
            }
            return concert
        }
    }
}
