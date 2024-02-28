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
        
        HStack{
            VStack(alignment: .leading){
                Text(concert.tour).font(.headline)
                Text(concert.artist)
            }
            Spacer()
            VStack{
                if (concert.isInFuture()){
                    Text("in")
                    Text("\(concert.daysTo())")
                    Text("days")
                }
                else{
                    Text("\(concert.daysTo())")
                    Text("days ago")
                }
            }
        }
       
    }
}

#Preview {
    ConcertItemView(concert: .constant(placeholderConcert))
        .modelContainer(for: Concert.self, inMemory: true)
}
