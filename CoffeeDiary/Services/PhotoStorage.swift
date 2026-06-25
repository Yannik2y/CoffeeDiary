import UIKit

enum PhotoStorage {
    private static let photosDirectoryName = "EquipmentPhotos"
    private static let thumbnailMaxDimension: CGFloat = 200
    private static let syncMaxDimension: CGFloat = 1200
    private static let syncJPEGQuality: CGFloat = 0.85

    /// Compresses image data for CloudKit sync via SwiftData external storage.
    static func compressedJPEG(from data: Data, maxDimension: CGFloat = syncMaxDimension, quality: CGFloat = syncJPEGQuality) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scaled = resized(image, maxDimension: maxDimension) ?? image
        return scaled.jpegData(compressionQuality: quality)
    }

    static var photosDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent(photosDirectoryName, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @discardableResult
    static func savePhoto(_ data: Data, id: UUID = UUID()) -> String? {
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

    static func loadPhoto(path: String?) -> Data? {
        guard let path else { return nil }
        let url = photosDirectory.appendingPathComponent(path)
        return try? Data(contentsOf: url)
    }

    static func loadThumbnail(path: String?) -> UIImage? {
        guard let path else { return nil }
        let thumbPath = path.replacingOccurrences(of: ".jpg", with: "_thumb.jpg")
        let url = photosDirectory.appendingPathComponent(thumbPath)
        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            return image
        }
        if let data = loadPhoto(path: path), let image = UIImage(data: data) {
            return resized(image, maxDimension: thumbnailMaxDimension)
        }
        return nil
    }

    static func deletePhoto(path: String?) {
        guard let path else { return }
        let url = photosDirectory.appendingPathComponent(path)
        try? FileManager.default.removeItem(at: url)
        let thumbPath = path.replacingOccurrences(of: ".jpg", with: "_thumb.jpg")
        try? FileManager.default.removeItem(at: photosDirectory.appendingPathComponent(thumbPath))
    }

    static func migrateInlinePhotoData(_ data: Data?) -> String? {
        guard let data else { return nil }
        return savePhoto(data)
    }

    private static func saveThumbnail(_ image: UIImage, for id: UUID) {
        guard let thumb = resized(image, maxDimension: thumbnailMaxDimension),
              let jpeg = thumb.jpegData(compressionQuality: 0.7) else { return }
        let url = photosDirectory.appendingPathComponent("\(id.uuidString)_thumb.jpg")
        try? jpeg.write(to: url)
    }

    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
