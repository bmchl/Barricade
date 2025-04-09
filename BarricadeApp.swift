//
//  BarricadeApp.swift
//  Barricade
//
//  Created by Michael Banna on 2024-02-15.
//

import SwiftUI
import SwiftData

@main
struct BarricadeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Concert.self,
            Song.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView().preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
    
}
