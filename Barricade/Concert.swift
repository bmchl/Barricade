//
//  Concert.swift
//  Barricade
//
//  Created by Michael Banna on 2024-02-16.
//

import Foundation
import SwiftData

@Model
final class Concert {
    var date: Date
    var artist: String
    var tour: String
    var city: String
    var setlist : [Song]
    
    init(date: Date, artist: String, tour: String, city: String, setlist: [Song] = []) {
        self.date = date
        self.artist = artist
        self.tour = tour
        self.city = city
        self.setlist = setlist
    }
    
    func isInFuture() -> Bool {
            let currentDate = Date()
            return date > currentDate
        }
    
    func daysTo() -> Int {
            let calendar = Calendar.current
            let currentDate = Date()
            let components = calendar.dateComponents([.day], from: currentDate, to: date)
            
            // The result can be positive (days to the future) or negative (days since the past)
            return abs(components.day ?? 0)
        }
}
var placeholderSetlist: [Song] = [placeholderSong, placeholderSong, placeholderSong, placeholderSong, placeholderSong]
var placeholderConcert = Concert(date: Date(), artist: "Ariana Grande", tour: "Sweetener Tour", city: "Montreal, QC", setlist:placeholderSetlist)
