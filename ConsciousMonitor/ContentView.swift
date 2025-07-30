import SwiftUI

struct ContentView: View {
    // Observe the ActivityMonitor instance passed from the App
    @ObservedObject var activityMonitor: ActivityMonitor
    @Environment(\.openWindow) var openWindow // Reinstate environment variable

    // State variable for selected tab
    @State private var selectedTab: Int = 0
    
    // Consolidated tab structure - 5 logical groups
    private enum Tab: Int {
        case activity = 0
        case analytics = 1   // Consolidates switch analytics, usage stack, and cost analysis
        case stackHealth = 2 // CSD Framework compliance and stack health
        case insights = 3    // AI insights
        case settings = 4
    }


    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Tab 1: Activity Log
                ModernActivityView(activityMonitor: activityMonitor)
                    .tabItem {
                        Label("Activity", systemImage: "list.bullet")
                    }
                    .tag(Tab.activity.rawValue)
                
                // Tab 2: Analytics (Consolidated)
                ModernAnalyticsTabView(activityMonitor: activityMonitor)
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar")
                    }
                    .tag(Tab.analytics.rawValue)
                
                // Tab 3: Stack Health (CSD Framework)
                StackHealthView(activityMonitor: activityMonitor)
                    .tabItem {
                        Label("Stack Health", systemImage: "heart.circle")
                    }
                    .tag(Tab.stackHealth.rawValue)
                
                // Tab 4: AI Insights
                ModernAIInsightsView(activityMonitor: activityMonitor)
                    .tabItem {
                        Label("Insights", systemImage: "brain.head.profile")
                    }
                    .tag(Tab.insights.rawValue)
                
                // Tab 5: Settings
                SidebarSettingsView()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(Tab.settings.rawValue)
            }
            
            // Data error alert overlay
            DataErrorAlert(activityMonitor: activityMonitor)
        } // End ZStack
        .background(DesignSystem.Colors.contentBackground.ignoresSafeArea())
        .frame(
            minWidth: DesignSystem.Layout.minWindowWidth,
            idealWidth: DesignSystem.Layout.idealWindowWidth,
            maxWidth: .infinity,
            minHeight: DesignSystem.Layout.minWindowHeight,
            idealHeight: DesignSystem.Layout.idealWindowHeight,
            maxHeight: .infinity
        )
        .onAppear { // Reinstate this block
            // Open the floating focus window when the ContentView appears
            // openWindow(id: "floating-focus-window") // Temporarily comment this out
        }
    }
}

// Helper view for displaying a single event row (extracted for clarity)
struct EventRow: View {
    let event: AppActivationEvent
    @State private var isHovered = false
    @State private var favicon: NSImage? = nil
    @State private var faviconLoadTask: Task<Void, Never>?
    @ObservedObject private var userSettings = UserSettings.shared
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = userSettings.showSecondsInTimestamps ? "h:mm:ss a" : "h:mm a"
        return formatter
    }

    var body: some View {
        HStack {
            if event.bundleIdentifier == "com.google.Chrome" {
                let actualChromeIcon = event.appIcon ?? NSImage(named: "chrome") ?? NSImage(systemSymbolName: "globe", accessibilityDescription: "Chrome fallback") ?? NSImage(size: NSSize(width: 20, height: 20))
                let favicon = event.siteFavicon ?? NSImage(named: "favicon_placeholder") ?? NSImage(systemSymbolName: "square.on.square", accessibilityDescription: "Favicon Placeholder") ?? NSImage(size: NSSize(width: 20, height: 20))
                DualAppIconView(backgroundImage: actualChromeIcon, overlayImage: favicon, size: 20)
            } else if let nsIcon = event.appIcon {
                Image(nsImage: nsIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "app.dashed")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            VStack(alignment: .leading) {
                Text(event.appName ?? "Unknown App")
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(event.category.name)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)

                if let tabTitle = event.chromeTabTitle {
                    Text(tabTitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(timeFormatter.string(from: event.timestamp))
                .font(DesignSystem.Typography.monospacedDigit)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
    }
}

// Preview needs adjustment as it now requires an ActivityMonitor
/*
#Preview {
    ContentView(activityMonitor: ActivityMonitor())
}
*/
