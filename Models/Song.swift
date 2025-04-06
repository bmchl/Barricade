//
//  Song.swift
//  Barricade
//
//  Created by Michael Banna on 2024-02-16.
//

import Foundation
import SwiftData

@Model
final class Song {
    var title: String
    var artist: String
    var link: String
    var clips: [URL]
    
    init(title: String, artist: String = "") {
        self.title = title
        self.artist = artist
        self.link = ""
        self.clips = []
    }
}

var placeholderSong = Song(title: "better off", artist: "Ariana Grande")
