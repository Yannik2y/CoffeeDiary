import SwiftUI
import UIKit

/// Decodes and caches a thumbnail-sized image so list rows don't re-decode full JPEGs every redraw.
struct CachedThumbnailImage: View {
    let data: Data?
    /// Stable identity for cache invalidation (preferred over hashing full JPEG bytes).
    var cacheId: String? = nil
    var maxDimension: CGFloat = 200
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?

    private var taskId: String {
        if let cacheId {
            return "\(cacheId)|\(Int(maxDimension))|\(data?.count ?? 0)"
        }
        guard let data else { return "nil|\(Int(maxDimension))" }
        var hasher = Hasher()
        hasher.combine(data.count)
        hasher.combine(data.prefix(64))
        if data.count > 128 {
            let mid = data.count / 2
            hasher.combine(data[mid..<min(mid + 64, data.count)])
        }
        hasher.combine(data.suffix(64))
        hasher.combine(Int(maxDimension))
        return String(hasher.finalize())
    }

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
            .task(id: taskId) {
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
