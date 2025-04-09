//
//  SongCreationSheet.swift
//  Barricade
//
//  Created by Michael Banna on 2025-04-08.
//

import SwiftUI
import SwiftData

struct SongCreationSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var concerts: [Concert]
    let videoData: Data?
    let videoURL: URL?
    let detectedSong: ShazamMatchResult?
    
    @State private var songTitle: String
    @State private var artistName: String
    @State private var selectedConcert: Concert?
    @State private var showNewConcertSheet = false
    
    @Environment(\.dismiss) private var dismiss
    
    private var concertIsInitiallySelected: Bool = false
    
    init(
        concert: Concert? = nil,
        videoData: Data?,
        videoURL: URL?,
        detectedSong: ShazamMatchResult?
    ) {
        self.videoData = videoData
        self.videoURL = videoURL
        self.detectedSong = detectedSong
        
        print("init song creation sheet")
        print("song title: \(detectedSong?.songTitle ?? "")")
        
        _songTitle = State(initialValue: detectedSong?.songTitle ?? "")
        _artistName = State(initialValue: detectedSong?.artist ?? "")
        
        if let concert = concert {
            _selectedConcert = State(initialValue: concert)
            concertIsInitiallySelected = true
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Song Details") {
                    TextField("Song Title", text: $songTitle)
                    TextField("Artist (optional)", text: $artistName)
                    
                    if detectedSong?.isSuccess == false {
                        Text("No song was detected in the video. Please enter the details manually.")
                            .foregroundColor(.secondary)
                    }
                }
                if (!concertIsInitiallySelected) {
                    Section("Concert") {
                        if (concerts.isEmpty) {
                            Button("Create New Concert") {
                                showNewConcertSheet = true
                            }
                        } else {
                            Picker("Select Concert", selection: Binding(
                                get: { selectedConcert?.id },
                                set: { newID in
                                    selectedConcert = concerts.first(where: { $0.id == newID })
                                }
                            )) {
                                Text("Select a concert").tag(Concert.ID?.none)
                                ForEach(concerts) { concert in
                                    Text("\(concert.artist) - \(concert.tour)").tag(Optional(concert.id))
                                }
                            }
                            
                            Button("Or Create New Concert") {
                                showNewConcertSheet = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSongToConcert()
                    }
                    .disabled(songTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedConcert == nil)
                }
            }
            .sheet(isPresented: $showNewConcertSheet) {
                ConcertCreationSheet(
                    showConcertCreationSheet: $showNewConcertSheet,
                    onConcertCreated: { newConcert in
                        selectedConcert = newConcert
                    }
                )
            }
            .onAppear {
                if songTitle.isEmpty {
                    songTitle = detectedSong?.songTitle ?? ""
                    artistName = detectedSong?.artist ?? ""
                    print("Sheet appeared. Synced song title: \(songTitle)")
                }
            }
        }
    }
    
    private func saveSongToConcert() {
        guard let concert = selectedConcert else { return }
        
        Task {
            if let videoData = videoData {
                do {
                    let fileName = "\(UUID().uuidString).mov"
                    let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent(fileName)
                    try videoData.write(to: fileURL)

                    await MainActor.run {
                        let newSong = Song(
                            title: songTitle,
                            artist: artistName,
                            order: 0
                        )
                        
                        // Set order based on setlist count
                        newSong.order = concert.setlist.count

                        newSong.clips.append(fileURL)
                        concert.setlist.append(newSong)

                        try? modelContext.save()
                        dismiss()
                    }
                } catch {
                    print("Failed to save video: \(error)")
                }
            }
        }
    }
}
