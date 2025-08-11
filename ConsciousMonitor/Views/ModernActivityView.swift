import SwiftUI

struct ActivityView: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    @State private var selectedView: ViewType = .chronological
    @State private var selectedEventForCategorization: AppActivationEvent?
    @State private var selectedEventForDomainCategorization: AppActivationEvent?
    @State private var showDetailedStats = false
    
    // Search functionality
    @State private var searchText: String = ""
    
    // Pagination functionality
    @State private var currentPage: Int = 0
    @State private var isLoadingMore: Bool = false
    
    // Constants
    private let pageSize: Int = 50
    private let loadMoreThreshold: Int = 10
    
    enum ViewType: String, CaseIterable, Identifiable {
        case chronological = "Chronological"
        case byApp = "By App"
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .chronological: return "clock"
            case .byApp: return "folder"
            }
        }
    }
    
    // Computed property for filtered events based on search
    private var filteredEvents: [AppActivationEvent] {
        guard !searchText.isEmpty else {
            return activityMonitor.activationEvents
        }
        
        let lowercaseSearch = searchText.lowercased()
        return activityMonitor.activationEvents.filter { event in
            // Search in display name (which includes Chrome tab titles)
            if event.displayName.lowercased().contains(lowercaseSearch) {
                return true
            }
            
            // Search in bundle identifier
            if let bundleId = event.bundleIdentifier, bundleId.lowercased().contains(lowercaseSearch) {
                return true
            }
            
            // Search in Chrome tab title
            if let tabTitle = event.chromeTabTitle, tabTitle.lowercased().contains(lowercaseSearch) {
                return true
            }
            
            // Search in Chrome tab URL
            if let tabUrl = event.chromeTabUrl, tabUrl.lowercased().contains(lowercaseSearch) {
                return true
            }
            
            // Search in site domain
            if let siteDomain = event.siteDomain, siteDomain.lowercased().contains(lowercaseSearch) {
                return true
            }
            
            // Search in category name
            if event.category.name.lowercased().contains(lowercaseSearch) {
                return true
            }
            
            return false
        }
    }
    
    // Computed property for paginated events - NO STATE MODIFICATION
    private var paginatedEvents: [AppActivationEvent] {
        let maxItems = (currentPage + 1) * pageSize
        let sortedEvents = filteredEvents.sorted { $0.timestamp > $1.timestamp }
        
        // Don't modify state here - just return the data
        if sortedEvents.count <= maxItems {
            return sortedEvents
        } else {
            return Array(sortedEvents.prefix(maxItems))
        }
    }
    
    // Computed property to check if more data is available
    private var hasMoreDataAvailable: Bool {
        let maxItems = (currentPage + 1) * pageSize
        return filteredEvents.count > maxItems
    }
    
    // Computed property for grouped and sorted events by app name (now uses filtered events)
    private var sortedGroupedEvents: [(key: String, value: [AppActivationEvent])] {
        let paginatedData = paginatedEvents
        let grouped = Dictionary(grouping: paginatedData, by: { $0.appName ?? "Unknown App" })
        return grouped
            .mapValues { events in
                events.sorted { $0.timestamp > $1.timestamp }
            }
            .sorted { $0.key < $1.key }
    }
    
    // Computed property for search result count
    private var searchResultCount: Int {
        return filteredEvents.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Page header with edge-to-edge card background
            VStack(spacing: DesignSystem.Layout.titleSpacing) {
                // App branding and primary info
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Conscious Monitor")
                            .font(DesignSystem.Typography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("powered by [Conscious Stack Design](https://consciousstack.com)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .accentColor(DesignSystem.Colors.accent)
                    }
                    
                    Spacer()
                    
                    // Condensed stats with expand button
                    VStack(alignment: .trailing, spacing: DesignSystem.Spacing.sm) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Text("\(activityMonitor.appActivationsInLast5Minutes)")
                                .font(DesignSystem.Typography.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.accent)
                            
                            Text("recent")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showDetailedStats.toggle()
                                }
                            }) {
                                Image(systemName: showDetailedStats ? "chevron.up.circle.fill" : "chevron.down.circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(DesignSystem.Colors.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Expandable detailed stats
                if showDetailedStats {
                    HStack(spacing: DesignSystem.Spacing.lg) {
                        QuickStatView(
                            title: "Recent Activity",
                            value: "\(activityMonitor.appActivationsInLast5Minutes)",
                            subtitle: "last 5 min",
                            icon: "clock.fill",
                            color: DesignSystem.Colors.accent
                        )
                        
                        QuickStatView(
                            title: "Total Events",
                            value: "\(activityMonitor.activationEvents.count)",
                            subtitle: "all time",
                            icon: "infinity",
                            color: DesignSystem.Colors.success
                        )
                        
                        QuickStatView(
                            title: "Focus Score",
                            value: "\(Int((100.0 - min(Double(activityMonitor.contextSwitchesToday) / 30.0 * 100.0, 100.0))))%",
                            subtitle: "today",
                            icon: "target",
                            color: activityMonitor.contextSwitchesToday < 30 ? DesignSystem.Colors.success : DesignSystem.Colors.warning
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Focus State Indicator (Enhanced)
                ModernFocusStateCard(focusStateDetector: activityMonitor.focusStateDetector)
            }
            .padding(.top, DesignSystem.Layout.pageHeaderPadding)
            .padding(.horizontal, DesignSystem.Layout.contentPadding)
            .padding(.bottom, DesignSystem.Layout.contentPadding)
            .background(DesignSystem.Colors.cardBackground)
            
            // Scrollable content section
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Search Bar
                    ActivitySearchBar(
                        searchText: $searchText,
                        resultCount: searchResultCount,
                        totalCount: activityMonitor.activationEvents.count
                    )
                    .padding(.horizontal, DesignSystem.Layout.contentPadding)
                    .padding(.top, DesignSystem.Layout.titleSpacing)
                    .onChange(of: searchText) {
                        resetPagination()
                    }
                    
                    // Section Header with View Picker
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Recent Activity")
                                .font(DesignSystem.Typography.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            if !searchText.isEmpty {
                                SearchResultsHeader(
                                    searchText: searchText,
                                    resultCount: searchResultCount,
                                    isLoading: isLoadingMore
                                )
                            } else {
                                Text("Track your app activations and context switches")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        // View type picker
                        Picker("View Type", selection: $selectedView) {
                            ForEach(ViewType.allCases) { viewType in
                                Label(viewType.rawValue, systemImage: viewType.icon)
                                    .tag(viewType)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                        .onChange(of: selectedView) {
                            resetPagination()
                        }
                    }
                    .padding(.horizontal, DesignSystem.Layout.contentPadding)
                    
                    // Activity List
                    if activityMonitor.activationEvents.isEmpty {
                        EmptyStateView(
                            "No Activity Yet",
                            subtitle: "Start using your Mac and app activations will appear here",
                            systemImage: "clock.arrow.circlepath"
                        )
                        .frame(maxHeight: .infinity)
                    } else if filteredEvents.isEmpty {
                        EmptyStateView(
                            "No Results Found",
                            subtitle: "No apps match '\(searchText)'. Try a different search term.",
                            systemImage: "magnifyingglass"
                        )
                        .frame(maxHeight: .infinity)
                    } else {
                        LazyVStack(spacing: DesignSystem.Spacing.md) {
                            if selectedView == .chronological {
                                ForEach(Array(paginatedEvents.enumerated()), id: \.element.id) { index, event in
                                    ModernEventRow(
                                        event: event,
                                        onTap: {
                                            selectedEventForCategorization = event
                                        },
                                        onTabTitleTap: event.bundleIdentifier == "com.google.Chrome" ? {
                                            selectedEventForDomainCategorization = event
                                        } : nil
                                    )
                                    .onAppear {
                                        checkForLoadMore(at: index)
                                    }
                                }
                            } else {
                                ForEach(sortedGroupedEvents, id: \.key) { appName, events in
                                    ModernAppGroupCard(
                                        appName: appName, 
                                        events: events,
                                        onEventTap: { event in
                                            selectedEventForCategorization = event
                                        },
                                        onDomainTap: { event in
                                            selectedEventForDomainCategorization = event
                                        }
                                    )
                                }
                            }
                            
                            // Loading indicator
                            if isLoadingMore {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Loading more results...")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                .padding(.vertical, DesignSystem.Spacing.md)
                            } else if !hasMoreDataAvailable && paginatedEvents.count > pageSize {
                                Text("End of results")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                                    .padding(.vertical, DesignSystem.Spacing.md)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Layout.contentPadding)
                        .padding(.bottom, DesignSystem.Layout.contentPadding)
                    }
                }
            }
        }
        .sheet(item: $selectedEventForCategorization) { event in
            CategoryPickerSheet(event: event, activityMonitor: activityMonitor, isDomainCategorization: false)
        }
        .sheet(item: $selectedEventForDomainCategorization) { event in
            CategoryPickerSheet(event: event, activityMonitor: activityMonitor, isDomainCategorization: true)
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetPagination() {
        DispatchQueue.main.async {
            currentPage = 0
            isLoadingMore = false
        }
    }
    
    private func checkForLoadMore(at index: Int) {
        let remainingItems = paginatedEvents.count - index
        if remainingItems <= loadMoreThreshold && hasMoreDataAvailable && !isLoadingMore {
            loadMoreEvents()
        }
    }
    
    private func loadMoreEvents() {
        guard hasMoreDataAvailable && !isLoadingMore else { return }
        
        isLoadingMore = true
        
        // Simulate loading delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentPage += 1
            isLoadingMore = false
        }
    }
}

// MARK: - Quick Stat View Component

struct QuickStatView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(DesignSystem.Typography.title2)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(width: 120, height: 80)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Modern Focus State Card

struct ModernFocusStateCard: View {
    @ObservedObject var focusStateDetector: FocusStateDetector
    @State private var showingDetails = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Focus state indicator
            HStack(spacing: DesignSystem.Spacing.md) {
                Circle()
                    .fill(focusStateColor)
                    .frame(width: 16, height: 16)
                    .shadow(color: focusStateColor.opacity(0.3), radius: 3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(focusStateDetector.currentFocusState.rawValue)
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(focusStateDetector.currentFocusState.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Metrics
            if focusStateDetector.switchingVelocity > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(String(format: "%.1f", focusStateDetector.switchingVelocity))")
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("switches/min")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
            
            Button(action: { showingDetails.toggle() }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.Layout.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius)
                .stroke(focusStateColor.opacity(0.3), lineWidth: 1)
        )
        .popover(isPresented: $showingDetails) {
            FocusStateDetailsView(focusStateDetector: focusStateDetector)
        }
        .animation(.easeInOut(duration: 0.3), value: focusStateDetector.currentFocusState)
    }
    
    private var focusStateColor: Color {
        switch focusStateDetector.currentFocusState {
        case .deepFocus: return DesignSystem.Colors.success
        case .focused: return DesignSystem.Colors.accent
        case .scattered: return DesignSystem.Colors.warning
        case .overloaded: return DesignSystem.Colors.error
        }
    }
}

// MARK: - Modern Event Row

struct ModernEventRow: View {
    let event: AppActivationEvent
    let onTap: () -> Void // App categorization callback
    let onTabTitleTap: (() -> Void)? // Domain categorization callback (Chrome only)
    @State private var isHovered = false
    @ObservedObject private var userSettings = UserSettings.shared
    
    // Default icons for fallback
    private var defaultAppIcon: NSImage {
        NSImage(systemSymbolName: "app.fill", accessibilityDescription: "App") ?? NSImage()
    }
    
    private var defaultChromeIcon: NSImage {
        NSImage(systemSymbolName: "network", accessibilityDescription: "Browser") ?? NSImage()
    }
    
    private var defaultFaviconIcon: NSImage {
        NSImage(systemSymbolName: "globe", accessibilityDescription: "Website") ?? NSImage()
    }
    
    init(event: AppActivationEvent, onTap: @escaping () -> Void, onTabTitleTap: (() -> Void)? = nil) {
        self.event = event
        self.onTap = onTap
        self.onTabTitleTap = onTabTitleTap
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = userSettings.showSecondsInTimestamps ? "h:mm:ss a" : "h:mm a"
        return formatter
    }
    
    private var isClickableTabTitle: Bool {
        event.bundleIdentifier == "com.google.Chrome" && onTabTitleTap != nil
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
                // App icon
                if event.bundleIdentifier == "com.google.Chrome" {
                    let chromeIcon = event.appIcon ?? defaultChromeIcon
                    let favicon = event.siteFavicon ?? defaultFaviconIcon
                    DualAppIconView(backgroundImage: chromeIcon, overlayImage: favicon, size: 32)
                } else if let appIcon = event.appIcon {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .cornerRadius(6)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 24))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .frame(width: 32, height: 32)
                }
                
                // Event details
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        // Event display name (no longer clickable)
                        Text(event.displayName)
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Text(timeFormatter.string(from: event.timestamp))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                    
                    HStack {
                        // Category badge (clickable for quick categorization)
                        Button(action: {
                            onTap() // Trigger categorization sheet
                        }) {
                            Text(event.displaySubtitle)
                                .font(DesignSystem.Typography.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, 2)
                                .background(event.category.color)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .help("Click to change category")
                        
                        Spacer()
                    }
                }
            }
        .padding(DesignSystem.Spacing.md)
        .background(isHovered ? DesignSystem.Colors.hoverBackground : DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .stroke(DesignSystem.Colors.tertiaryText.opacity(0.1), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            if event.bundleIdentifier == "com.google.Chrome" {
                // Chrome-specific context menu with dual categorization options
                Button("Categorize Chrome App") {
                    onTap() // Existing app categorization callback
                }
                
                if let domain = event.siteDomain, !domain.isEmpty {
                    Button("Categorize \(domain)") {
                        onTabTitleTap?() // Domain categorization callback
                    }
                }
                
                Divider()
            }
            
            // Standard categorization option for all apps
            Button("Categorize App") {
                onTap()
            }
        }
    }
}

// MARK: - Modern App Group Card

struct ModernAppGroupCard: View {
    let appName: String
    let events: [AppActivationEvent]
    let onEventTap: (AppActivationEvent) -> Void
    let onDomainTap: (AppActivationEvent) -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: { withAnimation(.easeInOut(duration: 0.3)) { isExpanded.toggle() } }) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    // App icon (from first event)
                    if let firstEvent = events.first, let appIcon = firstEvent.appIcon {
                        Image(nsImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .cornerRadius(4)
                    } else {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 18))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .frame(width: 24, height: 24)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appName)
                            .font(DesignSystem.Typography.headline)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("\(events.count) activations")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                .padding(DesignSystem.Spacing.md)
            }
            .buttonStyle(.plain)
            
            // Expandable content
            if isExpanded {
                Divider()
                
                LazyVStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(events) { event in
                        ModernEventRow(
                            event: event,
                            onTap: {
                                onEventTap(event)
                            },
                            onTabTitleTap: event.bundleIdentifier == "com.google.Chrome" ? {
                                onDomainTap(event)
                            } : nil
                        )
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                }
                .padding(.bottom, DesignSystem.Spacing.md)
            }
        }
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.Layout.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius)
                .stroke(DesignSystem.Colors.tertiaryText.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Category Picker Sheet

struct CategoryPickerSheet: View {
    let event: AppActivationEvent
    let activityMonitor: ActivityMonitor
    let isDomainCategorization: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        let chartDataForPicker = AppSwitchChartData(
            appName: event.appName ?? "Unknown App",
            bundleIdentifier: event.bundleIdentifier,
            activationCount: 1,
            category: event.category
        )
        
        CategoryPickerView(
            initialCategory: event.category,
            appToCategorize: chartDataForPicker,
            chromeDomain: isDomainCategorization ? event.siteDomain : nil,
            onSave: { newCategory, bundleId in
                if let validBundleId = bundleId, !validBundleId.isEmpty {
                    CategoryManager.shared.setCategoryForApp(bundleIdentifier: validBundleId, category: newCategory)
                    
                    var updatedEvents = [AppActivationEvent]()
                    for var event in activityMonitor.activationEvents {
                        if event.bundleIdentifier == validBundleId {
                            event.category = newCategory
                        }
                        updatedEvents.append(event)
                    }
                    activityMonitor.activationEvents = updatedEvents
                    activityMonitor.refreshDueToCategoryChange()
                }
                dismiss()
            },
            onSaveDomain: isDomainCategorization ? { newCategory, domain in
                // Save domain-specific category
                CategoryManager.shared.setCategoryForDomain(domain, category: newCategory)
                
                // Update all Chrome events with this domain to use the new category
                var updatedEvents = [AppActivationEvent]()
                for var event in activityMonitor.activationEvents {
                    if event.bundleIdentifier == "com.google.Chrome" && event.siteDomain == domain {
                        event.category = newCategory
                    }
                    updatedEvents.append(event)
                }
                activityMonitor.activationEvents = updatedEvents
                activityMonitor.refreshDueToCategoryChange()
                dismiss()
            } : nil
        )
    }
}

// MARK: - Search Components

struct ActivitySearchBar: View {
    @Binding var searchText: String
    let resultCount: Int
    let totalCount: Int
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .font(.system(size: 16))
                
                TextField("Search apps, websites, or categories...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .stroke(DesignSystem.Colors.tertiaryText.opacity(0.2), lineWidth: 1)
            )
            
            Spacer()
        }
    }
}

struct SearchResultsHeader: View {
    let searchText: String
    let resultCount: Int
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 12, height: 12)
            }
            
            Text(resultText)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Spacer()
        }
    }
    
    private var resultText: String {
        if isLoading {
            return "Searching..."
        } else if resultCount == 0 {
            return "No results for '\(searchText)'"
        } else if resultCount == 1 {
            return "1 result for '\(searchText)'"
        } else {
            return "\(resultCount) results for '\(searchText)'"
        }
    }
}

#Preview {
    ActivityView(activityMonitor: ActivityMonitor())
}
