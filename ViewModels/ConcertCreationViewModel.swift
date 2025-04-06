//
//  ConcertCreationViewModel.swift
//  Barricade
//
//  Created by Michael Banna on 2025-04-05.
//

import SwiftUI
import SwiftData

extension ConcertCreationSheet {
    @Observable
    class ViewModel {
        var artist: String = ""
        var concertDate: Date = Date()
        var tour: String = ""
        var city: String = ""

        @MainActor
        func createConcert(modelContext: ModelContext) {
            let newItem = Concert(date: concertDate, artist: artist, tour: tour, city: city)
            modelContext.insert(newItem)
        }
    }
}
