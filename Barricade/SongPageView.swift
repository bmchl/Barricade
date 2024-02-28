//
//  SongPageView.swift
//  Barricade
//
//  Created by Michael Banna on 2024-02-16.
//

import SwiftUI
import SwiftData
import AVKit


struct SongPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var song: Song
    
    var body: some View {
        VStack{
            VideoPlayer(player: AVPlayer(url: song.clips[0]))
            Text(song.title)
        }
 
    }
}

#Preview {
    SongPageView(song: .constant(placeholderSong))
        .modelContainer(for: Song.self, inMemory: true)
}
