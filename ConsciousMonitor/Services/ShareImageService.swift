import SwiftUI
import AppKit
import Foundation

@available(macOS 13.0, *)
@MainActor
class ShareImageService: ObservableObject {
    @Published var isGenerating = false
    @Published var errorMessage: String?
    
    private let shareableStackService = ShareableStackService()
    
    // MARK: - Public Methods
    
    /// Generate a shareable image from app data
    func generateShareableImage(
        from events: [AppActivationEvent],
        contextSwitches: [ContextSwitchMetrics],
        timeRange: ShareableStackTimeRange,
        format: ShareableStackFormat,
        privacyLevel: ShareableStackPrivacyLevel,
        customStartDate: Date? = nil,
        customEndDate: Date? = nil
    ) async -> NSImage? {
        
        isGenerating = true
        errorMessage = nil
        
        // Validate inputs
        guard !events.isEmpty || !contextSwitches.isEmpty else {
            isGenerating = false
            errorMessage = "No data available to generate shareable image. Please use the app for a while to collect data."
            return nil
        }
        
        // Generate shareable data
        let shareableData = shareableStackService.generateShareableData(
            from: events,
            contextSwitches: contextSwitches,
            timeRange: timeRange,
            customStartDate: customStartDate,
            customEndDate: customEndDate,
            privacyLevel: privacyLevel
        )
        
        // Validate generated data has meaningful content
        if shareableData.categoryBreakdown.isEmpty && shareableData.achievements.isEmpty {
            isGenerating = false
            errorMessage = "Insufficient data for the selected time period. Try selecting a different time range or use the app longer."
            return nil
        }
        
        // Create the view
        let shareableView = ShareableStackView(data: shareableData, format: format)
        
        // Render to image
        let image = renderViewToImage(shareableView, format: format)
        
        isGenerating = false
        
        return image
    }
    
    /// Generate and share image directly
    func generateAndShare(
        from events: [AppActivationEvent],
        contextSwitches: [ContextSwitchMetrics],
        timeRange: ShareableStackTimeRange,
        format: ShareableStackFormat,
        privacyLevel: ShareableStackPrivacyLevel,
        customStartDate: Date? = nil,
        customEndDate: Date? = nil
    ) async {
        
        if let image = await generateShareableImage(
            from: events,
            contextSwitches: contextSwitches,
            timeRange: timeRange,
            format: format,
            privacyLevel: privacyLevel,
            customStartDate: customStartDate,
            customEndDate: customEndDate
        ) {
            shareImage(image, format: format, timeRange: timeRange)
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func renderViewToImage(_ view: ShareableStackView, format: ShareableStackFormat) -> NSImage? {
        // Create ImageRenderer
        let renderer = ImageRenderer(content: view)
        
        // Set the scale for high quality
        renderer.scale = 2.0
        
        // Configure based on format
        let size = format.dimensions
        renderer.proposedSize = .init(width: size.width, height: size.height)
        
        // Render to NSImage
        return renderer.nsImage
    }
    
    private func shareImage(_ image: NSImage, format: ShareableStackFormat, timeRange: ShareableStackTimeRange) {
        // Save to temporary file
        let tempURL = createTemporaryImageFile(image: image, format: format, timeRange: timeRange)
        
        guard let url = tempURL else {
            errorMessage = "Failed to save temporary image file"
            return
        }
        
        // Use NSSharingServicePicker for macOS sharing
        let picker = NSSharingServicePicker(items: [url])
        
        // Find the main window to present from
        if let window = NSApplication.shared.windows.first {
            let contentView = window.contentView ?? NSView()
            let rect = NSRect(x: 0, y: 0, width: 100, height: 100)
            picker.show(relativeTo: rect, of: contentView, preferredEdge: .minY)
        } else {
            // Fallback: Open Finder to the file
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
    
    private func createTemporaryImageFile(image: NSImage, format: ShareableStackFormat, timeRange: ShareableStackTimeRange) -> URL? {
        // Create filename
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let filename = "FocusStack_\(dateString)_\(format.rawValue).png"
        
        // Get temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        // Convert NSImage to PNG data
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        do {
            try pngData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to write image file: \(error)")
            return nil
        }
    }
    
    // MARK: - Utility Methods
    
    /// Save image to user's Pictures folder
    func saveImageToPictures(_ image: NSImage, format: ShareableStackFormat, timeRange: ShareableStackTimeRange) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        
        let filename = "FocusStack_\(dateString)_\(format.rawValue).png"
        
        // Get Pictures directory
        let picturesDir = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
        guard let picturesURL = picturesDir else { return nil }
        
        let fileURL = picturesURL.appendingPathComponent(filename)
        
        // Convert NSImage to PNG data
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        do {
            try pngData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save image to Pictures: \(error)")
            return nil
        }
    }
    
    /// Copy image to clipboard
    func copyImageToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
}

// MARK: - SwiftUI Integration

struct ShareImageButton: View {
    let events: [AppActivationEvent]
    let contextSwitches: [ContextSwitchMetrics]
    let timeRange: ShareableStackTimeRange
    let format: ShareableStackFormat
    let privacyLevel: ShareableStackPrivacyLevel
    let customStartDate: Date?
    let customEndDate: Date?
    
    @StateObject private var shareService = ShareImageService()
    @State private var showingShareSheet = false
    @State private var generatedImage: NSImage?
    @State private var showingSuccessMessage = false
    
    var body: some View {
        Button(action: {
            Task {
                await shareService.generateAndShare(
                    from: events,
                    contextSwitches: contextSwitches,
                    timeRange: timeRange,
                    format: format,
                    privacyLevel: privacyLevel,
                    customStartDate: customStartDate,
                    customEndDate: customEndDate
                )
            }
        }) {
            HStack(spacing: 6) {
                if shareService.isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                }
                
                Text("Share Stack")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
            )
        }
        .disabled(shareService.isGenerating)
        .alert("Error", isPresented: .constant(shareService.errorMessage != nil)) {
            Button("OK") {
                shareService.errorMessage = nil
            }
        } message: {
            if let errorMessage = shareService.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Preview

struct ShareImageButton_Previews: PreviewProvider {
    static var previews: some View {
        ShareImageButton(
            events: [],
            contextSwitches: [],
            timeRange: .today,
            format: .square,
            privacyLevel: .detailed,
            customStartDate: nil,
            customEndDate: nil
        )
        .padding()
    }
}