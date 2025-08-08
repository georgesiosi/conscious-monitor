import SwiftUI

// MARK: - Data Model

/// Represents productivity gain metrics with comparison data
struct ProductivityGainMetrics {
    let appHoppingReduction: Double        // Percentage reduction in app hopping
    let averageDeepWorkDuration: TimeInterval  // Average duration of focused work sessions
    let dailyTimeSavings: TimeInterval     // Time saved per day through improved focus
    let comparisonPeriod: String           // e.g., "vs last week", "vs last month"
    let hasMinimumData: Bool              // Whether there's sufficient data for meaningful metrics
    
    /// Sample data for preview/testing purposes
    static let sampleData = ProductivityGainMetrics(
        appHoppingReduction: 23.5,
        averageDeepWorkDuration: 45 * 60, // 45 minutes
        dailyTimeSavings: 2 * 60 * 60 + 15 * 60, // 2 hours 15 minutes
        comparisonPeriod: "vs last week",
        hasMinimumData: true
    )
    
    /// Empty state for insufficient data
    static let insufficientData = ProductivityGainMetrics(
        appHoppingReduction: 0,
        averageDeepWorkDuration: 0,
        dailyTimeSavings: 0,
        comparisonPeriod: "insufficient data",
        hasMinimumData: false
    )
}

// MARK: - Metric Type Enumeration

/// Represents the different types of metrics that can be displayed
enum ProductivityMetricType: String, CaseIterable, Identifiable {
    case appHoppingReduction = "App Hopping Reduction"
    case deepWorkDuration = "Deep Work Sessions"
    case timeSavings = "Daily Time Savings"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .appHoppingReduction: return "arrow.down.circle"
        case .deepWorkDuration: return "clock"
        case .timeSavings: return "hourglass"
        }
    }
    
    var color: Color {
        switch self {
        case .appHoppingReduction: return .green
        case .deepWorkDuration: return .blue
        case .timeSavings: return .orange
        }
    }
}

// MARK: - Formatting Utilities

extension ProductivityGainMetrics {
    /// Format time duration into human-readable format
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Format percentage with appropriate decimal places
    private func formatPercentage(_ percentage: Double) -> String {
        if percentage < 1 {
            return String(format: "%.1f%%", percentage)
        } else {
            return String(format: "%.0f%%", percentage)
        }
    }
    
    /// Get formatted value for a specific metric type
    func formattedValue(for type: ProductivityMetricType) -> String {
        switch type {
        case .appHoppingReduction:
            return formatPercentage(appHoppingReduction)
        case .deepWorkDuration:
            return formatDuration(averageDeepWorkDuration)
        case .timeSavings:
            return formatDuration(dailyTimeSavings)
        }
    }
    
    /// Get accessibility label for a metric
    func accessibilityLabel(for type: ProductivityMetricType) -> String {
        switch type {
        case .appHoppingReduction:
            return "App hopping reduced by \(formatPercentage(appHoppingReduction)) \(comparisonPeriod)"
        case .deepWorkDuration:
            return "Average deep work session duration: \(formatDuration(averageDeepWorkDuration))"
        case .timeSavings:
            return "Daily time savings: \(formatDuration(dailyTimeSavings)) \(comparisonPeriod)"
        }
    }
}

// MARK: - Animated Metric Display

