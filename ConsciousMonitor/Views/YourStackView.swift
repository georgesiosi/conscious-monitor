import SwiftUI

struct YourStackView: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    let selectedTimeRange: SharedTimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Stack: \(selectedTimeRange.rawValue)")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 4)
            
            if topToolsPerCategory.isEmpty {
                Text("No tools found for this time range")
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(topToolsPerCategory, id: \.bundleIdentifier) { tool in
                            ToolCardView(tool: tool)
                                .frame(width: 160, height: 160)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }
    
    // Filter events by selected time range and generate stats
    private var filteredEvents: [AppActivationEvent] {
        return selectedTimeRange.filterEvents(activityMonitor.activationEvents, timestampKeyPath: \.timestamp)
    }
    
    // Generate app usage stats from filtered events
    private var filteredAppUsageStats: [AppUsageStat] {
        return activityMonitor.analyticsService.generateAppUsageStats(from: filteredEvents)
    }
    
    // Get most used app per category from filtered data
    private var topToolsPerCategory: [AppUsageStat] {
        let allStats = filteredAppUsageStats
        
        // Group by category name
        var categoryGroups: [String: [AppUsageStat]] = [:]
        for stat in allStats {
            let categoryName = stat.category.name
            categoryGroups[categoryName, default: []].append(stat)
        }
        
        // Get the top tool from each category
        var topTools: [AppUsageStat] = []
        for (_, stats) in categoryGroups {
            if let topTool = stats.max(by: { $0.activationCount < $1.activationCount }) {
                topTools.append(topTool)
            }
        }
        
        return topTools.sorted { $0.activationCount > $1.activationCount }
    }
}

struct ToolCardView: View {
    let tool: AppUsageStat
    
    var body: some View {
        VStack(spacing: 8) {
            if let appIcon = tool.appIcon {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                    .frame(width: 64, height: 64)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text(tool.appName)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            
            Text("\(tool.activationCount) uses")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(tool.category.name)
                .font(.caption2)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(tool.category.color.opacity(0.2))
                .foregroundColor(tool.category.color)
                .cornerRadius(6)
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}