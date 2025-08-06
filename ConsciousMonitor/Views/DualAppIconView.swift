import SwiftUI
import AppKit

/// A view that displays two app icons layered on top of each other
/// Used for Chrome tabs to show both Chrome icon (background) and site favicon (foreground)
struct DualAppIconView: View {
    let backgroundImage: NSImage
    let overlayImage: NSImage
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background icon (Chrome app icon)
            Image(nsImage: backgroundImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .cornerRadius(size * 0.15) // Subtle rounding
                .opacity(0.8) // Slightly transparent to show it's background
            
            // Overlay icon (site favicon) - positioned in bottom-right
            Image(nsImage: overlayImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.6, height: size * 0.6) // 60% of main icon size
                .cornerRadius(size * 0.08) // Smaller corner radius
                .background(
                    // White background for favicon for better visibility
                    RoundedRectangle(cornerRadius: size * 0.08)
                        .fill(Color.white)
                        .frame(width: size * 0.65, height: size * 0.65)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0.5)
                )
                .offset(x: size * 0.15, y: size * 0.15) // Position in bottom-right
        }
        .frame(width: size, height: size)
    }
}

#if DEBUG
struct DualAppIconView_Previews: PreviewProvider {
    static var previews: some View {
        let chromeIcon = NSImage(systemSymbolName: "network", accessibilityDescription: "Chrome") ?? NSImage()
        let faviconIcon = NSImage(systemSymbolName: "globe", accessibilityDescription: "Favicon") ?? NSImage()
        
        VStack(spacing: 20) {
            DualAppIconView(
                backgroundImage: chromeIcon,
                overlayImage: faviconIcon,
                size: 32
            )
            .previewDisplayName("Standard Size")
            
            DualAppIconView(
                backgroundImage: chromeIcon,
                overlayImage: faviconIcon,
                size: 64
            )
            .previewDisplayName("Large Size")
        }
        .padding()
    }
}
#endif