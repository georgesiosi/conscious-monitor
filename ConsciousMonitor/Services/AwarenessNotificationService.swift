import Foundation
import UserNotifications
import Combine

class AwarenessNotificationService: ObservableObject {
    static let shared = AwarenessNotificationService()
    
    @Published var isEnabled: Bool = true
    @Published var lastNotificationTime: Date?
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    private let minimumNotificationInterval: TimeInterval = 900 // 15 minutes between notifications
    
    // Notification preferences
    @Published var enableOverloadAlerts = true
    @Published var enableScatteredAlerts = true
    @Published var enableEncouragement = true
    @Published var enableProductivityInsights = true
    @Published var useGentleLanguage = true
    
    private init() {
        requestNotificationPermission()
        setupFocusStateListener()
        setupProductivityInsightTimer()
    }
    
    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isEnabled = granted
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setupFocusStateListener() {
        NotificationCenter.default.publisher(for: .focusStateChanged)
            .sink { [weak self] notification in
                guard let self = self,
                      let newState = notification.userInfo?["newState"] as? FocusState,
                      let velocity = notification.userInfo?["switchingVelocity"] as? Double,
                      let timestamp = notification.userInfo?["timestamp"] as? Date else { return }
                
                self.handleFocusStateChange(newState: newState, velocity: velocity, timestamp: timestamp)
            }
            .store(in: &cancellables)
    }
    
    private func handleFocusStateChange(newState: FocusState, velocity: Double, timestamp: Date) {
        guard isEnabled && shouldSendNotification() else { return }
        
        switch newState {
        case .overloaded:
            if enableOverloadAlerts {
                sendCognitiveOverloadNotification(velocity: velocity)
            }
        case .scattered:
            if enableScatteredAlerts {
                sendScatteredAttentionNotification()
            }
        case .deepFocus:
            if enableEncouragement {
                sendEncouragementNotification()
            }
        case .focused:
            break // No notification needed for healthy state
        }
    }
    
    private func shouldSendNotification() -> Bool {
        guard let lastTime = lastNotificationTime else { return true }
        return Date().timeIntervalSince(lastTime) >= minimumNotificationInterval
    }
    
    private func sendCognitiveOverloadNotification(velocity: Double) {
        let content = UNMutableNotificationContent()
        content.title = useGentleLanguage ? "Focus Check-In" : "Cognitive Overload Detected"
        content.body = useGentleLanguage 
            ? "You've been switching between tasks quite frequently. Consider taking a mindful pause."
            : "Rapid context switching detected (\(String(format: "%.1f", velocity)) switches/min). This may impact your cognitive performance."
        content.sound = .default
        content.categoryIdentifier = "FOCUS_AWARENESS"
        
        scheduleNotification(content: content, identifier: "cognitive_overload")
    }
    
    private func sendScatteredAttentionNotification() {
        let content = UNMutableNotificationContent()
        content.title = useGentleLanguage ? "Focus Gentle Reminder" : "Scattered Attention Pattern"
        content.body = useGentleLanguage
            ? "Would you like to set a focus intention for the next 25 minutes?"
            : "Frequent task switching detected. Consider consolidating your work or setting a focus timer."
        content.sound = .default
        content.categoryIdentifier = "FOCUS_AWARENESS"
        
        scheduleNotification(content: content, identifier: "scattered_attention")
    }
    
    private func sendEncouragementNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Great Focus! 🎯"
        content.body = "You've maintained deep focus for an extended period. Excellent work!"
        content.sound = .default
        content.categoryIdentifier = "FOCUS_ENCOURAGEMENT"
        
        scheduleNotification(content: content, identifier: "deep_focus_encouragement")
    }
    
    private func scheduleNotification(content: UNMutableNotificationContent, identifier: String) {
        // Cancel any existing notification with same identifier
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        // Schedule immediate notification
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        notificationCenter.add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to schedule notification: \(error.localizedDescription)")
                } else {
                    self?.lastNotificationTime = Date()
                    print("Scheduled awareness notification: \(identifier)")
                }
            }
        }
    }
    
    // Method to send a custom focus reminder
    func sendFocusReminder(message: String) {
        guard isEnabled && shouldSendNotification() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Focus Reminder"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "FOCUS_REMINDER"
        
        scheduleNotification(content: content, identifier: "custom_focus_reminder")
    }
    
    // Method to silence notifications temporarily
    func snoozeNotifications(for duration: TimeInterval) {
        isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.isEnabled = true
        }
    }
    
    // Configuration methods
    func updateNotificationSettings(
        enableOverload: Bool,
        enableScattered: Bool,
        enableEncouragement: Bool,
        enableInsights: Bool,
        useGentle: Bool
    ) {
        self.enableOverloadAlerts = enableOverload
        self.enableScatteredAlerts = enableScattered
        self.enableEncouragement = enableEncouragement
        self.enableProductivityInsights = enableInsights
        self.useGentleLanguage = useGentle
    }
}

