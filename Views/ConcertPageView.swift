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
    @Environment(\.dismiss) private var dismiss
    
    @Binding var concert: Concert
    @State var newClip: PhotosPickerItem?
    @State var showErrorAlert: Bool = false
    @State var errorMessage: String = ""
    @State var loadState = LoadState.unknown
    @State private var viewModel = ViewModel()
    @State private var navigateToVideoPlayer = false
    @State private var savedVideoURL: URL?
    @State private var videoData: Data?
    @State private var isLoading = false
    @State private var showEditSheet = false
    @State private var detectedSong: ShazamMatchResult?

    @ViewBuilder
    private func songsSection() -> some View {
        Section {
            if concert.setlist.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("No songs in the setlist")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text("Tap the plus icon to add a song from a concert clip.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical)
            } else {
                ForEach(concert.setlist.sorted(by: { $0.order < $1.order })) { song in
                    NavigationLink {
                        SongPageView(song: .constant(song))
                    } label: {
                        SongRowWithThumbnail(song: song)
                    }
                }
                .onMove { indices, newOffset in
                    concert.setlist.move(fromOffsets: indices, toOffset: newOffset)
                    for (index, song) in concert.setlist.enumerated() {
                        song.order = index
                    }
                    try? modelContext.save()
                }
            }
        } header: {
            HStack {
                Text("Setlist")
                Spacer()
                EditButton()
            }
        }
        .listRowBackground(Color.white.opacity(0.1))
    }
    
    @ViewBuilder
    private func infoSection() -> some View {
        Section("Information") {
            LabeledContent {
                Text(concert.artist)
            } label: {
                Text("Artist")
            }
            LabeledContent {
                Text(concert.city)
            } label: {
                Text("City")
            }
            LabeledContent {
                Text(concert.date.formatted(date: .long, time: .omitted))
            } label: {
                Text("Date")
            }
        }.listRowBackground(Color.white.opacity(0.1))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    infoSection()
                    if (concert.isInFuture()){
                        Section {
                            VStack(alignment: .center, spacing: 12){
                                Image(systemName: "calendar")
                                    .foregroundColor(.secondary)
                                    .scaleEffect(3.0).padding()
                                Text("This concert is in \(concert.daysTo()) days, get excited!").foregroundStyle(.secondary).padding()
                            }.frame(maxWidth: .infinity, alignment: .center).padding().padding(.top)
                        }.listRowBackground(Color.white.opacity(0.1))
                    } else {
                        songsSection()
                    }
                }
                .scrollContentBackground(.hidden)
                .background(
                    LinearGradient(
                        colors: [
                            concert.color.opacity(0.3),
                            concert.color.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .navigationTitle(concert.tour)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showEditSheet = true }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .foregroundColor(.primary)
                }
                if (!concert.isInFuture())
                {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        PhotosPicker(selection: $newClip, matching: .videos) {
                            Image(systemName: "plus.circle.fill").font(.title3).symbolRenderingMode(.hierarchical)
                        }
                        .onChange(of: newClip) { _, newSelectedVideo in
                            if let video = newSelectedVideo {
                                Task {
                                    newClip = nil
                                    await loadVideoForDetection(newSelectedVideo: video)
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                ConcertCreationSheet(showConcertCreationSheet: $showEditSheet, concert: concert)
            }
            .fullScreenCover(isPresented: $navigateToVideoPlayer) {
                if let videoURL = savedVideoURL, let data = videoData {
                    VideoDetectionView(
                        videoURL: videoURL,
                        videoData: data,
                        concert: $concert,
                        onSongDetected: { result in
                            self.detectedSong = result
                            navigateToVideoPlayer = false
                        }
                    )
                }
            }
            .sheet(item: $detectedSong) { result in
                if let videoURL = savedVideoURL {
                    SongCreationSheet(
                        concert: concert,
                        videoData: videoData,
                        videoURL: videoURL,
                        detectedSong: result
                    )
                }
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.7)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            Text("Processing video...")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.3))
                        .cornerRadius(10)
                    }
                    .transition(.opacity)
                }
            }
        }
    }
    
    @MainActor
    private func loadVideoForDetection(newSelectedVideo: PhotosPickerItem?) async {
        do {
            loadState = .loading
            isLoading = true
            
            guard let selectedVideo = newSelectedVideo else {
                loadState = .failed("No video selected")
                isLoading = false
                showError("No video selected")
                return
            }
            
            guard let movieData = try await selectedVideo.loadTransferable(type: Data.self) else {
                loadState = .failed("Failed to load video data")
                isLoading = false
                showError("Failed to load video data")
                return
            }
            
            loadState = .loaded
            self.videoData = movieData
            
            // Save the video first
            if let savedURL = try? await saveVideoToFile(movieData) {
                self.savedVideoURL = savedURL
                self.navigateToVideoPlayer = true
                isLoading = false
            } else {
                isLoading = false
                showError("Failed to save video")
            }
        } catch {
            loadState = .failed(error.localizedDescription)
            isLoading = false
            showError("Error: \(error.localizedDescription)")
        }
    }
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    private func saveVideoToFile(_ data: Data) async throws -> URL {
        // Create a file URL in the documents directory
        let contentType = newClip?.supportedContentTypes.first
        let url = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).\(contentType?.preferredFilenameExtension ?? "mp4")")
        
        // Write data to the URL
        try data.write(to: url)
        print("Saved clip to \(url.path)")
        return url
    }
    
    // Helper function to get the documents directory
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Concert.self, configurations: config)
        
        // Create a sample concert with some songs
        let sampleConcert = Concert(
            date: .now,
            artist: "Taylor Swift",
            tour: "Eras Tour",
            city: "Tokyo",
            colorHex: "FF1493"  // Deep pink color
        )
        
        // Add some sample songs to the setlist
        sampleConcert.setlist.append(Song(title: "Cruel Summer", artist: "Taylor Swift", order: 0))
        sampleConcert.setlist.append(Song(title: "Anti-Hero", artist: "Taylor Swift", order: 1))
        sampleConcert.setlist.append(Song(title: "Love Story", artist: "Taylor Swift", order: 2))
        sampleConcert.setlist.append(Song(title: "Shake It Off", artist: "Taylor Swift", order: 3))
        
        return NavigationStack {
            ConcertPageView(concert: .constant(sampleConcert))
                .modelContainer(container)
        }
        .preferredColorScheme(.dark)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
