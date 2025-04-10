import SwiftUI
import SwiftData
import AVKit
import PhotosUI

struct SongsGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var concerts: [Concert]
    @State private var newClip: PhotosPickerItem?
    @State private var videoData: Data?
    @State private var videoURL: URL?
    @State private var detectedSong: ShazamMatchResult?
    @State private var showVideoDetection = false
    @State private var isLoading = false
    
    // Computed property to get all songs with clips
    private var songsWithClips: [Song] {
        concerts.flatMap { $0.setlist }.filter { !$0.clips.isEmpty }
    }
    
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if songsWithClips.isEmpty {
                    VStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "music.note.list")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.white.opacity(0.6))

                            Text("No songs yet")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)

                            Text("Tap the plus icon to add a video and detect a song.")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)

                        Spacer()
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(songsWithClips, id: \.id) { song in
                            NavigationLink {
                                SongPageView(song: .constant(song))
                            } label: {
                                SongGridItem(song: song)
                            }
                        }
                    }
                    .padding()
                }
            }
            .frame(maxHeight: .infinity)
            .background(.barricadeBackground)
            .navigationTitle("Songs")
            .toolbar {
                ToolbarItem {
                    PhotosPicker(selection: $newClip, matching: .videos) {
                        Image(systemName: "plus.circle.fill").font(.title3).symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .onChange(of: newClip) { _, newValue in
                if let newValue {
                    newClip = nil
                    handleVideoSelection(newValue)
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
        .fullScreenCover(isPresented: $showVideoDetection) {
            if let videoURL = videoURL, let data = videoData {
                VideoDetectionView(
                    videoURL: videoURL,
                    videoData: data,
                    concert: .constant(Concert(
                        date: .now,
                        artist: "",
                        tour: "",
                        city: "",
                        colorHex: "FF6B6B"
                    )),
                    onSongDetected: { result in
                        self.detectedSong = result
                        self.showVideoDetection = false
                    }
                )
            }
        }
        .sheet(item: $detectedSong) { result in
            if let videoURL = videoURL {
                SongCreationSheet(
                    videoData: videoData,
                    videoURL: videoURL,
                    detectedSong: result
                )
            }
        }
    }
    
    private func handleVideoSelection(_ videoItem: PhotosPickerItem) {
        Task {
            isLoading = true
            do {
                // Load video data
                let data = try await videoItem.loadTransferable(type: Data.self)
                guard let videoData = data else {
                    isLoading = false
                    return
                }
                self.videoData = videoData
                
                // Save to temporary file for detection
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                try videoData.write(to: tempURL)
                self.videoURL = tempURL
                
                // Show video detection view
                await MainActor.run {
                    isLoading = false
                    showVideoDetection = true
                }
            } catch {
                print("Failed to load video: \(error)")
                isLoading = false
            }
        }
    }
}

#Preview {
    SongsGridView()
        .modelContainer(for: Concert.self, inMemory: true)
}
