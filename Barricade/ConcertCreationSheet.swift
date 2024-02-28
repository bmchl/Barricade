//
//  ConcertCreationSheet.swift
//  Barricade
//
//  Created by Michael Banna on 2024-02-16.
//

import SwiftUI
import SwiftData

struct ConcertCreationSheet: View {
    @Binding var showConcertCreationSheet: Bool
    @Environment(\.modelContext) private var modelContext
    
    @State var concertArtist: String = ""
    @State var concertDate: Date = Date()
    @State var concertTour: String = ""
    @State var concertCity: String = ""

    var body: some View {
        NavigationStack{
            NavigationView {
                Form {
                    Section(header: Text("General")) {
                        DatePicker("Concert Date", selection: $concertDate, displayedComponents: [.date])
                        TextField("Artist Name", text: $concertArtist)
                        TextField("Tour Name", text: $concertTour)
                        TextField("City Name", text: $concertCity)
                    }
                    
                }
                Section(header: Text("Personalization")) {
                    
                }
            }.toolbar{ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done", action: createConcert)
            }}.navigationTitle("New Concert")
        }
    }
            
    
    
    private func createConcert() {
        let newItem = Concert(date: concertDate, artist: concertArtist, tour: concertTour, city: concertCity)
        modelContext.insert(newItem)
        showConcertCreationSheet = false
    }
}



#Preview {
    ConcertCreationSheet(showConcertCreationSheet: .constant(true))
        .modelContainer(for: Concert.self, inMemory: true)
}
