//
//  SongInfoSheet.swift
//  Barricade
//
//  Created by Michael Banna on 2025-04-08.
//


import SwiftUI

struct SongInfoSheet: View {
    let song: Song

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let isExpanded = height > 140

            ZStack {
                // Background with blur and tint
                Color.barricadeDark.opacity(0.6)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()

                // Foreground content
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title)
                            .font(.title2.bold())

                        if !song.artist.isEmpty {
                            Text("\(song.artist) • \(song.concert?.tour ?? "")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    if isExpanded {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("DATE")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(song.concert?.date.formatted(date: .long, time: .omitted) ?? "-")
                                    .font(.body)
                            }

                            Spacer()

                            VStack(alignment: .leading) {
                                Text("LOCATION")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(song.concert?.city ?? "-")
                                    .font(.body)
                            }
                        }

                        if !song.link.isEmpty {
                            Button("Play on Music") {
                                if let url = URL(string: song.link) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
                        }
                    }

                    Spacer()
                }
                .padding()
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
        }
    }
}
#Preview {
    VStack {
        Text("Preview")
    }.sheet(isPresented: .constant(true)){
        SongPageView(song: .constant(placeholderSong))
            .modelContainer(for: Song.self, inMemory: true)
            .presentationDetents([.height(100), .medium])
            .presentationBackgroundInteraction(.enabled)
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(true)
    }
}
