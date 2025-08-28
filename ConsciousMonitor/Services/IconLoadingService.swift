import Foundation
import AppKit

class IconLoadingService {
    static let shared = IconLoadingService()
    
    private var iconCache: [String: NSImage] = [:]
    
    private init() {
        // Simple initialization - no disk cache needed
    }
    
    /// Simple, synchronous app icon loading with basic caching
    func loadAppIcon(for bundleId: String?) -> NSImage? {
        guard let bundleId = bundleId, !bundleId.isEmpty else { return nil }
        
        // Check memory cache first
        if let cachedIcon = iconCache[bundleId] {
            return cachedIcon
        }
        
        // Try to get icon from NSWorkspace (works for installed apps)
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            iconCache[bundleId] = icon
            return icon
        }
        
        // Try to get icon from running app as fallback
        if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }),
           let appIcon = runningApp.icon {
            iconCache[bundleId] = appIcon
            return appIcon
        }
        
        // Create fallback icon for unknown apps
        let fallbackIcon = createFallbackIcon(for: bundleId)
        if let fallbackIcon = fallbackIcon {
            iconCache[bundleId] = fallbackIcon
        }
        return fallbackIcon
    }
    
    /// Synchronous batch icon loading for events
    func loadIconsForEvents(_ events: [AppActivationEvent]) -> [AppActivationEvent] {
        var updatedEvents = events
        
        for i in 0..<updatedEvents.count {
            if updatedEvents[i].appIcon == nil {
                let icon = loadAppIcon(for: updatedEvents[i].bundleIdentifier)
                updatedEvents[i].appIcon = icon
            }
        }
        
        return updatedEvents
    }
    
    /// Create a simple fallback icon for unknown apps
    private func createFallbackIcon(for bundleId: String) -> NSImage? {
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
        
        return image
    }
    
    /// Clear the icon cache
    func clearCache() {
        iconCache.removeAll()
    }
    
    /// Get cache statistics
    func getCacheStats() -> (memoryCount: Int, diskCacheSize: Int) {
        return (memoryCount: iconCache.count, diskCacheSize: 0)
    }
}
