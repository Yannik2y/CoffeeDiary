import SwiftUI
import UIKit

/// Decodes and caches a thumbnail-sized image so list rows don't re-decode full JPEGs every redraw.
struct CachedThumbnailImage: View {
    let data: Data?
    var maxDimension: CGFloat = 200
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?

    var body: some View {
        // Color.clear keeps the view in the hierarchy while decoding; an empty conditional
        // would never appear, so `.task` would not run (e.g. inside `.overlay`).
        Color.clear
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                }
            }
            .clipped()
            .task(id: data?.count) {
                guard let data else {
                    image = nil
                    return
                }
                let dimension = maxDimension
                image = await Task.detached(priority: .userInitiated) {
                    PhotoStorage.thumbnailImage(from: data, maxDimension: dimension)
                }.value
            }
    }
}
