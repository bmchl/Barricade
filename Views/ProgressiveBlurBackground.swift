//
//  ProgressiveBlurBackground.swift
//  Barricade
//
//  Created by Michael Banna on 2025-04-08.
//

import SwiftUI

struct ProgressiveBlurBackground: View {
    var body: some View {
        Color.clear
            .background(.ultraThinMaterial)
            .blur(radius: 10)
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}
