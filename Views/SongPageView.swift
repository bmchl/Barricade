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
    @Environment(\.dismiss) private var dismiss
    @Binding var song: Song
    @StateObject private var playerModel = PlayerModel()
    @State private var showDeleteConfirmation = false
    @State private var isPlayerReady = false

    var body: some View {
        VStack {
            if let clipURL = song.clips.first {
                Group {
                    if let player = playerModel.player {
                        FullscreenVideoPlayer(player: player)
                            .aspectRatio(9/16, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .frame(maxWidth: .infinity, maxHeight: 700)
                    } else {
                        ProgressView()
                            .frame(height: 300)
                    }
                }
                .onAppear {
                    if playerModel.player == nil {
                        playerModel.configureAudioSession()
                        playerModel.loadVideo(url: clipURL)
                    }
                }
                .onDisappear {
                    playerModel.cleanup()
                }
            } else {
                Text("No video clips available")
                    .foregroundColor(.secondary)
                    .padding()
            }

            if let concert = song.concert {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(song.title)
                            .font(.title2.bold())

                        if !song.artist.isEmpty {
                            Text(song.artist)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(concert.tour)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(concert.city)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text(concert.date.formatted(date: .long, time: .omitted))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.barricadeDark)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Delete Song", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSong()
            }
        } message: {
            Text("Are you sure you want to delete this song? This action cannot be undone.")
        }
    }

    private func deleteSong() {
        if let concert = song.concert {
            concert.setlist.removeAll { $0.id == song.id }
            try? modelContext.save()
        }
        dismiss()
    }
}

// ViewModel for handling video playback
class PlayerModel: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    @Published var player: AVPlayer?
    @Published var isPictureInPictureActive = false

    private var playerLayer: AVPlayerLayer?
    private var pictureInPictureController: AVPictureInPictureController?

    func loadVideo(url: URL) {
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        setupPictureInPicture()
        player?.play()
    }

    func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }

    func setupPictureInPicture() {
        guard let playerLayer = playerLayer,
              AVPictureInPictureController.isPictureInPictureSupported() else { return }

        pictureInPictureController = AVPictureInPictureController(playerLayer: playerLayer)
        pictureInPictureController?.delegate = self
        pictureInPictureController?.canStartPictureInPictureAutomaticallyFromInline = true
    }

    func cleanup() {
        player?.pause()
        player = nil
        pictureInPictureController = nil
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }

    // MARK: - PiP Delegate
    func pictureInPictureControllerWillStartPictureInPicture(_ controller: AVPictureInPictureController) {
        DispatchQueue.main.async {
            self.isPictureInPictureActive = true
        }
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ controller: AVPictureInPictureController) {
        DispatchQueue.main.async {
            self.isPictureInPictureActive = false
        }
    }
}

struct FullscreenVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.entersFullScreenWhenPlaybackBegins = false
        controller.exitsFullScreenWhenPlaybackEnds = true
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

#Preview {
    SongPageView(song: .constant(placeholderSong))
        .modelContainer(for: Song.self, inMemory: true)
}
