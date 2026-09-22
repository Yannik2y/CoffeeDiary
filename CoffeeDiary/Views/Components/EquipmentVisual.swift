import SwiftUI

/// Shows the user's photo when present, otherwise the build-type illustration on a tinted well.
struct EquipmentVisual: View {
    let photoData: Data?
    let silhouette: EquipmentSilhouette
    var cornerRadius: CGFloat = 16
    var thumbnailDimension: CGFloat = 400

    var body: some View {
        // The well defines the layout size; the overlay may overflow (fill photo) and is clipped.
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.accentColor.opacity(0.12))
            .overlay {
                if photoData != nil {
                    CachedThumbnailImage(data: photoData, maxDimension: thumbnailDimension)
                } else {
                    EquipmentSilhouetteView(silhouette: silhouette)
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }
}
