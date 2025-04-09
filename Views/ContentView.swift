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

struct ConcertsTab: View {
    let items: [Concert]
    @Binding var concertType: Int
    @Binding var sortOption: SortOption
    @Binding var showConcertCreationSheet: Bool
    
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
                
                ScrollView {
                    if concertType == 0 {
                        ForEach(items) { item in
                            if !item.isInFuture() {
                                VStack {
                                    NavigationLink {
                                        ConcertPageView(concert: .constant(item))
                                    } label: {
                                        ConcertItemView(concert: .constant(item))
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 5)
                                }
                            }
                        }
                    } else {
                        ForEach(items) { item in
                            if item.isInFuture() {
                                VStack {
                                    NavigationLink {
                                        ConcertPageView(concert: .constant(item))
                                    } label: {
                                        ConcertItemView(concert: .constant(item))
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 5)
                                }
                            }
                        }
                    }
                }
            }
            .background(.barricadeBackground)
            .frame(maxWidth: .infinity, alignment: .center)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showConcertCreationSheet = true }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Concerts")
        }
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
