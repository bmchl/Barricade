//
//  ConcertPageView.swift
//  Barricade
//
//  Created by Michael Banna on 2024-02-16.
//

import SwiftUI
import SwiftData
import PhotosUI
import AVKit

// https://www.hackingwithswift.com/quick-start/swiftui/how-to-let-users-import-videos-using-photospicker
struct Movie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "movie.mp4")

            if FileManager.default.fileExists(atPath: copy.path()) {
                try FileManager.default.removeItem(at: copy)
            }

            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
}

struct ConcertPageView: View {
    enum LoadState {
           case unknown, loading, loaded(Movie), failed
       }
    @Environment(\.modelContext) private var modelContext
    
    @Binding var concert: Concert
    @State var newClip: PhotosPickerItem?
    @State var showClipNameAlert: Bool = false
    @State var songName: String = ""
    @State private var loadState = LoadState.unknown

    var body: some View {
        NavigationStack{
            
            VStack{
                Text("insert playback here")
                Form{
                    Section("Setlist"){
                        ForEach(concert.setlist) {
                            song in
                            NavigationLink {SongPageView(song:.constant(song))} label: {
                                Text(song.title)}
                        }
                    }
                }
            }.toolbar {
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    PhotosPicker(selection: $newClip, matching: .videos) {
                        Label("Add Item", systemImage: "plus")
                        
                    }.onChange(of: newClip) { newSelectedVideo, _ in
                        Task {
                                        do {
                                            loadState = .loading

                                            if let movie = try await newClip?.loadTransferable(type: Movie.self) {
                                                loadState = .loaded(movie)
                                                showClipNameAlert = true
                                            } else {
                                                loadState = .failed
                                            }
                                        } catch {
                                            loadState = .failed
                                        }
                                    }
                    }
                    
                }
            }.navigationTitle(concert.tour)
                .alert("Enter song name", isPresented:$showClipNameAlert) {
                    TextField("Enter song name", text: $songName)
                    Button("OK", action: addClipAsync)
                }
        }
    }
    
    private func addClipAsync() {
          Task {
              await addClip()
          }
      }
    
    private func addClip() async {
        do {
            guard let movie = try? await newClip?.loadTransferable(type: Movie.self) else {
                // Handle the case where loading the movie fails
                loadState = .failed
                return
            }
            
            let fileName = "\(Int(Date().timeIntervalSince1970)).\(movie.url.pathExtension)"
                            // create new URL
                            let newUrl = URL(fileURLWithPath: NSTemporaryDirectory() + fileName)
                            // copy item to APP Storage
            try? FileManager.default.copyItem(at: movie.url, to: newUrl)
            
            // Check if the song name already exists in the setlist
            if let existingSongIndex = concert.setlist.firstIndex(where: { $0.title == songName }) {
                // Song already exists, add the clip to its clips array
                concert.setlist[existingSongIndex].clips.append(newUrl)
            } else {
                // Song doesn't exist, create a new song and add it to the setlist
                let newSong = Song(title: songName)
                newSong.clips.append(newUrl)
                concert.setlist.append(newSong)
            }
            
            // Optionally reset state
            newClip = nil
            songName = ""
            showClipNameAlert = false
        }
    }

    
//    #Preview {
//        ConcertPageView(concert: .constant(placeholderConcert))
//            .modelContainer(for: Concert.self, inMemory: true)
//    }
}
