import SwiftUI

/// Displays a dual app icon: a background app (e.g., Chrome) and a foreground overlay (e.g., site favicon)
struct DualAppIconView: View {
    let backgroundImage: NSImage
    let overlayImage: NSImage?
    var size: CGFloat = 22

    var body: some View {
        ZStack(alignment: .center) {
            // Background (e.g. Chrome icon)
            Image(nsImage: backgroundImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .shadow(radius: 1)

            // Overlay (e.g. favicon) - only if available
            if let overlayImage = overlayImage {
                Image(nsImage: overlayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.7, height: size * 0.7) // Increased size
                    .padding(size * 0.05) // Add a little padding around the icon itself
                    .background(Color(.windowBackgroundColor).opacity(0.85)) // Background for the padded area
                    .clipShape(Circle())
                    .shadow(radius: 1)
                    .offset(x: size * 0.28, y: size * 0.28) // Slightly adjusted offset
            }
        }
    }
}

struct DualAppIconView_Previews: PreviewProvider {
    static var previews: some View {
        let chromeIcon = NSImage(named: "chrome") ?? NSImage(named: NSImage.Name("NSApplicationIcon")) ?? NSImage(size: NSSize(width: 64, height: 64))
        let favicon = NSImage(named: "favicon_placeholder") ?? NSImage(named: NSImage.Name("NSFolderIcon")) ?? NSImage(size: NSSize(width: 32, height: 32))
        Group {
            DualAppIconView(backgroundImage: chromeIcon, overlayImage: favicon, size: 44)
            DualAppIconView(backgroundImage: chromeIcon, overlayImage: nil, size: 44)
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.gray)
    }
}
