import SwiftUI

struct ShareConfigurationView: View {
    let events: [AppActivationEvent]
    let contextSwitches: [ContextSwitchMetrics]
    
    @State private var selectedTimeRange: ShareableStackTimeRange = .today
    @State private var selectedFormat: ShareableStackFormat = .square
    @State private var selectedPrivacyLevel: ShareableStackPrivacyLevel = .detailed
    @State private var customStartDate = Date().addingTimeInterval(-7 * 24 * 3600) // 1 week ago
    @State private var customEndDate = Date()
    @State private var showingPreview = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Share Your Focus Stack")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("Create a beautiful summary of your productivity achievements to share on social media")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Divider()
                    
                    // Time Range Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        sectionHeader("Time Period", icon: "calendar")
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(ShareableStackTimeRange.allCases, id: \.self) { timeRange in
                                timeRangeOption(timeRange)
                            }
                        }
                        
                        // Custom date range
                        if selectedTimeRange == .custom {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                Text("Custom Date Range")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                HStack(spacing: DesignSystem.Spacing.md) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("From")
                                            .font(DesignSystem.Typography.caption2)
                                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                                        DatePicker("", selection: $customStartDate, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("To")
                                            .font(DesignSystem.Typography.caption2)
                                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                                        DatePicker("", selection: $customEndDate, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                    }
                                }
                                .padding(DesignSystem.Spacing.md)
                                .background(DesignSystem.Colors.cardBackground)
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Format Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        sectionHeader("Format", icon: "rectangle.3.group")
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(ShareableStackFormat.allCases, id: \.self) { format in
                                formatOption(format)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Privacy Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        sectionHeader("Privacy Level", icon: "eye.slash")
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(ShareableStackPrivacyLevel.allCases, id: \.self) { privacy in
                                privacyOption(privacy)
                            }
                        }
                        
                        privacyExplanationCard
                    }
                    
                    Divider()
                    
                    // Preview and Share Buttons
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Button("Preview") {
                                showingPreview = true
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            if #available(macOS 13.0, *) {
                                ShareImageButton(
                                    events: events,
                                    contextSwitches: contextSwitches,
                                    timeRange: selectedTimeRange,
                                    format: selectedFormat,
                                    privacyLevel: selectedPrivacyLevel,
                                    customStartDate: selectedTimeRange == .custom ? customStartDate : nil,
                                    customEndDate: selectedTimeRange == .custom ? customEndDate : nil
                                )
                            }
                        }
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(TertiaryButtonStyle())
                    }
                }
                .padding(DesignSystem.Layout.contentPadding)
            }
            .navigationTitle("Share Configuration")
        }
        .sheet(isPresented: $showingPreview) {
            if #available(macOS 13.0, *) {
                SharePreviewView(
                    events: events,
                    contextSwitches: contextSwitches,
                    timeRange: selectedTimeRange,
                    format: selectedFormat,
                    privacyLevel: selectedPrivacyLevel,
                    customStartDate: selectedTimeRange == .custom ? customStartDate : nil,
                    customEndDate: selectedTimeRange == .custom ? customEndDate : nil
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.accent)
            
            Text(title)
                .font(DesignSystem.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
    }
    
    private func timeRangeOption(_ timeRange: ShareableStackTimeRange) -> some View {
        Button(action: {
            selectedTimeRange = timeRange
        }) {
            HStack {
                Text(timeRange.displayName)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                if selectedTimeRange == timeRange {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.accent)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedTimeRange == timeRange ? DesignSystem.Colors.accent.opacity(0.1) : DesignSystem.Colors.cardBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatOption(_ format: ShareableStackFormat) -> some View {
        Button(action: {
            selectedFormat = format
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(format.displayName)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(formatDescription(format))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if selectedFormat == format {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.accent)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedFormat == format ? DesignSystem.Colors.accent.opacity(0.1) : DesignSystem.Colors.cardBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func privacyOption(_ privacy: ShareableStackPrivacyLevel) -> some View {
        Button(action: {
            selectedPrivacyLevel = privacy
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(privacy.displayName)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(privacyDescription(privacy))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if selectedPrivacyLevel == privacy {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.accent)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedPrivacyLevel == privacy ? DesignSystem.Colors.accent.opacity(0.1) : DesignSystem.Colors.cardBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var privacyExplanationCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(DesignSystem.Colors.accent)
                Text("Privacy Information")
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
            
            Text("Your data stays on your device. Only aggregate metrics and categories are included in the shareable image. No specific URLs, personal data, or detailed activity logs are shared.")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.accent.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private func formatDescription(_ format: ShareableStackFormat) -> String {
        switch format {
        case .square:
            return "Perfect for Instagram posts (1080×1080)"
        case .landscape:
            return "Great for Twitter and LinkedIn (1200×675)"
        case .story:
            return "Ideal for Instagram Stories (1080×1920)"
        }
    }
    
    private func privacyDescription(_ privacy: ShareableStackPrivacyLevel) -> String {
        switch privacy {
        case .detailed:
            return "Show app names and specific metrics"
        case .categoryOnly:
            return "Show categories but hide specific app names"
        case .minimal:
            return "Show only high-level metrics and achievements"
        }
    }
}

// MARK: - Button Styles

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(DesignSystem.Colors.cardBackground)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DesignSystem.Colors.accent, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .foregroundColor(DesignSystem.Colors.secondaryText)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Preview

struct ShareConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        ShareConfigurationView(
            events: [],
            contextSwitches: []
        )
    }
}