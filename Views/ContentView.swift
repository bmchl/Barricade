//
//  ContentView.swift
//  Barricade
//
//  Created by Michael Banna on 2024-02-15.
//

import SwiftUI
import SwiftData
import PhotosUI


enum SortOption {
    case date
    case artist
    case city
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Concert]
    @State private var showConcertCreationSheet = false
    @State private var concertType = 0
    @State private var sortOption = SortOption.date
    
    var sortedItems: [Concert] {
        switch sortOption {
        case .date:
            return items.sorted { $0.date > $1.date }
        case .artist:
            return items.sorted { ($0.artist, $0.tour) < ($1.artist, $1.tour) }
        case .city:
            return items.sorted { $0.city < $1.city }
        }
    }
   
    var body: some View {
        TabView {
            ConcertsTab(
                items: sortedItems,
                concertType: $concertType,
                sortOption: $sortOption,
                showConcertCreationSheet: $showConcertCreationSheet
            )
            .tabItem {
                Label("Concerts", systemImage: "ticket")
            }
            
            SongsGridView()
                .tabItem {
                    Label("Songs", systemImage: "music.note.list")
                }
        }
        .sheet(isPresented: $showConcertCreationSheet) {
            ConcertCreationSheet(showConcertCreationSheet: $showConcertCreationSheet)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

import SwiftUI
import SwiftData

struct ConcertsTab: View {
    let items: [Concert]
    @Binding var concertType: Int
    @Binding var sortOption: SortOption
    @Binding var showConcertCreationSheet: Bool
    
    @Environment(\.modelContext) private var modelContext

    private var filteredConcerts: [Concert] {
        if concertType == 0 {
            return items.filter { !$0.isInFuture() }
        } else {
            return items.filter { $0.isInFuture() }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Picker("Concert Type", selection: $concertType) {
                        Text("Past").tag(0)
                        Text("Upcoming").tag(1)
                    }
                    .pickerStyle(.segmented)

                    Picker("Sort By", selection: $sortOption) {
                        Text("Date").tag(SortOption.date)
                        Text("Artist").tag(SortOption.artist)
                        Text("City").tag(SortOption.city)
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)

                if filteredConcerts.isEmpty {
                    GeometryReader { geo in
                        VStack(spacing: 16) {
                            Image(systemName: "ticket")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.white.opacity(0.6))

                            Text("No concerts yet")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)

                            Text("Tap the plus icon to add your first concert.")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                } else {
                    ScrollView {
                        ForEach(filteredConcerts) { item in
                            VStack {
                                NavigationLink {
                                    ConcertPageView(concert: .constant(item))
                                } label: {
                                    ConcertItemView(concert: .constant(item))
                                }
                                .padding(.horizontal)
                                .padding(.top, 5)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteConcert(item)
                                    } label: {
                                        Label("Delete Concert", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .background(.barricadeBackground)
            .frame(maxWidth: .infinity, alignment: .center)
            .toolbar {
                ToolbarItem {
                    Button(action: { showConcertCreationSheet = true }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Concerts")
        }
    }

    private func deleteConcert(_ concert: Concert) {
        modelContext.delete(concert)
        try? modelContext.save()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Concert.self, configurations: config)

    // Add our diverse placeholder concerts
    for concert in placeholderConcerts {
        container.mainContext.insert(concert)
    }
    
    return ContentView()
        .modelContainer(container)
}
