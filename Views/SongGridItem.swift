import SwiftUI
import SwiftData
import AVKit
import PhotosUI

struct SongGridItem: View {
    let song: Song
    @State private var thumbnail: UIImage?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fill)
                    .frame(maxWidth: .infinity) 
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(2/3, contentMode: .fill)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.5))
                    )
            }

            Color.clear
                .background(.ultraThinMaterial)
                .blur(radius: 10)
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black, location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)

                if !song.artist.isEmpty {
                    Text(song.artist)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }
            }
            .padding(8)
        }
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button(role: .destructive) {
                deleteSong()
            } label: {
                Label("Delete Song", systemImage: "trash")
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }

    private func deleteSong() {
        if let concert = song.concert {
            concert.setlist.removeAll { $0.id == song.id }
            try? modelContext.save()
        }
    }

    private func generateThumbnail() {
        guard let firstClipURL = song.clips.first else { return }

        guard FileManager.default.fileExists(atPath: firstClipURL.path) else {
            print("Video file not found, deleting song")
            deleteSong()
            return
        }

        let asset = AVAsset(url: firstClipURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            thumbnail = UIImage(cgImage: cgImage)
        } catch {
            print("Failed to generate thumbnail: \(error)")
            deleteSong()
        }
    }
}
