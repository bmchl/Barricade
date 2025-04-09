//
//  ConcertItemView.swift
//  Barricade
//
//  Created by Michael Banna on 2024-02-16.
//

import SwiftUI
import SwiftData

struct ConcertItemView: View {
    @Environment(\.modelContext) private var modelContext

    @Binding var concert: Concert
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(concert.tour)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(concert.artist)
                    .foregroundColor(.white.opacity(0.9))
            }
            Spacer()
            VStack {
                if concert.isInFuture() {
                    Text("in")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                    Text("\(concert.daysTo())")
                        .font(.title3)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Text("days")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                } else {
                    Text("\(concert.daysTo())")
                        .font(.title3)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Text("days ago")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(concert.color.gradient)
            .shadow(radius: 2))
            
    }
}

#Preview {
    ConcertItemView(concert: .constant(placeholderConcerts[0]))
        .modelContainer(for: Concert.self, inMemory: true)
}
