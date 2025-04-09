//
//  VideoDetectionView.swift
//  Barricade
//
//  Created by Michael Banna on 2025-04-08.
//

import SwiftUI
import AVKit
import SwiftData
import ShazamKit

struct VideoDetectionView: View {
    let videoURL: URL
    let videoData: Data
    @Binding var concert: Concert
    var onSongDetected: ((ShazamMatchResult) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ViewModel()
    @State private var showAlertOnDismiss = false
    @State private var showManualEntrySheet = false
    @State private var manualSongTitle = ""
    @State private var manualArtistName = ""
    
    var body: some View {
        VStack {
            VideoPlayer(player: viewModel.player)
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    Group {
                        if viewModel.isDetecting {
                            // Transparent touch-blocking overlay
                            Color.black.opacity(0.001)
                                .allowsHitTesting(true)
                        }
                    }
                )
                .overlay(
                    VStack(alignment: .leading) {
                        Spacer()
                        ZStack(alignment: .leading) {
                            if viewModel.isDetecting {
                                identifyingSongView()
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            } else if let songTitle = viewModel.detectedSong {
                                matchFoundView(songTitle: songTitle, artist: viewModel.detectedArtist)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            } else if viewModel.noMatchFound {
                                noMatchFoundView()
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding()
                        .background(.barricadeDark)
                        .cornerRadius(30)
                        .padding(.horizontal)
                        .animation(.easeInOut(duration: 0.35), value: viewModel.isDetecting || viewModel.detectedSong != nil || viewModel.noMatchFound)
                        
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
            viewModel.startDetection(
                videoData: videoData,
                concert: concert,
                onSongDetected: onSongDetected
            )
        }
        .onDisappear {
            viewModel.stopDetection()
        }
    }
    
    func identifyingSongView() -> some View {
        HStack(alignment:.center) {
            VStack(alignment: .leading) {
                Label("Volume up!", systemImage: "speaker.wave.3.fill")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("Identifying song...")
                    .font(.title).fontWeight(.bold)
            }
            Spacer()
            ProgressView().scaleEffect(2.0).frame(width: 80, height: 80)
        }.frame(maxWidth: .infinity)
    }
    
    func matchFoundView(songTitle: String, artist: String?) -> some View {
        VStack{
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Label("Match found!", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text(songTitle)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let artist = artist {
                        Text(artist)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let artworkURL = viewModel.currentMatchResult?.artworkURL {
                    AsyncImage(url: artworkURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .cornerRadius(10)
                        case .failure(_):
                            EmptyView()
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            
            Button(action: {
                print("current result")
                print("song: \(viewModel.currentMatchResult?.songTitle ?? "none")")
                if let result = viewModel.currentMatchResult {
                    onSongDetected?(result)
                }
                dismiss()
            }) {
                Label("Confirm & Continue", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.barricadeDark)
                    .font(.headline)
                    .padding()
                    .background(.accent)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }.frame(maxWidth: .infinity)
    }
    
    func noMatchFoundView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No match found", systemImage: "xmark.circle.fill")
                .font(.headline)
                .foregroundColor(.red)
            
            Text("Try adding manually")
                .font(.title)
                .fontWeight(.bold)
            
            Button(action: {
                if let result = viewModel.currentMatchResult {
                    onSongDetected?(result)
                }
                dismiss()
            }) {
                Label("Continue", systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor2)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }.frame(maxWidth: .infinity)
    }
}



#Preview {
    NavigationStack {
        VideoDetectionView(
            videoURL: URL(string: "https://example.com/video.mp4")!,
            videoData: Data(),
            concert: .constant(placeholderConcert))
    }
}
