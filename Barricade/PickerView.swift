//
//  PickerView.swift
//  Barricade
//
//  Created by Michael Banna on 2024-02-15.
//

import SwiftUI
import PhotosUI
import AVFoundation

class ImageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}

struct PickerView: View {
    @State private var selectedVideo: PhotosPickerItem?
    @State private var thumbnails: [UIImage] = []

    var body: some View {
        VStack {
            PhotosPicker(selection: $selectedVideo, matching: .videos) {
                Text("Hello, World!")
            }.onChange(of: selectedVideo) { newSelectedVideo, _ in
            }

            List {
                ForEach(thumbnails, id: \.self) { thumbnail in
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100) // Adjust as needed
                        .cornerRadius(8) // Optional: Add corner radius for rounded corners
                        .padding(8) // Optional: Add padding between images
                }
            }
        }
    }

}

struct PickerView_Previews: PreviewProvider {
    static var previews: some View {
        PickerView()
    }
}
