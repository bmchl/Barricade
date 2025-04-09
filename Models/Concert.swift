//
//  Concert.swift
//  Barricade
//
//  Created by Michael Banna on 2024-02-16.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Concert {
    var date: Date
    var artist: String
    var tour: String
    var city: String
    var nickname: String
    var colorHex: String
    
    @Relationship(deleteRule: .cascade, inverse: \Song.concert)
    var setlist: [Song] = []
    
    init(date: Date, artist: String, tour: String, city: String, nickname: String = "", colorHex: String = "FF6B6B", setlist: [Song] = []) {
        self.date = date
        self.artist = artist
        self.tour = tour
        self.city = city
        self.nickname = nickname
        self.colorHex = colorHex
        self.setlist = setlist
    }
    
    // Convert hex string to Color
    var color: Color {
        get {
            Color(hex: colorHex) ?? .red
        }
    }
    
    func isInFuture() -> Bool {
        let currentDate = Date()
        return date > currentDate
    }
    
    func daysTo() -> Int {
        let calendar = Calendar.current
        let currentDate = Date()
        let components = calendar.dateComponents([.day], from: currentDate, to: date)
        
        return abs(components.day ?? 0)
    }
}

var placeholderSetlist: [Song] = [placeholderSong, placeholderSong, placeholderSong, placeholderSong, placeholderSong]

// Collection of placeholder concerts with different artists, tours, cities and colors
var placeholderConcerts: [Concert] = [
    Concert(
        date: Date().addingTimeInterval(60*60*24*30), // 30 days in future
        artist: "Ariana Grande",
        tour: "Sweetener Tour",
        city: "Montreal, QC",
        colorHex: "FF6B6B", // Coral red
        setlist: placeholderSetlist
    ),
    Concert(
        date: Date().addingTimeInterval(-60*60*24*10), // 10 days ago
        artist: "Taylor Swift",
        tour: "Eras Tour",
        city: "Toronto, ON",
        colorHex: "4ECDC4", // Teal
        setlist: placeholderSetlist
    ),
    Concert(
        date: Date().addingTimeInterval(60*60*24*60), // 60 days in future
        artist: "The Weeknd",
        tour: "After Hours Tour",
        city: "Vancouver, BC",
        colorHex: "FF8C42", // Orange
        setlist: placeholderSetlist
    ),
    Concert(
        date: Date().addingTimeInterval(-60*60*24*30), // 30 days ago
        artist: "Beyoncé",
        tour: "Renaissance World Tour",
        city: "Calgary, AB",
        colorHex: "6A0572", // Purple
        setlist: placeholderSetlist
    ),
    Concert(
        date: Date().addingTimeInterval(60*60*24*14), // 14 days in future
        artist: "Coldplay",
        tour: "Music of the Spheres Tour",
        city: "Ottawa, ON",
        colorHex: "1A535C", // Dark teal
        setlist: placeholderSetlist
    )
]

var placeholderConcert = placeholderConcerts[0]

// Extension to help with hex color conversion
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
