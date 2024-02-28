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
    var link: String
    var clips: [URL]
    
    init(title: String) {
        self.title = title
        self.link = ""
        self.clips = []
    }
}

var placeholderSong = Song(title: "better off")
