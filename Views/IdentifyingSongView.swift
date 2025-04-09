//
//  IdentifyingSongView.swift
//  Barricade
//
//  Created by Michael Banna on 2025-04-08.
//

import SwiftUI

struct IdentifyingSongView: View {
    var body: some View {
        VStack(alignment: .leading){
            Label ("Volume up!", systemImage: "speaker.wave.3.fill")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Identifying song...")
                .font(.title).fontWeight(.bold)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    IdentifyingSongView()
}
