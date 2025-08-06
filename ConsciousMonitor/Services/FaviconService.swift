import Foundation
import AppKit
import Combine

/// Service for fetching and caching website favicons
/// Provides async favicon loading with fallback strategies and local caching
class FaviconService: ObservableObject {
    static let shared = FaviconService()
    
    // MARK: - Properties
    
    private let cache: NSCache<NSString, NSImage>
    private let diskCacheDirectory: URL
    private let session: URLSession
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    // Track ongoing fetch operations to avoid duplicates
    private var ongoingFetches: Set<String> = []
    private let fetchQueue = DispatchQueue(label: "com.consciousmonitor.favicon", qos: .utility)
    
    // MARK: - Initialization
    
    private init() {
        // Configure memory cache
        cache = NSCache<NSString, NSImage>()
        cache.countLimit = 200 // Store up to 200 favicons in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit
        
        // Setup disk cache directory
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                   in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "com.consciousmonitor"
        diskCacheDirectory = appSupportDir
            .appendingPathComponent(bundleID)
            .appendingPathComponent("favicons")
        
        // Create disk cache directory
        try? FileManager.default.createDirectory(at: diskCacheDirectory, 
                                               withIntermediateDirectories: true)
        
        // Configure URL session for favicon fetching
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 15.0
        config.httpMaximumConnectionsPerHost = 4
        session = URLSession(configuration: config)
        
        print("FaviconService: Initialized with cache directory: \(diskCacheDirectory.path)")
    }
    
    // MARK: - Public API
    
    /// Fetch favicon for a domain with callback
    /// - Parameters:
    ///   - domain: The domain to fetch favicon for (e.g., "stripe.com")
    ///   - completion: Callback with the fetched favicon or nil
    func fetchFavicon(for domain: String, completion: @escaping (NSImage?) -> Void) {
        let cleanDomain = domain.lowercased().replacingOccurrences(of: "www.", with: "")
        
        // Check memory cache first
        if let cachedImage = cache.object(forKey: cleanDomain as NSString) {
            print("FaviconService: Memory cache hit for \(cleanDomain)")
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return
        }
        
        // Check if we're already fetching this favicon
        fetchQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.ongoingFetches.contains(cleanDomain) {
                print("FaviconService: Already fetching \(cleanDomain), skipping")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            self.ongoingFetches.insert(cleanDomain)
            
            // Check disk cache
            if let diskCachedImage = self.loadFromDiskCache(domain: cleanDomain) {
                print("FaviconService: Disk cache hit for \(cleanDomain)")
                self.cache.setObject(diskCachedImage, forKey: cleanDomain as NSString)
                self.ongoingFetches.remove(cleanDomain)
                DispatchQueue.main.async {
                    completion(diskCachedImage)
                }
                return
            }
            
            // Fetch from network
            self.fetchFaviconFromNetwork(domain: cleanDomain) { [weak self] image in
                self?.ongoingFetches.remove(cleanDomain)
                completion(image)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchFaviconFromNetwork(domain: String, completion: @escaping (NSImage?) -> Void) {
        let faviconURLs = buildFaviconURLs(for: domain)
        
        fetchFromURLs(faviconURLs, domain: domain, urlIndex: 0, completion: completion)
    }
    
    private func fetchFromURLs(_ urls: [URL], domain: String, urlIndex: Int, completion: @escaping (NSImage?) -> Void) {
        guard urlIndex < urls.count else {
            print("FaviconService: All favicon URLs failed for \(domain)")
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        let url = urls[urlIndex]
        print("FaviconService: Trying \(url.absoluteString) for \(domain)")
        
        session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("FaviconService: Error fetching \(url): \(error.localizedDescription)")
                // Try next URL
                self.fetchFromURLs(urls, domain: domain, urlIndex: urlIndex + 1, completion: completion)
                return
            }
            
            guard let data = data, 
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = NSImage(data: data),
                  image.size.width > 0 && image.size.height > 0 else {
                print("FaviconService: Invalid response or image data from \(url)")
                // Try next URL
                self.fetchFromURLs(urls, domain: domain, urlIndex: urlIndex + 1, completion: completion)
                return
            }
            
            print("FaviconService: Successfully fetched favicon for \(domain) from \(url)")
            
            // Process and cache the image
            let processedImage = self.processFavicon(image)
            
            // Store in caches
            self.cache.setObject(processedImage, forKey: domain as NSString)
            self.saveToDiskCache(image: processedImage, domain: domain)
            
            DispatchQueue.main.async {
                completion(processedImage)
            }
            
        }.resume()
    }
    
    private func buildFaviconURLs(for domain: String) -> [URL] {
        let baseURL = "https://\(domain)"
        var urls: [URL] = []
        
        // Standard favicon locations in order of preference
        let faviconPaths = [
            "/favicon-32x32.png",
            "/favicon-16x16.png", 
            "/apple-touch-icon.png",
            "/apple-touch-icon-152x152.png",
            "/favicon.png",
            "/favicon.ico"
        ]
        
        for path in faviconPaths {
            if let url = URL(string: baseURL + path) {
                urls.append(url)
            }
        }
        
        return urls
    }
    
    private func processFavicon(_ image: NSImage) -> NSImage {
        // Ensure favicon is appropriate size and quality
        let targetSize = NSSize(width: 32, height: 32)
        
        guard image.size != targetSize else { return image }
        
        let processedImage = NSImage(size: targetSize)
        processedImage.lockFocus()
        
        // Draw with high quality
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: targetSize), 
                  from: NSRect(origin: .zero, size: image.size), 
                  operation: .copy, 
                  fraction: 1.0)
        
        processedImage.unlockFocus()
        return processedImage
    }
    
