//
//  SongRowWithThumbnail.swift
//  Barricade
//
//  Created by Michael Banna on 2025-04-09.
//

import SwiftUI
import AVFoundation

struct SongRowWithThumbnail: View {
    let song: Song
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .frame(width: 43, height: 60)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 43, height: 60)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.5))
                    )
            }

            VStack(alignment: .leading) {
                Text(song.title)
                    .font(.headline)
                if !song.artist.isEmpty {
                    Text(song.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }

    private func generateThumbnail() {
        guard let clipURL = song.clips.first else { return }
        let asset = AVAsset(url: clipURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            thumbnail = UIImage(cgImage: cgImage)
        } catch {
            print("Thumbnail error: \(error)")
        }
    }
}
