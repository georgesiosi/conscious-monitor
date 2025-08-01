import Foundation
import Combine

class UserSettings: ObservableObject {
    nonisolated(unsafe) static let shared = UserSettings() // Singleton for easy access
    
    // All settings now auto-save immediately following macOS conventions

    private enum Keys {
        static let hourlyRate = "hourlyRate"
        static let openAIAPIKey = "openAIAPIKey"
        static let csdAgentKey = "csdAgentKey"
        static let enableCSDCoaching = "enableCSDCoaching"
        static let defaultChatMode = "defaultChatMode"
        static let aboutMe = "aboutMe"
        static let userGoals = "userGoals"
        static let showFloatingFocusPanel = "showFloatingFocusPanel"
        static let showSecondsInTimestamps = "showSecondsInTimestamps"
        static let enableAwarenessNotifications = "enableAwarenessNotifications"
        static let enableOverloadAlerts = "enableOverloadAlerts"
        static let enableScatteredAlerts = "enableScatteredAlerts"
        static let enableEncouragement = "enableEncouragement"
        static let enableProductivityInsights = "enableProductivityInsights"
        static let useGentleLanguage = "useGentleLanguage"
        // Floating bar configuration settings
        static let floatingBarOpacity = "floatingBarOpacity"
        static let floatingBarAutoHide = "floatingBarAutoHide"
    }

    @Published var hourlyRate: Double {
        didSet {
            UserDefaults.standard.set(hourlyRate, forKey: Keys.hourlyRate)
            print("UserSettings: Hourly rate saved - \(hourlyRate)")
        }
    }
    
    @Published var openAIAPIKey: String {
        didSet {
            UserDefaults.standard.set(openAIAPIKey, forKey: Keys.openAIAPIKey)
            print("UserSettings: OpenAI API key saved")
        }
    }
    
    @Published var csdAgentKey: String {
        didSet {
            UserDefaults.standard.set(csdAgentKey, forKey: Keys.csdAgentKey)
            print("UserSettings: CSD Agent key saved")
        }
    }
    
    @Published var enableCSDCoaching: Bool {
        didSet {
            UserDefaults.standard.set(enableCSDCoaching, forKey: Keys.enableCSDCoaching)
            print("UserSettings: CSD Coaching enabled - \(enableCSDCoaching)")
        }
    }
    
    @Published var defaultChatMode: ChatMode {
        didSet {
            UserDefaults.standard.set(defaultChatMode.rawValue, forKey: Keys.defaultChatMode)
            print("UserSettings: Default chat mode - \(defaultChatMode.displayName)")
        }
    }

    @Published var aboutMe: String {
        didSet {
            UserDefaults.standard.set(aboutMe, forKey: Keys.aboutMe)
            print("UserSettings: About me saved")
        }
    }

    @Published var userGoals: String {
        didSet {
            UserDefaults.standard.set(userGoals, forKey: Keys.userGoals)
            print("UserSettings: User goals saved")
        }
    }

    // Published property for showing/hiding the floating focus panel
    @Published var showFloatingFocusPanel: Bool {
        didSet {
            UserDefaults.standard.set(showFloatingFocusPanel, forKey: Keys.showFloatingFocusPanel)
            print("UserSettings: Show Floating Focus Panel saved - \(showFloatingFocusPanel)")
        }
    }
    
    @Published var showSecondsInTimestamps: Bool {
        didSet {
            UserDefaults.standard.set(showSecondsInTimestamps, forKey: Keys.showSecondsInTimestamps)
            print("UserSettings: Show seconds in timestamps - \(showSecondsInTimestamps)")
        }
    }
    
    // MARK: - Awareness Notification Settings
    
    @Published var enableAwarenessNotifications: Bool {
        didSet {
            UserDefaults.standard.set(enableAwarenessNotifications, forKey: Keys.enableAwarenessNotifications)
            AwarenessNotificationService.shared.isEnabled = enableAwarenessNotifications
            print("UserSettings: Awareness notifications - \(enableAwarenessNotifications)")
        }
    }
    
    @Published var enableOverloadAlerts: Bool {
        didSet {
            UserDefaults.standard.set(enableOverloadAlerts, forKey: Keys.enableOverloadAlerts)
            updateNotificationServiceSettings()
            print("UserSettings: Overload alerts - \(enableOverloadAlerts)")
        }
    }
    
    @Published var enableScatteredAlerts: Bool {
        didSet {
            UserDefaults.standard.set(enableScatteredAlerts, forKey: Keys.enableScatteredAlerts)
            updateNotificationServiceSettings()
            print("UserSettings: Scattered alerts - \(enableScatteredAlerts)")
        }
    }
    
    @Published var enableEncouragement: Bool {
        didSet {
            UserDefaults.standard.set(enableEncouragement, forKey: Keys.enableEncouragement)
            updateNotificationServiceSettings()
            print("UserSettings: Encouragement notifications - \(enableEncouragement)")
        }
    }
    
    @Published var enableProductivityInsights: Bool {
        didSet {
            UserDefaults.standard.set(enableProductivityInsights, forKey: Keys.enableProductivityInsights)
            updateNotificationServiceSettings()
            print("UserSettings: Productivity insights - \(enableProductivityInsights)")
        }
    }
    
    @Published var useGentleLanguage: Bool {
        didSet {
            UserDefaults.standard.set(useGentleLanguage, forKey: Keys.useGentleLanguage)
            updateNotificationServiceSettings()
            print("UserSettings: Gentle language - \(useGentleLanguage)")
        }
    }
    
