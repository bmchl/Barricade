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
import ShazamKit


struct ConcertPageView: View {
    enum LoadState {
        case unknown, loading, loaded, failed(String)
    }
    @Environment(\.modelContext) private var modelContext
    
    @Binding var concert: Concert
    @State var newClip: PhotosPickerItem?
    @State var showClipNameAlert: Bool = false
    @State var showErrorAlert: Bool = false
    @State var errorMessage: String = ""
    @State var songName: String = ""
    @State private var loadState = LoadState.unknown
    @State private var viewModel = ViewModel()
    @State private var isShazamming = false
    @State private var detectedSong: String? = nil

    var body: some View {
        NavigationStack{
            ZStack {
                VStack{
                    // TODO: Insert playback of concert song videos in order
                    Form{
                        Section("Setlist"){
                            ForEach(concert.setlist) {
                                song in
                                NavigationLink {SongPageView(song:.constant(song))} label: {
                                    HStack {
                                        Text(song.title)
                                        Spacer()
                                        if !song.artist.isEmpty {
                                            Text(song.artist)
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                        }
                                    }
                                }
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
                                    isShazamming = true

                                    if let movie = try await newClip?.loadTransferable(type: Data.self) {
                                        loadState = .loaded
                                        // Shazam clip
                                        addClipAsync()
                                    } else {
                                        loadState = .failed("Failed to load video data")
                                        isShazamming = false
                                        showError("Failed to load video data")
                                    }
                                } catch {
                                    loadState = .failed(error.localizedDescription)
                                    isShazamming = false
                                    showError("Error: \(error.localizedDescription)")
                                }
                            }
                        }
                        
                    }
                }.navigationTitle(concert.tour)
                .onAppear {
                    // Make sure the viewModel has a reference to our concert
                    viewModel.setConcert(concert)
                }
                
                // Loading overlay
                if isShazamming {
                    ZStack {
                        Color.black.opacity(0.7)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            Text(detectedSong == nil ? "Identifying song..." : "Found: \(detectedSong!)")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(2.0)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.3))
                        .cornerRadius(10)
                    }
                    .transition(.opacity)
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {
                    showErrorAlert = false
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    private func addClipAsync() {
          Task {
              await addClip()
          }
      }
    
    private func addClip() async {
        do {
            guard let movieData = try? await newClip?.loadTransferable(type: Data.self) else {
                // Handle the case where loading the movie fails
                loadState = .failed("Failed to load video data")
                isShazamming = false
                showError("Failed to load video data")
                return
            }
            
            var savedURL: URL?
            
            // Save the clip data to a file
            if let contentType = newClip?.supportedContentTypes.first {
                // Create a file URL in the documents directory
                let url = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).\(contentType.preferredFilenameExtension ?? "")")
                
                // Write data to the URL
                do {
                    try movieData.write(to: url)
                    savedURL = url
                    print("Saved clip to \(url.path)")
                } catch {
                    print("Error saving clip: \(error.localizedDescription)")
                    showError("Error saving clip: \(error.localizedDescription)")
                }
            }
            
            // Use ShazamKit to detect the song from the clip
            let detectionResult = await viewModel.processVideoData(movieData, modelContext: modelContext)
            
            // Add the video URL to the song's clips array if detection was successful
            if let result = viewModel.detectionResult, 
               result.isSuccess, 
               let songTitle = result.songTitle,
               let savedURL = savedURL {
                
                // Set detected song name to show in UI
                detectedSong = songTitle
                
                // Wait a moment to show the detected song name
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                // Find the song in the setlist
                if let songIndex = concert.setlist.firstIndex(where: { $0.title == songTitle }) {
                    // Add the clip URL to the song
                    concert.setlist[songIndex].clips.append(savedURL)
                    try? modelContext.save()
                    print("Successfully added clip to song: \(songTitle)")
                }
                
                // Hide loading overlay
                isShazamming = false
            } else if let error = detectionResult.error {
                isShazamming = false
                showError("Song detection failed: \(error.localizedDescription)")
            } else if savedURL != nil {
                isShazamming = false
                showError("Could not identify song in the clip")
            }
            
            // Reset state
            newClip = nil
            loadState = .unknown
        }
    }

    // Helper function to get the documents directory
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

//    #Preview {
//        ConcertPageView(concert: .constant(placeholderConcert))
//            .modelContainer(for: Concert.self, inMemory: true)
//    }
}
