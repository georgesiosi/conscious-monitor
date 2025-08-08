import Foundation
import AppKit

class IconLoadingService {
    static let shared = IconLoadingService()
    
    private var iconCache: [String: NSImage] = [:]
    private let cacheQueue = DispatchQueue(label: "com.consciousmonitor.iconCache", qos: .utility)
    private let diskCacheURL: URL
    
    private init() {
        // Create icon cache directory - use same bundle ID pattern as other services
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "com.example.ConsciousMonitor"
        diskCacheURL = appSupportURL.appendingPathComponent(bundleID).appendingPathComponent("IconCache")
        
        do {
            try FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create icon cache directory: \(error)")
        }
    }
    
    /// Validate if an icon is actually visible and not blank (conservative check)
    private func isValidIcon(_ image: NSImage) -> Bool {
        // Only reject icons with clearly invalid dimensions (very conservative)
        guard image.size.width > 1 && image.size.height > 1 else { 
            print("IconLoadingService: Icon has invalid dimensions: \(image.size)")
            return false 
        }
        
        // For most cases, if it has reasonable dimensions, it's probably valid
        // Avoid expensive validation that was causing issues
        return true
    }
    
    /// Load app icon for a given bundle identifier with enhanced reliability
    func loadAppIcon(for bundleId: String?) -> NSImage? {
        guard let bundleId = bundleId, !bundleId.isEmpty else { return nil }
        
        // Check memory cache first - return cached icons without aggressive validation
        if let cachedIcon = iconCache[bundleId] {
            return cachedIcon
        }
        
        // Check disk cache with better error handling
        if let diskCachedIcon = loadIconFromDisk(bundleId: bundleId) {
            iconCache[bundleId] = diskCachedIcon
            return diskCachedIcon
        }
        
        // Try multiple approaches to get the icon
        var icon: NSImage? = nil
        
        // 1. Try to get icon from running application
        if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }),
           let appIcon = runningApp.icon {
            icon = appIcon
            print("IconLoadingService: Loaded icon from running app for \(bundleId)")
        }
        
        // 2. Try to get icon from bundle path (more reliable approach)
        if icon == nil {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                let workspaceIcon = NSWorkspace.shared.icon(forFile: appURL.path)
                icon = workspaceIcon
                print("IconLoadingService: Loaded icon from workspace for \(bundleId)")
            }
        }
        
        // 3. Try alternative bundle lookup approaches
        if icon == nil {
            // Try to find app in common locations
            let commonPaths = [
                "/Applications",
                "/System/Applications",
                "/System/Library/CoreServices",
                "/usr/local/bin"
            ]
            
            for basePath in commonPaths {
                let fm = FileManager.default
                do {
                    let contents = try fm.contentsOfDirectory(atPath: basePath)
                    for item in contents {
                        let fullPath = "\(basePath)/\(item)"
                        
                        // Check if this might be our app
                        if item.hasSuffix(".app") {
                            let bundle = Bundle(path: fullPath)
                            if bundle?.bundleIdentifier == bundleId {
                                let appIcon = NSWorkspace.shared.icon(forFile: fullPath)
                                icon = appIcon
                                print("IconLoadingService: Loaded icon from directory search for \(bundleId)")
                                break
                            }
                        }
                    }
                    if icon != nil { break }
                } catch {
                    // Continue to next path
                    continue
                }
            }
        }
        
        // 4. Create a meaningful fallback icon if we still don't have one
        if icon == nil {
            print("IconLoadingService: Creating fallback icon for \(bundleId)")
            icon = createFallbackIcon(for: bundleId)
        }
        
        // Cache and save the icon if we found one
        if let finalIcon = icon {
            iconCache[bundleId] = finalIcon
            saveIconToDisk(icon: finalIcon, bundleId: bundleId)
            print("IconLoadingService: Successfully loaded and cached icon for \(bundleId)")
            return finalIcon
        }
        
        print("IconLoadingService: Could not load valid icon for bundle ID: \(bundleId)")
        return nil
    }
    
    /// Load app icon asynchronously with retry mechanism
    func loadAppIconAsync(for bundleId: String?, completion: @escaping (NSImage?) -> Void) {
        loadAppIconWithRetry(for: bundleId, attempt: 0, completion: completion)
    }
    
    /// Load app icon with retry mechanism for blank/invalid icons
    private func loadAppIconWithRetry(for bundleId: String?, attempt: Int, completion: @escaping (NSImage?) -> Void) {
        cacheQueue.async { [weak self] in
            let icon = self?.loadAppIcon(for: bundleId)
            
            // If we got any icon, return it (validation is too aggressive)
            if let icon = icon {
                DispatchQueue.main.async {
                    completion(icon)
                }
                return
            }
            
            // Only retry if we got no icon at all
            let maxAttempts = 2 // Reduced retry attempts
            if attempt < maxAttempts {
                let delay = 0.1 * Double(attempt + 1) // 0.1s, 0.2s
                print("IconLoadingService: Retrying icon load for \(bundleId ?? "unknown") (attempt \(attempt + 1)/\(maxAttempts)) after \(delay)s")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self?.loadAppIconWithRetry(for: bundleId, attempt: attempt + 1, completion: completion)
                }
            } else {
                print("IconLoadingService: Max retry attempts reached for \(bundleId ?? "unknown")")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    /// Load multiple icons for events with enhanced reliability
    func loadIconsForEvents(_ events: [AppActivationEvent], completion: @escaping ([AppActivationEvent]) -> Void) {
        cacheQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(events) }
                return
            }
            
            var updatedEvents = events
            var pendingFaviconUpdates = 0
            let dispatchGroup = DispatchGroup()
            
            for i in 0..<updatedEvents.count {
                if updatedEvents[i].appIcon == nil {
                    let icon = self.loadAppIcon(for: updatedEvents[i].bundleIdentifier)
                    updatedEvents[i].appIcon = icon
                    
                    // Log for debugging
                    if icon == nil {
                        print("Failed to load icon for: \(updatedEvents[i].bundleIdentifier ?? "unknown")")
                    }
                }
                
                // Also load favicon for Chrome events if missing
                if updatedEvents[i].bundleIdentifier == "com.google.Chrome" && 
                   updatedEvents[i].siteFavicon == nil,
                   let domain = updatedEvents[i].siteDomain {
                    
                    dispatchGroup.enter()
                    pendingFaviconUpdates += 1
                    
                    // Load favicon asynchronously
                    FaviconFetcher.shared.fetchFavicon(forDomain: domain) { favicon in
                        defer { dispatchGroup.leave() }
                        
                        // Find the event and update it
                        if let index = updatedEvents.firstIndex(where: { $0.id == updatedEvents[i].id }) {
                            updatedEvents[index].siteFavicon = favicon
                        }
                    }
                }
            }
            
            // Wait for all favicon loads to complete, then return results
            dispatchGroup.notify(queue: DispatchQueue.main) {
                print("IconLoadingService: Loaded icons for \(events.count) events. Missing icons: \(updatedEvents.filter { $0.appIcon == nil }.count)")
                completion(updatedEvents)
            }
        }
    }
    
    /// Create a fallback icon for unknown apps - MUST be called on main thread
    private func createFallbackIcon(for bundleId: String) -> NSImage? {
        // Ensure we're on the main thread for UI operations
        if !Thread.isMainThread {
            print("IconLoadingService: Creating fallback icon on main thread for \\(bundleId)")
            return DispatchQueue.main.sync {
                return createFallbackIconOnMainThread(for: bundleId)
            }
        } else {
            return createFallbackIconOnMainThread(for: bundleId)
        }
    }
    
    /// Create fallback icon on main thread (lockFocus/unlockFocus require main thread)
    private func createFallbackIconOnMainThread(for bundleId: String) -> NSImage? {
        // Try to extract app name from bundle ID and create a text-based icon
        let appName = bundleId.components(separatedBy: ".").last?.capitalized ?? "App"
        
        // Create a simple colored circle with first letter
        let size = NSSize(width: 32, height: 32)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Draw background circle
        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(ovalIn: rect)
        NSColor.systemBlue.setFill()
        path.fill()
        
        // Draw first letter
        let firstLetter = String(appName.prefix(1))
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 18, weight: .medium)
        ]
        
        let attributedString = NSAttributedString(string: firstLetter, attributes: attributes)
        let textSize = attributedString.size()
        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: textRect)
        image.unlockFocus()
        
        print("IconLoadingService: Created fallback icon for \\(bundleId)")
        return image
    }
    
    /// Load icon from disk cache
    private func loadIconFromDisk(bundleId: String) -> NSImage? {
        let filename = sanitizedFilename(for: bundleId)
        let fileURL = diskCacheURL.appendingPathComponent("\(filename).png")
        
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = NSImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    /// Save icon to disk cache
    private func saveIconToDisk(icon: NSImage, bundleId: String) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            let filename = self.sanitizedFilename(for: bundleId)
            let fileURL = self.diskCacheURL.appendingPathComponent("\(filename).png")
            
            if let tiffData = icon.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                try? pngData.write(to: fileURL)
            }
        }
    }
    
    /// Create safe filename from bundle ID
    private func sanitizedFilename(for bundleId: String) -> String {
        return bundleId.replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
    
    /// Clear the icon cache
    func clearCache() {
        cacheQueue.async { [weak self] in
            self?.iconCache.removeAll()
        }
    }
    
    /// Preload icons for common applications
    func preloadCommonIcons() {
        let commonBundleIds = [
            "com.google.Chrome",
            "com.apple.Safari",
            "com.microsoft.VSCode",
            "com.apple.finder",
            "com.apple.mail",
            "com.slack.Slack",
            "com.microsoft.teams",
            "com.zoom.xos"
        ]
        
        cacheQueue.async { [weak self] in
            for bundleId in commonBundleIds {
                _ = self?.loadAppIcon(for: bundleId)
            }
        }
    }
    
    /// Batch preload icons for a list of bundle identifiers
    func preloadIcons(for bundleIds: [String], completion: @escaping () -> Void = {}) {
        cacheQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion() }
                return
            }
            
            for bundleId in bundleIds {
                if self.iconCache[bundleId] == nil {
                    _ = self.loadAppIcon(for: bundleId)
                }
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    /// Validate and retry icons that appear to be blank
    func validateAndRetryBlankIcons() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Only validate icons that are clearly problematic (very small dimensions)
            var iconsToRetry: [String] = []
            for (bundleId, icon) in self.iconCache {
                if icon.size.width <= 1 || icon.size.height <= 1 {
                    iconsToRetry.append(bundleId)
                }
            }
            
            if !iconsToRetry.isEmpty {
                print("IconLoadingService: Found \(iconsToRetry.count) clearly invalid cached icons, retrying...")
                
                // Remove invalid icons and retry
                for bundleId in iconsToRetry {
                    self.iconCache.removeValue(forKey: bundleId)
                    _ = self.loadAppIcon(for: bundleId)
                }
            }
        }
    }
    
    /// Force reload all icons for events (useful for debugging)
    func forceReloadAllIcons(for events: [AppActivationEvent], completion: @escaping ([AppActivationEvent]) -> Void) {
        cacheQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(events) }
                return
            }
            
            // Clear cache for these specific bundle IDs
            let bundleIds = Set(events.compactMap { $0.bundleIdentifier })
            for bundleId in bundleIds {
                self.iconCache.removeValue(forKey: bundleId)
            }
            
            // Reload icons
            self.loadIconsForEvents(events, completion: completion)
        }
    }
    
    /// Get cache statistics for debugging
    func getCacheStats() -> (memoryCount: Int, diskCacheSize: Int) {
        let memoryCount = iconCache.count
        
        var diskCacheSize = 0
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil)
            diskCacheSize = contents.filter { $0.pathExtension == "png" }.count
        } catch {
            print("Error reading disk cache: \(error)")
        }
        
        return (memoryCount: memoryCount, diskCacheSize: diskCacheSize)
    }
}
