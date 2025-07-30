import SwiftUI

struct AwarenessSettingsView: View {
    @ObservedObject private var userSettings = UserSettings.shared
    @ObservedObject private var notificationService = AwarenessNotificationService.shared
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            SectionHeaderView(
                "Focus Awareness",
                subtitle: "Configure real-time notifications to help maintain focus and reduce context switching"
            )
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Master toggle
                HStack {
                    Toggle("Enable Focus Awareness Notifications", isOn: $userSettings.enableAwarenessNotifications)
                        .toggleStyle(.switch)
                        .onChange(of: userSettings.enableAwarenessNotifications) { _, isEnabled in
                            if isEnabled && !notificationService.isEnabled {
                                // Request permission if not already granted
                                showingPermissionAlert = true
                            }
                        }
                    
                    Spacer()
                }
                
                if userSettings.enableAwarenessNotifications {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Divider()
                        
                        Text("Notification Types")
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Toggle("Cognitive Overload Alerts", isOn: $userSettings.enableOverloadAlerts)
                                    .help("Notify when rapid context switching is detected")
                                
                                Spacer()
                                
                            }
                            
                            HStack {
                                Toggle("Scattered Attention Alerts", isOn: $userSettings.enableScatteredAlerts)
                                    .help("Notify during frequent task switching patterns")
                                
                                Spacer()
                                
                            }
                            
                            HStack {
                                Toggle("Focus Encouragement", isOn: $userSettings.enableEncouragement)
                                    .help("Positive reinforcement for maintained focus periods")
                                
                                Spacer()
                                
                            }
                            
                            HStack {
                                Toggle("Productivity Insights", isOn: $userSettings.enableProductivityInsights)
                                    .help("Ambient notifications with productivity insights and focus predictions")
                                
                                Spacer()
                                
                            }
                        }
                        .disabled(!userSettings.enableAwarenessNotifications)
                        
                        Divider()
                        
                        Text("Notification Style")
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        HStack {
                            Toggle("Use Gentle Language", isOn: $userSettings.useGentleLanguage)
                                .help("Use encouraging, supportive language instead of direct warnings")
                                .disabled(!userSettings.enableAwarenessNotifications)
                            
                            Spacer()
                            
                        }
                        
                        Divider()
                        
                        // Current status
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Current Status")
                                .font(DesignSystem.Typography.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            HStack {
                                Circle()
                                    .fill(notificationService.isEnabled ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                                    .frame(width: 8, height: 8)
                                
                                Text(notificationService.isEnabled ? "Notifications Enabled" : "Notifications Disabled")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            
                            if let lastNotification = notificationService.lastNotificationTime {
                                Text("Last notification: \(formatTime(lastNotification))")
                                    .font(DesignSystem.Typography.caption2)
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                            }
                        }
                        
                        Divider()
                        
                        // Test notification button
                        HStack {
                            Button("Test Notification") {
                                notificationService.sendFocusReminder(message: "This is a test of your FocusMonitor awareness notifications.")
                            }
                            .disabled(!notificationService.isEnabled)
                            
                            Spacer()
                            
                            Button("Snooze Notifications (15m)") {
                                notificationService.snoozeNotifications(for: 900)
                            }
                            .disabled(!notificationService.isEnabled)
                        }
                    }
                    .padding(.leading, DesignSystem.Spacing.lg)
                }
            }
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open System Preferences") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                userSettings.enableAwarenessNotifications = false
            }
        } message: {
            Text("FocusMonitor needs notification permission to send focus awareness alerts. Please enable notifications in System Preferences.")
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    AwarenessSettingsView()
        .padding()
}