    // MARK: - Floating Bar Configuration
    
    @Published var floatingBarOpacity: Double {
        didSet {
            UserDefaults.standard.set(floatingBarOpacity, forKey: Keys.floatingBarOpacity)
            print("UserSettings: Floating bar opacity - \(floatingBarOpacity)")
        }
    }
    
    @Published var floatingBarAutoHide: Bool {
        didSet {
            UserDefaults.standard.set(floatingBarAutoHide, forKey: Keys.floatingBarAutoHide)
            print("UserSettings: Floating bar auto-hide - \(floatingBarAutoHide)")
        }
    }
    
    // MARK: - Settings Loading
    // All settings now auto-save on change - no manual save needed
    
    private func loadSettings() {
        // Load settings from UserDefaults with defaults
        self.hourlyRate = UserDefaults.standard.object(forKey: Keys.hourlyRate) != nil ? 
            UserDefaults.standard.double(forKey: Keys.hourlyRate) : 25.0
        self.openAIAPIKey = UserDefaults.standard.string(forKey: Keys.openAIAPIKey) ?? ""
        self.csdAgentKey = UserDefaults.standard.string(forKey: Keys.csdAgentKey) ?? "asst_rIyzxzd2BqXyzTNpA9AWhLYw"
        self.aboutMe = UserDefaults.standard.string(forKey: Keys.aboutMe) ?? ""
        self.userGoals = UserDefaults.standard.string(forKey: Keys.userGoals) ?? ""
        
        // Load chat settings
        if let chatModeString = UserDefaults.standard.string(forKey: Keys.defaultChatMode),
           let chatMode = ChatMode(rawValue: chatModeString) {
            self.defaultChatMode = chatMode
        } else {
            self.defaultChatMode = .auto
        }
    }
    
    private func updateNotificationServiceSettings() {
        AwarenessNotificationService.shared.updateNotificationSettings(
            enableOverload: enableOverloadAlerts,
            enableScattered: enableScatteredAlerts,
            enableEncouragement: enableEncouragement,
            enableInsights: enableProductivityInsights,
            useGentle: useGentleLanguage
        )
    }

    private init() {
        // Initialize all settings with defaults
        self.hourlyRate = 25.0
        self.openAIAPIKey = ""
        self.csdAgentKey = ""
        self.enableCSDCoaching = false
        self.defaultChatMode = .auto
        self.aboutMe = ""
        self.userGoals = ""
        self.showFloatingFocusPanel = false
        self.showSecondsInTimestamps = false
        self.enableAwarenessNotifications = false
        self.enableOverloadAlerts = false
        self.enableScatteredAlerts = false
        self.enableEncouragement = false
        self.enableProductivityInsights = false
        self.useGentleLanguage = false
        // Floating bar defaults - following specified configuration
        self.floatingBarOpacity = 0.9  // Visual transparency (0.0-1.0)
        self.floatingBarAutoHide = true // Hide when main window active
        
        // Load all settings from UserDefaults (this will trigger didSet if values exist)
        loadSettings()
        
        // Load boolean settings from UserDefaults
        self.showFloatingFocusPanel = UserDefaults.standard.bool(forKey: Keys.showFloatingFocusPanel)
        self.showSecondsInTimestamps = UserDefaults.standard.bool(forKey: Keys.showSecondsInTimestamps)
        self.enableCSDCoaching = UserDefaults.standard.bool(forKey: Keys.enableCSDCoaching)
        
        // Load awareness notification settings with defaults
        self.enableAwarenessNotifications = UserDefaults.standard.object(forKey: Keys.enableAwarenessNotifications) != nil ? 
            UserDefaults.standard.bool(forKey: Keys.enableAwarenessNotifications) : true
        self.enableOverloadAlerts = UserDefaults.standard.object(forKey: Keys.enableOverloadAlerts) != nil ?
            UserDefaults.standard.bool(forKey: Keys.enableOverloadAlerts) : true
        self.enableScatteredAlerts = UserDefaults.standard.object(forKey: Keys.enableScatteredAlerts) != nil ?
            UserDefaults.standard.bool(forKey: Keys.enableScatteredAlerts) : true
        self.enableEncouragement = UserDefaults.standard.object(forKey: Keys.enableEncouragement) != nil ?
            UserDefaults.standard.bool(forKey: Keys.enableEncouragement) : true
        self.enableProductivityInsights = UserDefaults.standard.object(forKey: Keys.enableProductivityInsights) != nil ?
            UserDefaults.standard.bool(forKey: Keys.enableProductivityInsights) : true
        self.useGentleLanguage = UserDefaults.standard.object(forKey: Keys.useGentleLanguage) != nil ?
            UserDefaults.standard.bool(forKey: Keys.useGentleLanguage) : true
            
        // Load floating bar settings with defaults
        self.floatingBarOpacity = UserDefaults.standard.object(forKey: Keys.floatingBarOpacity) != nil ?
            UserDefaults.standard.double(forKey: Keys.floatingBarOpacity) : 0.9
        self.floatingBarAutoHide = UserDefaults.standard.object(forKey: Keys.floatingBarAutoHide) != nil ?
            UserDefaults.standard.bool(forKey: Keys.floatingBarAutoHide) : true
            
        print("UserSettings: All settings loaded successfully")
    }
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    func objectExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
