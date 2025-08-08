import SwiftUI

struct FloatingFocusView: View {
    @ObservedObject var activityMonitor: ActivityMonitor

    // Computed property to get the top 5 most frequently activated apps in the last hour
    private var topAppsLastHour: [String] {
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
        
        let recentEvents = activityMonitor.activationEvents.filter { $0.timestamp >= oneHourAgo }
        
        let appFrequencies = Dictionary(grouping: recentEvents, by: { $0.appName })
            .mapValues { $0.count }
        
        let sortedAppKeys: [String] = appFrequencies.sorted { $0.value > $1.value }
            .map { $0.key } // Should be [String]
            .compactMap { $0 } // Add compactMap to ensure non-optional strings, in case of compiler confusion
            
        if sortedAppKeys.count > 5 {
            return Array(sortedAppKeys[0..<5]) // Take the first 5 elements
        } else {
            return sortedAppKeys // If fewer than 5, return all of them
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Focus Activity (Last Hour)")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)

            if topAppsLastHour.isEmpty {
                Text("No app activity recorded in the last hour.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            } else {
                ForEach(topAppsLastHour, id: \.self) { appName in
                    HStack {
                        Text(appName)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        Spacer()
                        // Placeholder for usage time or frequency count later
                        // Text("X min") 
                        //    .font(.caption)
                        //    .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius))
    }
}

struct FloatingFocusView_Previews: PreviewProvider {
    static var previews: some View {
        FloatingFocusView(activityMonitor: ActivityMonitor()) // Pass a dummy ActivityMonitor
    }
}
