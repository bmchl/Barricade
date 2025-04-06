//
//  ConcertCreationSheet.swift
//  Barricade
//
//  Created by Michael Banna on 2024-02-16.
//

import SwiftUI
import SwiftData

struct ConcertCreationSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showConcertCreationSheet: Bool
    @State private var viewModel = ViewModel()


    var body: some View {
        NavigationStack{
            NavigationView {
                Form {
                    Section(header: Text("General")) {
                        DatePicker("Concert Date", selection: $viewModel.concertDate, displayedComponents: [.date])
                        TextField("Artist Name", text: $viewModel.artist)
                        TextField("Tour Name", text: $viewModel.tour)
                        TextField("City Name", text: $viewModel.city)
                    }
                    
                }
                Section(header: Text("Personalization")) {
                    
                }
            }.toolbar{ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done", action: {
                    viewModel.createConcert(modelContext: modelContext)
                    showConcertCreationSheet = false})
            }}.navigationTitle("New Concert")
        }
    }
}



#Preview {
    ConcertCreationSheet(showConcertCreationSheet: .constant(true))
        .modelContainer(for: Concert.self, inMemory: true)
}