// MARK: - Notification Categories Setup

extension AwarenessNotificationService {
    func setupNotificationCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze (15 min)",
            options: []
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION", 
            title: "Dismiss",
            options: []
        )
        
        let focusCategory = UNNotificationCategory(
            identifier: "FOCUS_AWARENESS",
            actions: [snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        let encouragementCategory = UNNotificationCategory(
            identifier: "FOCUS_ENCOURAGEMENT",
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        let insightCategory = UNNotificationCategory(
            identifier: "PRODUCTIVITY_INSIGHT",
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([focusCategory, encouragementCategory, insightCategory])
    }
}

// MARK: - Productivity Insights

extension AwarenessNotificationService {
    private func setupProductivityInsightTimer() {
        // Send insights at strategic times: mid-morning, post-lunch, end of day
        let insightTimes = [
            (hour: 10, minute: 30), // Mid-morning
            (hour: 14, minute: 15), // Post-lunch  
            (hour: 17, minute: 0)   // End of day
        ]
        
        for time in insightTimes {
            scheduleRecurringInsight(hour: time.hour, minute: time.minute)
        }
    }
    
    private func scheduleRecurringInsight(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "PRODUCTIVITY_INSIGHT"
        content.sound = .default
        
        // Create date components for the trigger
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "productivity_insight_\(hour)_\(minute)",
            content: content,
            trigger: trigger
        )
        
        // We'll set the actual content dynamically when notification fires
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule productivity insight: \(error.localizedDescription)")
            }
        }
    }
    
    func sendProductivityInsight(activityMonitor: ActivityMonitor) {
        guard enableProductivityInsights && shouldSendNotification() else { return }
        
        let insights = generateProductivityInsights(from: activityMonitor)
        guard let insight = insights.randomElement() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = insight.title
        content.body = insight.message
        content.sound = .default
        content.categoryIdentifier = "PRODUCTIVITY_INSIGHT"
        
        scheduleNotification(content: content, identifier: "productivity_insight")
    }
    
    private func generateProductivityInsights(from monitor: ActivityMonitor) -> [ProductivityInsight] {
        var insights: [ProductivityInsight] = []
        
        // Focus time insights
        let focusTime = monitor.totalFocusTimeToday
        let focusHours = focusTime / 3600
        if focusHours > 2 {
            let avgFocusHours = 4.0 // Default average, could be computed from historical data
            insights.append(ProductivityInsight(
                title: "Great Focus Today! 🎯",
                message: "You've maintained \(String(format: "%.1f", focusHours)) hours of deep focus - that's \(focusHours > avgFocusHours ? "above" : "at") your average."
            ))
        }
        
        // Context switching insights
        let contextSwitches = monitor.contextSwitchesToday
        let avgSwitches = 50.0 // Default average, could be computed from historical data
        if contextSwitches < Int(avgSwitches * 0.8) {
            insights.append(ProductivityInsight(
                title: "Excellent Focus Control 🧘",
                message: "Your context switching is \(Int((1.0 - Double(contextSwitches)/avgSwitches) * 100))% lower than usual - great discipline!"
            ))
        }
        
        // Productivity score insights
        let score = monitor.todaysProductivityScore
        if score > 75 {
            insights.append(ProductivityInsight(
                title: "High Performance Day 🚀",
                message: "Your productivity score is \(Int(score))/100 - you're in the zone today!"
            ))
        }
        
        // Peak time prediction
        if let peakHour = predictPeakFocusTime(from: monitor) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            let peakTime = Calendar.current.date(bySettingHour: peakHour, minute: 0, second: 0, of: Date()) ?? Date()
            
            insights.append(ProductivityInsight(
                title: "Focus Window Approaching ⏰",
                message: "Based on your patterns, your peak focus time typically starts around \(formatter.string(from: peakTime))."
            ))
        }
        
        return insights
    }
    
    private func predictPeakFocusTime(from monitor: ActivityMonitor) -> Int? {
        // Analyze historical focus patterns to predict optimal focus time
        let switchesByHour = monitor.getSwitchesByHour()
        
        // Find hour with lowest context switches (indicates deeper focus)
        let sortedHours = switchesByHour.sorted { $0.value < $1.value }
        return sortedHours.first?.key
    }
}

private struct ProductivityInsight {
    let title: String
    let message: String
}