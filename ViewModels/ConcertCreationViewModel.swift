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
        var nickname: String = ""
        var selectedColor: Color = .red
        private var existingConcert: Concert?
        var previousCities: [String] = []
        private var modelContext: ModelContext?
        
        var isEditing: Bool { existingConcert != nil }
        
        // Predefined color options
        let colorOptions: [Color] = [
            .red, .orange, .yellow, .green, .blue, .purple, .pink,
            Color(hex: "FF6B6B") ?? .red,    // Coral
            Color(hex: "4ECDC4") ?? .green,  // Teal
            Color(hex: "FF8C42") ?? .orange, // Light Orange
            Color(hex: "6A0572") ?? .purple, // Deep Purple
            Color(hex: "1A535C") ?? .blue    // Dark Teal
        ]
        
        @MainActor
        init(concert: Concert? = nil, modelContext: ModelContext? = nil) {
            self.modelContext = modelContext
            if let concert = concert {
                self.artist = concert.artist
                self.concertDate = concert.date
                self.tour = concert.tour
                self.city = concert.city
                self.nickname = concert.nickname
                self.selectedColor = concert.color
                self.existingConcert = concert
            }
            loadPreviousCities()
        }
        
        @MainActor
        func loadPreviousCities() {
            // Use either the existing concert's context or the provided context
            guard let context = existingConcert?.modelContext ?? modelContext else { return }
            
            // Fetch all concerts
            let descriptor = FetchDescriptor<Concert>()
            if let concerts = try? context.fetch(descriptor) {
                // Get unique cities and sort them
                let cities = Set(concerts.map { $0.city })
                previousCities = Array(cities).filter { !$0.isEmpty }.sorted()
            }
        }

        @MainActor
        func updateModelContext(_ context: ModelContext) {
            self.modelContext = context
            loadPreviousCities()
        }

        @MainActor
        func saveChanges(modelContext: ModelContext) {
            // Convert color to hex string for storage
            let hexColor = selectedColor.toHex() ?? "FF6B6B"
            
            if let existingConcert = existingConcert {
                // Update existing concert
                existingConcert.artist = artist
                existingConcert.date = concertDate
                existingConcert.tour = tour
                existingConcert.city = city
                existingConcert.nickname = nickname
                existingConcert.colorHex = hexColor
            } else {
                // Create new concert
                let newConcert = Concert(
                    date: concertDate,
                    artist: artist,
                    tour: tour,
                    city: city,
                    nickname: nickname,
                    colorHex: hexColor
                )
                modelContext.insert(newConcert)
            }
        }
    }
}

// Extension to convert Color to hex string
extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let hexString = String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        return hexString
    }
}
