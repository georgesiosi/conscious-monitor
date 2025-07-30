import SwiftUI

@available(macOS 13.0, *)
struct SharePreviewView: View {
    let events: [AppActivationEvent]
    let contextSwitches: [ContextSwitchMetrics]
    let timeRange: ShareableStackTimeRange
    let format: ShareableStackFormat
    let privacyLevel: ShareableStackPrivacyLevel
    let customStartDate: Date?
    let customEndDate: Date?
    
    @StateObject private var shareService = ShareImageService()
    @State private var shareableData: ShareableStackData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    loadingView
                } else if let errorMessage = errorMessage {
                    errorView(errorMessage)
                } else if let data = shareableData {
                    previewContent(data)
                } else {
                    emptyView
                }
            }
            .navigationTitle("Preview")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if shareableData != nil {
                    ToolbarItem(placement: .primaryAction) {
                        ShareImageButton(
                            events: events,
                            contextSwitches: contextSwitches,
                            timeRange: timeRange,
                            format: format,
                            privacyLevel: privacyLevel,
                            customStartDate: customStartDate,
                            customEndDate: customEndDate
                        )
                    }
                }
            }
        }
        .onAppear {
            generatePreviewData()
        }
    }
    
    // MARK: - Content Views
    
    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Generating Preview...")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text("Analyzing your productivity data")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.primaryBackground)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.error)
            
            Text("Preview Error")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            Button("Retry") {
                generatePreviewData()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.primaryBackground)
    }
    
    private var emptyView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Text("No Preview Available")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text("Unable to generate preview with current settings")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.primaryBackground)
    }
    
    private func previewContent(_ data: ShareableStackData) -> some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Preview metadata
                previewMetadata(data)
                
                // Actual preview
                previewCard(data)
                
                // Actions
                actionButtons(data)
            }
            .padding(DesignSystem.Layout.contentPadding)
        }
        .background(DesignSystem.Colors.primaryBackground)
    }
    
    private func previewMetadata(_ data: ShareableStackData) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Format")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text(format.displayName)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Privacy")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text(privacyLevel.displayName)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Time Period")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                Text(timeRangeDescription(data))
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(12)
    }
    
    private func previewCard(_ data: ShareableStackData) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Text("Preview")
                .font(DesignSystem.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            // Scale down the preview to fit the screen
            let scaleFactor: CGFloat = format == .story ? 0.3 : 0.5
            
            ShareableStackView(data: data, format: format)
                .scaleEffect(scaleFactor)
                .frame(
                    width: format.dimensions.width * scaleFactor,
                    height: format.dimensions.height * scaleFactor
                )
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    private func actionButtons(_ data: ShareableStackData) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Text("Actions")
                .font(DesignSystem.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            HStack(spacing: DesignSystem.Spacing.md) {
                Button("Copy to Clipboard") {
                    Task {
                        await copyToClipboard()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Save to Pictures") {
                    Task {
                        await saveToPictures()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            // Key metrics summary
            keyMetricsSummary(data)
        }
    }
    
    private func keyMetricsSummary(_ data: ShareableStackData) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Key Metrics")
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.sm) {
                metricItem("Focus Score", "\(Int(data.focusScore))%", color: focusScoreColor(data.focusScore))
                metricItem("Context Switches", "\(data.contextSwitches)", color: DesignSystem.Colors.warning)
                metricItem("Deep Focus Sessions", "\(data.deepFocusSessions)", color: DesignSystem.Colors.success)
                metricItem("Cost Savings", "$\(String(format: "%.0f", data.productivityCostSavings))", color: DesignSystem.Colors.accent)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(12)
    }
    
    private func metricItem(_ title: String, _ value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DesignSystem.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.primaryBackground)
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private func generatePreviewData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let service = ShareableStackService()
            let data = service.generateShareableData(
                from: events,
                contextSwitches: contextSwitches,
                timeRange: timeRange,
                customStartDate: customStartDate,
                customEndDate: customEndDate,
                privacyLevel: privacyLevel
            )
            
            await MainActor.run {
                self.shareableData = data
                self.isLoading = false
            }
        }
    }
    
    @MainActor
    private func copyToClipboard() async {
        guard let image = await shareService.generateShareableImage(
            from: events,
            contextSwitches: contextSwitches,
            timeRange: timeRange,
            format: format,
            privacyLevel: privacyLevel,
            customStartDate: customStartDate,
            customEndDate: customEndDate
        ) else { return }
        
        shareService.copyImageToClipboard(image)
    }
    
    @MainActor
    private func saveToPictures() async {
        guard let image = await shareService.generateShareableImage(
            from: events,
            contextSwitches: contextSwitches,
            timeRange: timeRange,
            format: format,
            privacyLevel: privacyLevel,
            customStartDate: customStartDate,
            customEndDate: customEndDate
        ) else { return }
        
        _ = shareService.saveImageToPictures(image, format: format, timeRange: timeRange)
    }
    
    private func timeRangeDescription(_ data: ShareableStackData) -> String {
        switch data.timeRange {
        case .today:
            return "Today"
        case .thisWeek:
            return "This Week"
        case .thisMonth:
            return "This Month"
        case .custom:
            if let startDate = data.customStartDate, let endDate = data.customEndDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
            }
            return "Custom Range"
        }
    }
    
    private func focusScoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100:
            return DesignSystem.Colors.success
        case 60...79:
            return DesignSystem.Colors.warning
        default:
            return DesignSystem.Colors.error
        }
    }
}

// MARK: - Preview

struct SharePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(macOS 13.0, *) {
            SharePreviewView(
                events: [],
                contextSwitches: [],
                timeRange: .today,
                format: .square,
                privacyLevel: .detailed,
                customStartDate: nil,
                customEndDate: nil
            )
        }
    }
}