import AppKit
import Combine

class FaviconFetcher: ObservableObject {
    nonisolated(unsafe) static let shared = FaviconFetcher()
    private var cache = [String: NSImage]()
    private var cancellables = Set<AnyCancellable>()
    private let diskCacheURL: URL

    private init() {
        // Create favicon cache directory
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        diskCacheURL = appSupportURL.appendingPathComponent("FocusMonitor").appendingPathComponent("FaviconCache")
        
        do {
            try FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create favicon cache directory: \(error)")
        }
    }

    func fetchFavicon(forDomain domain: String, completion: @escaping (NSImage?) -> Void) {
        // Check memory cache first
        if let cachedImage = cache[domain] {
            completion(cachedImage)
            return
        }
        
        // Check disk cache
        if let diskCachedImage = loadFaviconFromDisk(domain: domain) {
            cache[domain] = diskCachedImage
            completion(diskCachedImage)
            return
        }

        // Use a reliable favicon service, e.g., Google's S2 favicon service
        // sz=64 requests a 64x64 pixel icon, adjust as needed.
        guard let url = URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=64") else {
            completion(nil)
            return
        }

        URLSession.shared.dataTaskPublisher(for: url)
            .map { NSImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink {
                [weak self] image in
                if let image = image {
                    self?.cache[domain] = image
                    self?.saveFaviconToDisk(image: image, domain: domain)
                }
                completion(image)
            }
            .store(in: &cancellables)
    }
    
    // Helper to extract domain from a URL string if needed, can be expanded.
    // Assumes basic https://www.example.com/path type URLs for now.
    func extractDomain(fromUrlString urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        return url.host
    }
    
    /// Load favicon from disk cache
    private func loadFaviconFromDisk(domain: String) -> NSImage? {
        let filename = sanitizedFilename(for: domain)
        let fileURL = diskCacheURL.appendingPathComponent("\(filename).png")
        
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = NSImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    /// Save favicon to disk cache
    private func saveFaviconToDisk(image: NSImage, domain: String) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            let filename = self.sanitizedFilename(for: domain)
            let fileURL = self.diskCacheURL.appendingPathComponent("\(filename).png")
            
            if let tiffData = image.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                try? pngData.write(to: fileURL)
            }
        }
    }
    
    /// Create safe filename from domain
    private func sanitizedFilename(for domain: String) -> String {
        return domain.replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}
