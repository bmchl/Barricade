//
//  ContentView.swift
//  Barricade
//
//  Created by Michael Banna on 2024-02-15.
//

import SwiftUI
import SwiftData
import PhotosUI


struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Concert]
    @State private var showConcertCreationSheet = false
    @State private var concertType = 0
    
   
    var body: some View {
    

            NavigationStack {
                
                VStack {
                       Picker("Concert Type", selection: $concertType) {
                           Text("Past").tag(0)
                           Text("Upcoming").tag(1)
                       }.pickerStyle(.segmented).padding()
                       if concertType == 0 {
                           List {
                               ForEach(items) {
                                   item in !item.isInFuture() ? 
                                   NavigationLink {ConcertPageView(concert: .constant(item))} label: {
                                       ConcertItemView(concert: .constant(item))} : nil
                               }.onDelete(perform: deleteItems)
                           }
                       } else {
                           List {
                               ForEach(items) {
                                   item in item.isInFuture() ? NavigationLink {} label: {
                                       ConcertItemView(concert: .constant(item))} : nil
                               }.onDelete(perform: deleteItems)
                           }
                       }
                   }
                
                .toolbar {
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                            
                        }
                    }
                }.navigationTitle("Concerts")
                    .sheet(isPresented: $showConcertCreationSheet) {
                        ConcertCreationSheet(showConcertCreationSheet: $showConcertCreationSheet)
                    }
            }
    
      
        
    }

    private func addItem() {
        showConcertCreationSheet = true
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
       let container = try! ModelContainer(for: Concert.self, configurations: config)

       for i in 1..<10 {
           let concert = placeholderConcert
           container.mainContext.insert(concert)
       }
    
    return ContentView()
        .modelContainer(container)
}