/// Displays a single metric with smooth transitions between different values
struct AnimatedMetricDisplay: View {
    let metrics: ProductivityGainMetrics
    let currentMetricType: ProductivityMetricType
    let showInsufficientData: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Metric icon
            Image(systemName: currentMetricType.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(showInsufficientData ? DesignSystem.Colors.tertiaryText : currentMetricType.color)
                .transition(.opacity.combined(with: .scale))
            
            // Main metric value
            if showInsufficientData {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("--")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    Text("Insufficient Data")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text(metrics.formattedValue(for: currentMetricType))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .transition(.opacity.combined(with: .scale))
                    
                    Text(currentMetricType.rawValue)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    if !metrics.comparisonPeriod.isEmpty && metrics.comparisonPeriod != "insufficient data" {
                        Text(metrics.comparisonPeriod)
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(showInsufficientData ? "Insufficient data available" : metrics.accessibilityLabel(for: currentMetricType))
        .accessibilityHint(showInsufficientData ? "Tap to cycle through metrics when data is available" : "Tap to cycle through different productivity metrics")
    }
}

// MARK: - Compact Metric Indicator

/// Shows a compact indicator for secondary metrics
struct CompactMetricIndicator: View {
    let metrics: ProductivityGainMetrics
    let metricType: ProductivityMetricType
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: metricType.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isActive ? metricType.color : DesignSystem.Colors.tertiaryText)
            
            if metrics.hasMinimumData {
                Text(metrics.formattedValue(for: metricType))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(isActive ? DesignSystem.Colors.primaryText : DesignSystem.Colors.tertiaryText)
            } else {
                Text("--")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .fill(isActive ? metricType.color.opacity(0.1) : DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .stroke(isActive ? metricType.color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(metrics.hasMinimumData ? metrics.accessibilityLabel(for: metricType) : "No data available for \(metricType.rawValue)")
    }
}

// MARK: - Main Productivity Gains Card

/// A comprehensive card displaying rotating productivity metrics with smooth animations
struct ProductivityGainsCard: View {
    let metrics: ProductivityGainMetrics
    
    @State private var currentMetricIndex: Int = 0
    @State private var rotationTimer: Timer?
    @State private var showInsufficientData: Bool = false
    
    private let rotationInterval: TimeInterval = 5.0 // 5 seconds
    private let metricTypes = ProductivityMetricType.allCases
    
    var body: some View {
        CardView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Header
                headerView
                
                // Main animated metric display
                AnimatedMetricDisplay(
                    metrics: metrics,
                    currentMetricType: metricTypes[currentMetricIndex],
                    showInsufficientData: showInsufficientData
                )
                .frame(minHeight: 120)
                .animation(.easeInOut(duration: 0.3), value: currentMetricIndex)
                .animation(.easeInOut(duration: 0.3), value: showInsufficientData)
                
                // Compact indicators for other metrics
                if metrics.hasMinimumData {
                    compactIndicatorsView
                }
                
                // Insufficient data message
                if showInsufficientData {
                    insufficientDataView
                }
            }
        }
        .onTapGesture {
            cycleToNextMetric()
        }
        .onAppear {
            updateDataState()
            startRotationTimer()
        }
        .onDisappear {
            stopRotationTimer()
        }
        .onChange(of: metrics.hasMinimumData) { _, _ in
            updateDataState()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Productivity Gains Card")
        .accessibilityHint("Displays rotating productivity metrics. Tap to cycle through different metrics.")
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: DesignSystem.Layout.iconSize, weight: .medium))
                .foregroundColor(DesignSystem.Colors.accent)
            
            Text("Productivity Gains")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Spacer()
            
            // Rotation indicator
            if metrics.hasMinimumData {
                Image(systemName: "arrow.2.circlepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .opacity(0.7)
            }
        }
    }
    
    // MARK: - Compact Indicators View
    
    private var compactIndicatorsView: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(metricTypes.indices, id: \.self) { index in
                CompactMetricIndicator(
                    metrics: metrics,
                    metricType: metricTypes[index],
                    isActive: index == currentMetricIndex
                )
                .animation(.easeInOut(duration: 0.2), value: currentMetricIndex)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Metric indicators showing current selection")
    }
    
    // MARK: - Insufficient Data View
    
    private var insufficientDataView: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("Need more data to show meaningful productivity gains")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Text("Continue using ConsciousMonitor to track your progress")
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Insufficient data available. Continue using ConsciousMonitor to track productivity gains.")
    }
    
    // MARK: - Private Methods
    
    private func updateDataState() {
        showInsufficientData = !metrics.hasMinimumData
        
        if showInsufficientData {
            stopRotationTimer()
        } else {
            startRotationTimer()
        }
    }
    
    private func startRotationTimer() {
        guard metrics.hasMinimumData else { return }
        
        stopRotationTimer()
        rotationTimer = Timer.scheduledTimer(withTimeInterval: rotationInterval, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                cycleToNextMetric()
            }
        }
    }
    
    private func stopRotationTimer() {
        rotationTimer?.invalidate()
        rotationTimer = nil
    }
    
    private func cycleToNextMetric() {
        currentMetricIndex = (currentMetricIndex + 1) % metricTypes.count
        
        // Reset timer when manually cycling
        if metrics.hasMinimumData {
            startRotationTimer()
        }
    }
}

// MARK: - Preview

#Preview("With Data") {
    ProductivityGainsCard(metrics: .sampleData)
        .frame(width: 320)
        .padding()
}

#Preview("Insufficient Data") {
    ProductivityGainsCard(metrics: .insufficientData)
        .frame(width: 320)
        .padding()
}

#Preview("Dark Mode") {
    ProductivityGainsCard(metrics: .sampleData)
        .frame(width: 320)
        .padding()
        .preferredColorScheme(.dark)
}