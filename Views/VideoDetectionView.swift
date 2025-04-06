import SwiftUI
import AVKit
import SwiftData
import ShazamKit

struct VideoDetectionView: View {
    let videoURL: URL
    let videoData: Data
    @Binding var concert: Concert
    let modelContext: ModelContext
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VideoDetectionViewModel()
    @State private var showAlertOnDismiss = false
    @State private var showManualEntrySheet = false
    @State private var manualSongTitle = ""
    @State private var manualArtistName = ""
    
    var body: some View {
        VStack {
            // Video player takes full width and most of the height
            VideoPlayer(player: viewModel.player)
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    VStack {
                        Spacer()
                        if viewModel.isDetecting {
                            Text("Identifying song...")
                                .font(.headline)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                        } else if let songTitle = viewModel.detectedSong {
                            VStack(spacing: 4) {
                                Text("Song detected:")
                                    .font(.subheadline)
                                Text(songTitle)
                                    .font(.headline)
                                if let artist = viewModel.detectedArtist {
                                    Text(artist)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                        } else if viewModel.noMatchFound {
                            VStack(spacing: 8) {
                                Text("No song detected")
                                    .font(.headline)
                                
                                Button("Add Song Manually") {
                                    showManualEntrySheet = true
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                        }
                        Spacer().frame(height: 40)
                    }
                )
        }
        .navigationTitle("Video Player")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    if viewModel.isDetecting {
                        showAlertOnDismiss = true
                    } else {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.setup(videoURL: videoURL)
            viewModel.startDetection(videoData: videoData, concert: concert, modelContext: modelContext)
        }
        .onDisappear {
            viewModel.stopDetection()
        }
        .alert("Song Detection in Progress", isPresented: $showAlertOnDismiss) {
            Button("Cancel", role: .destructive) {
                viewModel.stopDetection()
                dismiss()
            }
            Button("Continue Detection", role: .cancel) {
                // Just close the alert and continue
            }
        } message: {
            Text("Song detection is still running. Do you want to cancel it?")
        }
        .sheet(isPresented: $showManualEntrySheet) {
            NavigationStack {
                Form {
                    Section("Song Details") {
                        TextField("Song Title", text: $manualSongTitle)
                        TextField("Artist (optional)", text: $manualArtistName)
                    }
                }
                .navigationTitle("Add Song Manually")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showManualEntrySheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if !manualSongTitle.isEmpty {
                                viewModel.addManualSong(
                                    title: manualSongTitle,
                                    artist: manualArtistName,
                                    url: videoURL,
                                    concert: concert,
                                    modelContext: modelContext
                                )
                                showManualEntrySheet = false
                            }
                        }
                        .disabled(manualSongTitle.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

class VideoDetectionViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isDetecting = false
    @Published var detectedSong: String?
    @Published var detectedArtist: String?
    @Published var error: Error?
    @Published var noMatchFound = false
    
    private let shazamService = ShazamService.shared
    private var detectionTask: Task<Void, Never>?
    private var videoURL: URL?
    
    func setup(videoURL: URL) {
        self.videoURL = videoURL
        // Don't create a player here, we'll use the one from ShazamService
    }
    
    func startDetection(videoData: Data, concert: Concert, modelContext: ModelContext) {
        isDetecting = true
        
        guard let videoURLForSaving = self.videoURL else {
            print("Error: No video URL available")
            return
        }
        
        detectionTask = Task {
            // Start song detection using ShazamKit
            let (returnedPlayer, result) = await shazamService.matchAudioData(videoData)
            
            // Set the player from ShazamService
            await MainActor.run {
                self.player = returnedPlayer
                isDetecting = false
                
                if result.isSuccess, let songTitle = result.songTitle {
                    self.detectedSong = songTitle
                    self.detectedArtist = result.artist
                    
                    // Save the detected song if it's not already in the setlist
                    if !concert.setlist.contains(where: { $0.title == songTitle }) {
                        let newSong = Song(title: songTitle, artist: result.artist ?? "")
                        newSong.clips.append(videoURLForSaving)
                        concert.setlist.append(newSong)
                        try? modelContext.save()
                    } else if let existingSong = concert.setlist.first(where: { $0.title == songTitle }) {
                        // Add this clip to the existing song
                        if !existingSong.clips.contains(videoURLForSaving) {
                            existingSong.clips.append(videoURLForSaving)
                            try? modelContext.save()
                        }
                    }
                } else {
                    // No match found, show manual entry option
                    self.noMatchFound = true
                    self.error = result.error
                    
                    if let error = result.error {
                        print("Song detection failed: \(error.localizedDescription)")
                    } else {
                        print("No match found for the song")
                    }
                }
            }
        }
    }
    
    func stopDetection() {
        detectionTask?.cancel()
        player?.pause()
        player = nil
        shazamService.stopPlayback()
    }
    
    func addManualSong(title: String, artist: String, url: URL, concert: Concert, modelContext: ModelContext) {
        // Update the view model properties
        self.detectedSong = title
        self.detectedArtist = artist.isEmpty ? nil : artist
        self.noMatchFound = false
        
        // Check if the song already exists in the setlist
        if !concert.setlist.contains(where: { $0.title == title }) {
            // Create a new song with the provided details
            let newSong = Song(title: title, artist: artist)
            newSong.clips.append(url)
            concert.setlist.append(newSong)
        } else if let existingSong = concert.setlist.first(where: { $0.title == title }) {
            // Add this clip to the existing song
            if !existingSong.clips.contains(url) {
                existingSong.clips.append(url)
            }
        }
        
        // Save to the database
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        VideoDetectionView(
            videoURL: URL(string: "https://example.com/video.mp4")!,
            videoData: Data(),
            concert: .constant(placeholderConcert),
            modelContext: ModelContext(try! ModelContainer(for: Concert.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        )
    }
} 