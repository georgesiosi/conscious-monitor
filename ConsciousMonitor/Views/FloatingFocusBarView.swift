import SwiftUI

struct FloatingFocusBarView: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    @ObservedObject var windowManager: FloatingWindowManager
    @ObservedObject private var userSettings = UserSettings.shared
    
    @State private var currentTime = Date()
    @State private var sessionStartTime: Date?
    @State private var isHovered = false
    
    // Timer for updating current time - real-time updates every second
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 12) {
            // Current app info section
            currentAppSection
            
            Spacer()
            
            // Focus state and metrics section
            focusStateSection
            
            // Session timer section
            sessionTimerSection
        }
        .padding(12)
        .background(backgroundView)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .onReceive(timer) { _ in
            // Use async update to avoid modifying state during view update
            DispatchQueue.main.async {
                currentTime = Date()
            }
        }
        .onHover { hovering in
            // Use async update to avoid modifying state during view update
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
        .simultaneousGesture(
            TapGesture(count: 1)
                .onEnded { _ in
                    // Single click does nothing - prevents accidental activation
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    // Double click activates main ConsciousMonitor window
                    DispatchQueue.main.async {
                        windowManager.activateMainWindow()
                    }
                }
        )
        .contextMenu {
            contextMenuItems
        }
        .onAppear {
            DispatchQueue.main.async {
                setupSessionTracking()
            }
        }
    }
    
    // MARK: - Current App Section
    
    private var currentAppSection: some View {
        HStack(spacing: 8) {
            // App icon
            if let currentApp = getCurrentApp() {
                if let icon = currentApp.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .cornerRadius(4)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                }
                
                // App name and category
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentApp.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Category badge
                    Text(currentApp.category.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(currentApp.category.color)
                        .cornerRadius(4)
                }
            } else {
                // No current app - show desktop
                HStack(spacing: 8) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                    
                    Text("Desktop")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Focus State Section
    
    private var focusStateSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Focus state indicator with color coding
            HStack(spacing: 6) {
                Circle()
                    .fill(focusStateColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: focusStateColor.opacity(0.5), radius: 2)
                
                Text(focusStateText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(focusStateColor)
            }
            
            // Switching velocity
            if let velocity = getSwitchingVelocity(), velocity > 0 {
                Text("\(String(format: "%.1f", velocity)) switches/min")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Session Timer Section
    
    private var sessionTimerSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Session duration with monospaced font
            Text(sessionDurationText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .monospacedDigit()
            
            // Context switches today
            Text("\(contextSwitchesToday) switches")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Background View with NSVisualEffectView
    
    private var backgroundView: some View {
        ZStack {
            // Base background with blur effect - .hudWindow material for Sunsama-style appearance
            VisualEffectView()
                .opacity(userSettings.floatingBarOpacity)
            
            // Subtle border with gradient
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            focusStateColor.opacity(0.3),
                            focusStateColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
    
    // MARK: - Context Menu for Options
    
    private var contextMenuItems: some View {
        Group {
            Button("Show Main Window") {
                DispatchQueue.main.async {
                    windowManager.activateMainWindow()
                }
            }
            
            Divider()
            
            Menu("Window Size") {
                Button("Compact") { 
                    DispatchQueue.main.async {
                        windowManager.resizeWindow(to: CGSize(width: 250, height: 80))
                    }
                }
                Button("Standard") { 
                    DispatchQueue.main.async {
                        windowManager.resizeWindow(to: CGSize(width: 300, height: 120))
                    }
                }
                Button("Detailed") { 
                    DispatchQueue.main.async {
                        windowManager.resizeWindow(to: CGSize(width: 400, height: 160))
                    }
                }
            }
            
            Divider()
            
            Button("Hide Floating Bar") {
                DispatchQueue.main.async {
                    userSettings.showFloatingFocusPanel = false
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var focusStateColor: Color {
        let focusState = activityMonitor.focusStateDetector.currentFocusState
        
        switch focusState {
        case .deepFocus:
            return .green
        case .focused:
            return .blue
        case .scattered:
            return .orange
        case .overloaded:
            return .red
        }
    }
    
    private var focusStateText: String {
        return activityMonitor.focusStateDetector.currentFocusState.rawValue
    }
    
    private var sessionDurationText: String {
        guard let sessionStart = sessionStartTime else { return "0:00" }
        let duration = currentTime.timeIntervalSince(sessionStart)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var contextSwitchesToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return activityMonitor.contextSwitches.filter { $0.timestamp >= today }.count
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentApp() -> (name: String, icon: NSImage?, category: AppCategory)? {
        guard let lastSwitch = activityMonitor.lastAppSwitch else { return nil }
        
        // Get the icon from the most recent event for this app
        let recentEvent = activityMonitor.activationEvents
            .filter { $0.appName == lastSwitch.name }
            .sorted { $0.timestamp > $1.timestamp }
            .first
        
        return (
            name: lastSwitch.name,
            icon: recentEvent?.appIcon,
            category: lastSwitch.category
        )
    }
    
    private func getSwitchingVelocity() -> Double? {
        return activityMonitor.focusStateDetector.switchingVelocity
    }
    
    private func setupSessionTracking() {
        // Use the current session start time from ActivityMonitor if available
        let newSessionStartTime = activityMonitor.currentSessionStartTime ?? Date()
        
        // Only update if different to avoid unnecessary updates
        if sessionStartTime != newSessionStartTime {
            sessionStartTime = newSessionStartTime
        }
    }
}

// MARK: - Visual Effect View with .hudWindow material

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.material = .hudWindow  // Using .hudWindow material for proper Sunsama-style blur
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        return effectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}


#Preview {
    FloatingFocusBarView(
        activityMonitor: ActivityMonitor(),
        windowManager: FloatingWindowManager()
    )
    .frame(width: 300, height: 120)
}
