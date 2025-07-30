import SwiftUI

// MARK: - Chrome Usage Row View
struct ChromeUsageRow: View {
    let stat: AppUsageStat
    let siteBreakdown: [SiteUsageStat]
    
    var body: some View {
        DisclosureGroup {
            // Content of DisclosureGroup: Site breakdown
            ForEach(siteBreakdown) { siteStat in
                HStack {
                    if let siteFavicon = siteStat.siteFavicon {
                        Image(nsImage: siteFavicon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "network") // Placeholder if no favicon
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Text(siteStat.displayTitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(siteStat.activationCount) visits")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.leading, 20) // Indent site breakdown items
            }
        } label: {
            // Label of DisclosureGroup: Main Chrome row
            HStack {
                let actualChromeIcon = stat.appIcon ?? NSImage(named: "chrome") ?? NSImage(systemSymbolName: "globe", accessibilityDescription: "Chrome fallback") ?? NSImage(size: NSSize(width: 22, height: 22))
                let favicon = siteBreakdown.first?.siteFavicon ?? NSImage(named: "favicon_placeholder") ?? NSImage(systemSymbolName: "square.on.square", accessibilityDescription: "Favicon Placeholder") ?? NSImage(size: NSSize(width: 22, height: 22))
                DualAppIconView(backgroundImage: actualChromeIcon, overlayImage: favicon, size: 22)
                Text(stat.appName)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Text("\(stat.activationCount) activations")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Standard App Row View
struct StandardAppRow: View {
    let stat: AppUsageStat
    
    var body: some View {
        HStack {
            if let nsIcon = stat.appIcon {
                Image(nsImage: nsIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
            } else {
                Image(systemName: "app.dashed")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .foregroundColor(.white.opacity(0.4))
            }
            Text(stat.appName)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            Spacer()
            Text("\(stat.activationCount) activations")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Enhanced Rows with CSD Compliance
struct StandardAppRowWithCompliance: View {
    let stat: AppUsageStat
    @ObservedObject var activityMonitor: ActivityMonitor
    
    var body: some View {
        HStack {
            if let nsIcon = stat.appIcon {
                Image(nsImage: nsIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
            } else {
                Image(systemName: "app.dashed")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .foregroundColor(.white.opacity(0.4))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(stat.appName)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                
                HStack(spacing: 4) {
                    Text(stat.category.name)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    if let categoryMetric = getCategoryMetric(for: stat.category) {
                        CSDComplianceBadge(status: categoryMetric.compliance)
                    }
                }
            }
            
            Spacer()
            
            Text("\(stat.activationCount) activations")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private func getCategoryMetric(for category: AppCategory) -> CategoryUsageMetrics? {
        return activityMonitor.getCategoryUsageMetrics().first { $0.category == category }
    }
}

struct ChromeUsageRowWithCompliance: View {
    let stat: AppUsageStat
    let siteBreakdown: [SiteUsageStat]
    @ObservedObject var activityMonitor: ActivityMonitor
    
    var body: some View {
        DisclosureGroup {
            // Content of DisclosureGroup: Site breakdown
            ForEach(siteBreakdown) { siteStat in
                HStack {
                    if let siteFavicon = siteStat.siteFavicon {
                        Image(nsImage: siteFavicon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "network") // Placeholder if no favicon
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Text(siteStat.displayTitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(siteStat.activationCount) visits")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.leading, 20) // Indent site breakdown items
            }
        } label: {
            // Label of DisclosureGroup: Main Chrome row with compliance
            HStack {
                let actualChromeIcon = stat.appIcon ?? NSImage(named: "chrome") ?? NSImage(systemSymbolName: "globe", accessibilityDescription: "Chrome fallback") ?? NSImage(size: NSSize(width: 22, height: 22))
                let favicon = siteBreakdown.first?.siteFavicon ?? NSImage(named: "favicon_placeholder") ?? NSImage(systemSymbolName: "square.on.square", accessibilityDescription: "Favicon Placeholder") ?? NSImage(size: NSSize(width: 22, height: 22))
                DualAppIconView(backgroundImage: actualChromeIcon, overlayImage: favicon, size: 22)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.appName)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack(spacing: 4) {
                        Text(stat.category.name)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        if let categoryMetric = getCategoryMetric(for: stat.category) {
                            CSDComplianceBadge(status: categoryMetric.compliance)
                        }
                    }
                }
                
                Spacer()
                Text("\(stat.activationCount) activations")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private func getCategoryMetric(for category: AppCategory) -> CategoryUsageMetrics? {
        return activityMonitor.getCategoryUsageMetrics().first { $0.category == category }
    }
}

struct UsageStackView: View {
    @ObservedObject var activityMonitor: ActivityMonitor

    var body: some View {
        ZStack {
            // Dark background color
            Color(red: 0.02, green: 0.02, blue: 0.04).ignoresSafeArea()

            VStack(alignment: .leading) {
                    Text("Application Usage Stack")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9)) // Light text
                        .padding(.bottom)

                    if activityMonitor.appUsageStats.isEmpty {
                        EmptyStateView(
                            "No Usage Data",
                            subtitle: "Start using apps to see your usage breakdown here.",
                            systemImage: "chart.bar.xaxis"
                        )
                        .frame(minHeight: 200)
                    } else {
                        List(activityMonitor.appUsageStats) { stat in
                            if stat.bundleIdentifier == "com.google.Chrome", 
                               let siteBreakdown = stat.siteBreakdown, 
                               !siteBreakdown.isEmpty {
                                ChromeUsageRowWithCompliance(stat: stat, siteBreakdown: siteBreakdown, activityMonitor: activityMonitor)
                            } else {
                                StandardAppRowWithCompliance(stat: stat, activityMonitor: activityMonitor)
                            }
                        }
                        .listStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding() // Add padding to the VStack content inside the ZStack
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Make ZStack (and thus UsageStackView) full width with leading alignment
            .navigationTitle("App Usage Stack") // Or just .listStyle(PlainListStyle()) if not in NavigationView
    }
}

struct UsageStackView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock ActivityMonitor for preview purposes
        let mockMonitor = ActivityMonitor()
        // Populate with some mock data
        mockMonitor.activationEvents = [
            AppActivationEvent(id: UUID(), timestamp: Date(), appName: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", category: CategoryManager.shared.getCategory(for: "com.apple.dt.Xcode")),
            AppActivationEvent(id: UUID(), timestamp: Date(), appName: "Google Chrome", bundleIdentifier: "com.google.Chrome", category: CategoryManager.shared.getCategory(for: "com.google.Chrome")),
            AppActivationEvent(id: UUID(), timestamp: Date(), appName: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", category: CategoryManager.shared.getCategory(for: "com.apple.dt.Xcode")),
            AppActivationEvent(id: UUID(), timestamp: Date(), appName: "Finder", bundleIdentifier: "com.apple.finder", category: CategoryManager.shared.getCategory(for: "com.apple.finder")),
            AppActivationEvent(id: UUID(), timestamp: Date(), appName: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", category: CategoryManager.shared.getCategory(for: "com.apple.dt.Xcode"))
        ]
        return UsageStackView(activityMonitor: mockMonitor)
    }
}
