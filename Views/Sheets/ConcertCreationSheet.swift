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
    @State private var viewModel: ViewModel
    var onConcertCreated: ((Concert) -> Void)?
    
    @MainActor
    init(showConcertCreationSheet: Binding<Bool>, concert: Concert? = nil, onConcertCreated: ((Concert) -> Void)? = nil) {
        self._showConcertCreationSheet = showConcertCreationSheet
        self.onConcertCreated = onConcertCreated
        // Initialize viewModel with existing concert data if editing
        if let concert = concert {
            self._viewModel = State(initialValue: ViewModel(concert: concert))
        } else {
            self._viewModel = State(initialValue: ViewModel())
        }
    }

    private var isFormValid: Bool {
        !viewModel.artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.tour.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("General")) {
                    DatePicker("Concert Date", selection: $viewModel.concertDate, displayedComponents: [.date])
                    
                    TextField("Artist", text: $viewModel.artist)
                    
                    TextField("Tour", text: $viewModel.tour)
                        .textInputAutocapitalization(.words)
                    
                    TextField("City", text: $viewModel.city)
                        .textInputAutocapitalization(.words)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if viewModel.previousCities.isEmpty {
                                Text("No previous cities")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                            } else {
                                ForEach(viewModel.previousCities, id: \.self) { city in
                                    Button(action: {
                                        viewModel.city = city
                                    }) {
                                        Text(city)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .fill(viewModel.city == city ? Color.accentColor2
                                                        : Color.secondary.opacity(0.2))
                                            )
                                            .foregroundColor(viewModel.city == city ? .white : .primary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Personalization")) {
                    VStack(alignment: .leading) {
                        TextField("Nickname (optional)", text: $viewModel.nickname)
                            .font(.body)
                        
                        Text("Concert Color")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.colorOptions, id: \.self) { color in
                                    ColorCircleView(
                                        color: color,
                                        isSelected: viewModel.selectedColor == color
                                    )
                                    .onTapGesture {
                                        viewModel.selectedColor = color
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(.barricadeBackground)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.saveChanges(modelContext: modelContext)
                        if !viewModel.isEditing {
                            // Get the newly created concert
                            let descriptor = FetchDescriptor<Concert>(
                                sortBy: [SortDescriptor(\Concert.date, order: .reverse)]
                            )
                            if let newConcert = try? modelContext.fetch(descriptor).first {
                                onConcertCreated?(newConcert)
                            }
                        }
                        showConcertCreationSheet = false
                    }
                    .disabled(!isFormValid)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showConcertCreationSheet = false
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Concert" : "New Concert")
            .onAppear {
                // Update the modelContext when the view appears
                if !viewModel.isEditing {
                    viewModel.updateModelContext(modelContext)
                }
            }
        }
    }
}

struct ColorCircleView: View {
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .shadow(radius: 2)
            
            if isSelected {
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .bold))
            }
        }
    }
}

#Preview {
    ConcertCreationSheet(showConcertCreationSheet: .constant(true))
        .modelContainer(for: Concert.self, inMemory: true)
}