    // MARK: - Disk Cache Management
    
    private func loadFromDiskCache(domain: String) -> NSImage? {
        let fileURL = diskCacheDirectory.appendingPathComponent("\(domain).png")
        
        // Check if file exists and is recent enough
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let modificationDate = attributes[.modificationDate] as? Date {
                let age = Date().timeIntervalSince(modificationDate)
                if age > maxCacheAge {
                    // Cache expired, delete file
                    try? FileManager.default.removeItem(at: fileURL)
                    return nil
                }
            }
            
            return NSImage(contentsOf: fileURL)
        } catch {
            print("FaviconService: Error reading disk cache for \(domain): \(error)")
            return nil
        }
    }
    
    private func saveToDiskCache(image: NSImage, domain: String) {
        let fileURL = diskCacheDirectory.appendingPathComponent("\(domain).png")
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            print("FaviconService: Failed to convert image to PNG for \(domain)")
            return
        }
        
        do {
            try pngData.write(to: fileURL)
            print("FaviconService: Saved favicon to disk cache for \(domain)")
        } catch {
            print("FaviconService: Failed to save favicon to disk for \(domain): \(error)")
        }
    }
    
    // MARK: - Cache Management
    
    /// Clear memory cache
    func clearMemoryCache() {
        cache.removeAllObjects()
        print("FaviconService: Memory cache cleared")
    }
    
    /// Clear disk cache
    func clearDiskCache() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: diskCacheDirectory, 
                                                                  includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            print("FaviconService: Disk cache cleared")
        } catch {
            print("FaviconService: Error clearing disk cache: \(error)")
        }
    }
    
    /// Get cache statistics
    func getCacheStats() -> (memoryCount: Int, diskCount: Int, diskSize: Int64) {
        let diskFiles = (try? FileManager.default.contentsOfDirectory(at: diskCacheDirectory, 
                                                                     includingPropertiesForKeys: [.fileSizeKey])) ?? []
        
        let diskSize = diskFiles.compactMap { url -> Int64? in
            let resources = try? url.resourceValues(forKeys: [.fileSizeKey])
            return Int64(resources?.fileSize ?? 0)
        }.reduce(0, +)
        
        return (
            memoryCount: cache.countLimit,
            diskCount: diskFiles.count,
            diskSize: diskSize
        )
    }
}