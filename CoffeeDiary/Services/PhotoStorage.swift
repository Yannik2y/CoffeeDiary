import UIKit
import ImageIO

enum PhotoStorage {
    private nonisolated static let photosDirectoryName = "EquipmentPhotos"
    private nonisolated static let thumbnailMaxDimension: CGFloat = 200
    private nonisolated static let syncMaxDimension: CGFloat = 1200
    private nonisolated static let syncJPEGQuality: CGFloat = 0.85

    /// Compresses image data for CloudKit sync via SwiftData external storage.
    /// Safe to call off the main thread (uses ImageIO / UIGraphicsImageRenderer).
    nonisolated static func compressedJPEG(from data: Data, maxDimension: CGFloat = 1200, quality: CGFloat = 0.85) -> Data? {
        guard let image = downsampledImage(from: data, maxDimension: maxDimension) ?? UIImage(data: data) else {
            return nil
        }
        let scaled = resized(image, maxDimension: maxDimension) ?? image
        return scaled.jpegData(compressionQuality: quality)
    }

    /// Async wrapper that performs compression off the main actor.
    static func compressedJPEGAsync(from data: Data, maxDimension: CGFloat = 1200, quality: CGFloat = 0.85) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            compressedJPEG(from: data, maxDimension: maxDimension, quality: quality)
        }.value
    }

    nonisolated static var photosDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent(photosDirectoryName, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @discardableResult
    nonisolated static func savePhoto(_ data: Data, id: UUID = UUID()) -> String? {
        guard let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.85) else { return nil }
        let filename = "\(id.uuidString).jpg"
        let url = photosDirectory.appendingPathComponent(filename)
        do {
            try jpeg.write(to: url)
            saveThumbnail(image, for: id)
            return filename
        } catch {
            return nil
        }
    }

    nonisolated static func loadPhoto(path: String?) -> Data? {
        guard let path else { return nil }
        let url = photosDirectory.appendingPathComponent(path)
        return try? Data(contentsOf: url)
    }

    /// Returns a thumbnail-sized UIImage from inline photo data (for list rows).
    nonisolated static func thumbnailImage(from data: Data?, maxDimension: CGFloat = 200) -> UIImage? {
        guard let data else { return nil }
        if let downsampled = downsampledImage(from: data, maxDimension: maxDimension) {
            return downsampled
        }
        guard let image = UIImage(data: data) else { return nil }
        return resized(image, maxDimension: maxDimension) ?? image
    }

    nonisolated static func deletePhoto(path: String?) {
        guard let path else { return }
        let url = photosDirectory.appendingPathComponent(path)
        try? FileManager.default.removeItem(at: url)
        let thumbPath = path.replacingOccurrences(of: ".jpg", with: "_thumb.jpg")
        try? FileManager.default.removeItem(at: photosDirectory.appendingPathComponent(thumbPath))
    }

    /// Removes leftover JPEGs in the photos directory after migration to external storage.
    nonisolated static func cleanupOrphanedPhotos() {
        let dir = photosDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files where file.pathExtension.lowercased() == "jpg" {
            try? FileManager.default.removeItem(at: file)
        }
    }

    nonisolated static func migrateInlinePhotoData(_ data: Data?) -> String? {
        guard let data else { return nil }
        return savePhoto(data)
    }

    private nonisolated static func saveThumbnail(_ image: UIImage, for id: UUID) {
        guard let thumb = resized(image, maxDimension: thumbnailMaxDimension),
              let jpeg = thumb.jpegData(compressionQuality: 0.7) else { return }
        let url = photosDirectory.appendingPathComponent("\(id.uuidString)_thumb.jpg")
        try? jpeg.write(to: url)
    }

    private nonisolated static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1)
        if scale >= 1 { return image }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Memory-efficient downsample via ImageIO (safe off main thread).
    private nonisolated static func downsampledImage(from data: Data, maxDimension: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            return nil
        }
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
