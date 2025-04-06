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

    var body: some View {
        NavigationStack {
            VStack {
                // TODO: Insert playback of concert song videos in order
                Form {
                    Section("Setlist") {
                        ForEach(concert.setlist) { song in
                            NavigationLink {
                                SongPageView(song:.constant(song))
                            } label: {
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
                .toolbar {
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
                                    isLoading = true
                                    
                                    if let movieData = try await newClip?.loadTransferable(type: Data.self) {
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
                                    } else {
                                        loadState = .failed("Failed to load video data")
                                        isLoading = false
                                        showError("Failed to load video data")
                                    }
                                } catch {
                                    loadState = .failed(error.localizedDescription)
                                    isLoading = false
                                    showError("Error: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
                .navigationTitle(concert.tour)
                .onAppear {
                    // Make sure the viewModel has a reference to our concert
                    viewModel.setConcert(concert)
                }
            }
            .navigationDestination(isPresented: $navigateToVideoPlayer) {
                if let videoURL = savedVideoURL, let data = videoData {
                    VideoDetectionView(
                        videoURL: videoURL,
                        videoData: data,
                        concert: $concert,
                        modelContext: modelContext
                    )
                } else {
                    Text("Error loading video")
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {
                    showErrorAlert = false
                }
            } message: {
                Text(errorMessage)
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
