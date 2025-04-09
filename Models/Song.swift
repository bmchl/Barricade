//
//  Song.swift
//  Barricade
//
//  Created by Michael Banna on 2024-02-16.
//

import Foundation
import SwiftData

@Model
final class Song: Identifiable, Equatable, Hashable {
    var id: UUID
    var title: String
    var artist: String
    var order: Int
    var link: String
    var clipPaths: [String]
    
    var clips: [URL] {
        get {
            clipPaths.map { URL(fileURLWithPath: $0) }
        }
        set {
            clipPaths = newValue.map { $0.path }
        }
    }
    
    var concert: Concert?

    init(
        title: String,
        artist: String = "",
        order: Int,
        link: String = "",
        clips: [URL] = [],
        concert: Concert? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.order = order
        self.artist = artist
        self.link = link
        self.clipPaths = clips.map { $0.path }
        self.concert = concert
    }

    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

var placeholderSong = Song(title: "better off", artist: "Ariana Grande", order: 0)
