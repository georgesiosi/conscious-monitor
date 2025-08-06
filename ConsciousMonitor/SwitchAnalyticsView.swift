import SwiftUI
import Charts

// MARK: - Global Helper Functions

private func timeString(from timeInterval: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .abbreviated
    formatter.maximumUnitCount = 2
    return formatter.string(from: timeInterval) ?? "0s"
}

private func summaryCardView(title: String, value: String, color: Color, icon: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        Text(value)
            .font(.title2.bold())
            .foregroundColor(.primary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(Color(.windowBackgroundColor))
    .cornerRadius(10)
}

// MARK: - Identifiable Struct for Most Common Switches

struct CommonSwitchItem: Identifiable {
    let fromApp: String
    let toApp: String
    let count: Int
    
    var id: String { "\(fromApp)-\(toApp)" }
}

// MARK: - Switch Analytics View

struct SwitchAnalyticsView: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    @State private var selectedTimeRange: TimeRange = .today
    @State private var selectedSwitchType: SwitchType?
    @State private var selectedSwitch: ContextSwitchMetrics?
    @State private var showDetail = false
    
    // Use SharedTimeRange instead of local enum
    private typealias TimeRange = SharedTimeRange
    
    // MARK: - Helper Methods
    
    private var averageTimeSpent: String {
        guard !filteredSwitches.isEmpty else { return "0s" }
        let total = filteredSwitches.reduce(0) { $0 + $1.timeSpent }
        let average = total / Double(filteredSwitches.count)
        return timeString(from: average)
    }
    
    // NOTE: summaryCard function moved to top-level below timeString

    private var filteredSwitches: [ContextSwitchMetrics] {
        return activityMonitor.getContextSwitches(for: selectedTimeRange)
    }
    
    private var switchStats: (quick: Int, normal: Int, focused: Int) {
        return activityMonitor.getSwitchStatistics(for: selectedTimeRange)
    }
    
    private var mostCommonSwitchItems: [CommonSwitchItem] {
        activityMonitor.getMostCommonSwitches(limit: 5).map {
            CommonSwitchItem(fromApp: $0.from, toApp: $0.to, count: $0.count)
        }
    }
    
    private var switchTypeData: [(value: Double, color: Color, label: String)] {
        [
            (Double(switchStats.quick), Color.blue, "Quick"),
            (Double(switchStats.normal), Color.orange, "Normal"),
            (Double(switchStats.focused), Color.green, "Focused")
        ]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                // Header with time range filter
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Context Switch Analytics")
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("Track your app switching patterns")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    CompactTimeRangeFilter(selectedTimeRange: $selectedTimeRange)
                }
                .padding(.horizontal)
                
                // Summary cards
                SummaryCardsView(averageTimeSpent: averageTimeSpent, switchStats: switchStats)
                    .padding(.horizontal)
                
                // Switch timeline chart
                SwitchTimelineChartView(filteredSwitches: filteredSwitches, selectedSwitchType: selectedSwitchType)
                
                // Switch type distribution
                SwitchTypeDistributionView(switchTypeData: switchTypeData)
                
                // Most common switches
                SimpleMostCommonSwitchesView(switchesData: mostCommonSwitchItems, selectedSwitch: $selectedSwitch, showDetail: $showDetail)
                    .padding(.horizontal)
                
                // No need for Spacer in ScrollView
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Switch Analytics")
            .navigationDestination(for: ContextSwitchMetrics.self) { switchMetric in
                SwitchDetailAnalyticsView(activityMonitor: activityMonitor, selectedSwitch: .constant(switchMetric))
            }
            .toolbar {
                ToolbarItem {
                    // NavigationLink will be handled by .navigationDestination
                    // The button itself can trigger the state change for selectedSwitch if needed
                    // Or, rely on the list tap to set selectedSwitch, and .navigationDestination will pick it up.
                    // For simplicity, we can make the toolbar button also set a dummy switch or a specific one if desired,
                    // or remove it if the list items are the only way to navigate.
                    // Let's assume the list tap is the primary way. If a general "Detail" button is still needed without a specific switch,
                    // its logic would need to be rethought with the new NavigationStack style.
                    // For now, we remove the direct NavigationLink from here as it's tied to the list selection.
                    // If a generic detail view button is needed, it would set a specific state for that.
                    // We will rely on list items setting selectedSwitch and navigationDestination handling it.
                    // Thus, this ToolbarItem might become redundant if there's no other action.
                    // Let's keep it simple and remove it, assuming detail is only from list taps.
                    EmptyView() // Placeholder, effectively removing the old ToolbarItem's direct NavigationLink
                }
            }
        }
    }
}


// MARK: - Simple Most Common Switches View

struct SimpleMostCommonSwitchesView: View {
    let switchesData: [CommonSwitchItem]
    @Binding var selectedSwitch: ContextSwitchMetrics?
    @Binding var showDetail: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Most Common Switches")
                .font(.headline)
                .padding(.horizontal)
            
            if switchesData.isEmpty {
                ContentUnavailableView {
                    Label("No Common Switches", systemImage: "list.star")
                } description: {
                    Text("Not enough data to determine common app switches yet.")
                }
                .frame(height: 100) // Give some space for the message
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(switchesData, id: \.id) { switchDataItem in
                            HStack {
                                Text("\(switchDataItem.fromApp) → \(switchDataItem.toApp)")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(switchDataItem.count) switches")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.windowBackgroundColor).opacity(0.5))
                            .cornerRadius(8)
                            .contentShape(Rectangle()) // Make the whole row tappable
                            .onTapGesture {
                                // Navigation from this specific list item is currently not implemented.
                                // The main navigation happens from SwitchTimelineChartView or other detailed views.
                                // The selectedSwitch and showDetail bindings might be for a different, future interaction.
                                print("Tapped on common switch: \(switchDataItem.fromApp) to \(switchDataItem.toApp)")
                                // To enable navigation, we would need to find a representative ContextSwitchMetrics
                                // or navigate to a view that shows details for this specific *pair*.
                                // Example: if let representativeSwitch = activityMonitor.contextSwitches.first(where: { $0.fromApp == switchDataItem.fromApp && $0.toApp == switchDataItem.toApp }) {
                                //     selectedSwitch = representativeSwitch // This would trigger the .navigationDestination in SwitchAnalyticsView
                                // }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 200) // Set a fixed height for the scroll view
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Summary Cards View

struct SummaryCardsView: View {
    let averageTimeSpent: String
    let switchStats: (quick: Int, normal: Int, focused: Int)

    var body: some View {
        HStack(spacing: 12) {
            summaryCardView(title: "Avg. Time Spent", value: averageTimeSpent, color: .blue, icon: "clock.fill")
            summaryCardView(title: SwitchType.quick.rawValue.capitalized, value: "\(switchStats.quick)", color: SwitchType.quick.color, icon: SwitchType.quick.icon)
            summaryCardView(title: SwitchType.normal.rawValue.capitalized, value: "\(switchStats.normal)", color: SwitchType.normal.color, icon: SwitchType.normal.icon)
            summaryCardView(title: SwitchType.focused.rawValue.capitalized, value: "\(switchStats.focused)", color: SwitchType.focused.color, icon: SwitchType.focused.icon)
        }
        .frame(height: 100) // Give it some explicit height for now
    }
}

// MARK: - Switch Timeline Chart View

struct SwitchTimelineChartView: View {
    let filteredSwitches: [ContextSwitchMetrics]
    let selectedSwitchType: SwitchType?

    var body: some View {
        VStack(alignment: .leading) {
            Text("Switch Timeline")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(filteredSwitches) { switchEvent in
                    if selectedSwitchType == nil || switchEvent.switchType == selectedSwitchType {
                        BarMark(
                            x: .value("Time", switchEvent.timestamp),
                            y: .value("Duration", switchEvent.timeSpent / 60) // Convert to minutes
                        )
                        .foregroundStyle(switchEvent.switchType.color)
                        .cornerRadius(4)
                        .opacity(selectedSwitchType == nil || switchEvent.switchType == selectedSwitchType ? 1.0 : 0.3)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, style: .time)
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let minutes = value.as(Double.self) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            Text("\(Int(minutes))m")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(.windowBackgroundColor))
            .cornerRadius(10)
            .shadow(radius: 2)
            .padding(.horizontal)
        }
    }
}

// MARK: - Switch Type Distribution View

struct SwitchTypeDistributionView: View {
    let switchTypeData: [(value: Double, color: Color, label: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Switch Type Distribution")
                .font(.headline)
                .padding(.horizontal)
            
            PieChartView(
                data: switchTypeData,
                title: ""
            )
            .frame(height: 280)
            .padding()
            .background(Color(.windowBackgroundColor))
            .cornerRadius(10)
            .onTapGesture {
                // Handle tap on chart segments if needed
            }
            .padding(.horizontal)
        }
    }
}


// MARK: - Icon Resolver View

struct IconResolverView: View {
    let fromBundleId: String?
    let toBundleId: String?
    var size: CGFloat = 20 // Default size, matches usage

    @State private var fromImage: NSImage?
    @State private var toImage: NSImage?

    private var defaultAppIcon: NSImage {
        NSImage(named: NSImage.applicationIconName) ?? NSImage(size: NSSize(width: size, height: size))
    }

    var body: some View {
        Group {
            if let fromImage = fromImage {
                DualAppIconView(backgroundImage: fromImage, overlayImage: toImage ?? defaultAppIcon, size: size)
            } else {
                // Show placeholder if fromImage is still loading or failed
                DualAppIconView(backgroundImage: defaultAppIcon, overlayImage: toImage ?? defaultAppIcon, size: size)
            }
        }
        .task(id: fromBundleId) {
            await loadFromImage()
        }
        .task(id: toBundleId) {
            await loadToImage()
        }
    }

    private func loadImage(for bundleId: String?) async -> NSImage? {
        guard let bundleId = bundleId, !bundleId.isEmpty else { return nil }
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }
        return nil
    }

    private func loadFromImage() async {
        if let image = await loadImage(for: fromBundleId) {
            fromImage = image
        } else {
            // Explicitly set to default if fromBundleId was provided but image failed to load
            // If fromBundleId was nil/empty, fromImage remains nil (and body uses defaultAppIcon anyway)
            if fromBundleId != nil && !(fromBundleId?.isEmpty ?? true) {
                 fromImage = defaultAppIcon
            }
        }
    }

    private func loadToImage() async {
        toImage = await loadImage(for: toBundleId)
    }
}

// MARK: - Common Switches List View

struct CommonSwitchesListView: View {
    let commonSwitchPatterns: [(key: String, count: Int, fromApp: String, toApp: String, fromBundleId: String?, toBundleId: String?, averageTimeSpent: TimeInterval)]
    @ObservedObject var faviconFetcher: FaviconFetcher
    @Binding var selectedSwitch: ContextSwitchMetrics?

    private func timeString(from interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Most Common Switches")
                .font(.headline)
                .padding(.horizontal)
            
            List {
                ForEach(commonSwitchPatterns.prefix(10), id: \.key) { pattern in
                    Button(action: {
                        self.selectedSwitch = ContextSwitchMetrics(
                            fromApp: pattern.fromApp,
                            toApp: pattern.toApp,
                            fromBundleId: pattern.fromBundleId,
                            toBundleId: pattern.toBundleId,
                            timeSpent: pattern.averageTimeSpent
                        )
                    }) {
                        HStack {
                            IconResolverView(fromBundleId: pattern.fromBundleId, toBundleId: pattern.toBundleId, size: 20)
                                .frame(width: 40, height: 20)
                            
                            VStack(alignment: .leading) {
                                Text("\(pattern.fromApp) → \(pattern.toApp)")
                                    .font(.subheadline)
                                Text("Avg: \(timeString(from: pattern.averageTimeSpent))")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("\(pattern.count) switches")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(height: 300) // Adjust height as needed
            .background(Color(.windowBackgroundColor))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

// MARK: - Switch Type Card

struct SwitchTypeCard: View {
    let type: SwitchType
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle()
                        .fill(type.color)
                        .frame(width: 12, height: 12)
                    Spacer()
                }
                
                Text("\(count)")
                    .font(.title2.bold())
                
                Text(type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
            .background(isSelected ? type.color.opacity(0.1) : Color(.windowBackgroundColor))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SwitchDetailAnalyticsView: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    @Binding var selectedSwitch: ContextSwitchMetrics?
    
    var body: some View {
        if let selectedSwitch = selectedSwitch {
            VStack(alignment: .leading, spacing: 20) {
                Text("Switch Details")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("From App: \(selectedSwitch.fromApp)")
                        .font(.subheadline)
                    
                    Text("To App: \(selectedSwitch.toApp)")
                        .font(.subheadline)
                    
                    Text("Time Spent: \(timeString(from: selectedSwitch.timeSpent))")
                        .font(.subheadline)
                    
                    Text("Timestamp: \(selectedSwitch.timestamp, formatter: dateFormatter)")
                        .font(.subheadline)
                    
                    Text("Switch Type: \(selectedSwitch.switchType.rawValue.capitalized)")
                        .font(.subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(10)
            }
            .padding()
        } else {
            Text("No switch selected")
                .font(.headline)
        }
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Preview

struct SwitchAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        let monitor = ActivityMonitor()
        let now = Date()
        let calendar = Calendar.current
        
        // Add sample data for different switch types
        let apps = [
            ("Safari", "com.apple.Safari"),
            ("Xcode", "com.apple.dt.Xcode"),
            ("Messages", "com.apple.MobileSMS"),
            ("Slack", "com.tinyspeck.slackmacgap"),
            ("Mail", "com.apple.mail"),
            ("Terminal", "com.apple.Terminal"),
            ("Notes", "com.apple.Notes"),
            ("Calendar", "com.apple.iCal")
        ]
        
        // Generate random switch events
        for i in 0..<50 {
            let minutesAgo = TimeInterval(i * Int.random(in: 1...30))
            _ = calendar.date(byAdding: .minute, value: -Int(minutesAgo), to: now)!
            
            let fromApp = apps.randomElement()!
            var toApp = apps.randomElement()!
            
            // Ensure we don't have a switch to the same app
            while fromApp.0 == toApp.0 && apps.count > 1 {
                toApp = apps.randomElement()!
            }
            
            // Generate time spent with different distributions for switch types
            let timeSpent: TimeInterval
            let switchType = Double.random(in: 0...1)
            
            if switchType < 0.3 {
                // Rapid switches (0-30s)
                timeSpent = TimeInterval.random(in: 5...30)
            } else if switchType < 0.8 {
                // Normal switches (30s - 5min)
                timeSpent = TimeInterval.random(in: 30...300)
            } else {
                // Extended switches (5-15min)
                timeSpent = TimeInterval.random(in: 300...900)
            }
            
            let switchMetric = ContextSwitchMetrics(
                fromApp: fromApp.0,
                toApp: toApp.0,
                fromBundleId: fromApp.1,
                toBundleId: toApp.1,
                timeSpent: timeSpent
            )
            
            monitor.addContextSwitch(switchMetric)
        }
        
        // Add some common patterns
        for _ in 0..<10 {
            let timeSpent = TimeInterval.random(in: 30...120)
            
            // Common pattern: Switching between code editor and browser
            let browserSwitch = ContextSwitchMetrics(
                fromApp: "Xcode",
                toApp: "Safari",
                fromBundleId: "com.apple.dt.Xcode",
                toBundleId: "com.apple.Safari",
                timeSpent: timeSpent
            )
            
            monitor.addContextSwitch(browserSwitch)
            
            // Common pattern: Switching between messaging and work
            let messageSwitch = ContextSwitchMetrics(
                fromApp: "Slack",
                toApp: "Xcode",
                fromBundleId: "com.tinyspeck.slackmacgap",
                toBundleId: "com.apple.dt.Xcode",
                timeSpent: TimeInterval.random(in: 10...30)
            )
            
            monitor.addContextSwitch(messageSwitch)
        }
        
        // Set the last app switch for the preview
        if let lastSwitch = monitor.contextSwitches.last {
            monitor.lastAppSwitch = (name: lastSwitch.fromApp, 
                                   timestamp: lastSwitch.timestamp,
                                   bundleId: lastSwitch.fromBundleId, 
                                   category: lastSwitch.fromCategory)
        }
        
        return SwitchAnalyticsView(activityMonitor: monitor)
            .frame(width: 800, height: 900)
            .preferredColorScheme(.dark)
    }
}
