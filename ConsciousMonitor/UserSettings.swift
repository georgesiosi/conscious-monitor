import Foundation
import Combine

class UserSettings: ObservableObject {
    static let shared = UserSettings() // Singleton for easy access
    
    // All settings now auto-save immediately following macOS conventions

    private enum Keys {
        static let hourlyRate = "hourlyRate"
        static let openAIAPIKey = "openAIAPIKey"
        static let claudeAPIKey = "claudeAPIKey"
        static let grokAPIKey = "grokAPIKey"
        static let primaryAIProvider = "primaryAIProvider"
        static let fallbackAIProvider = "fallbackAIProvider"
        static let enableAIGatewayCache = "enableAIGatewayCache"
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

    // Migration sentinel to ensure we only migrate once
    private static let legacyMigrationDoneKey = "didMigrateFromLegacyUserDefaults"

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
    
    @Published var claudeAPIKey: String {
        didSet {
            UserDefaults.standard.set(claudeAPIKey, forKey: Keys.claudeAPIKey)
            print("UserSettings: Claude API key saved")
        }
    }
    
    @Published var grokAPIKey: String {
        didSet {
            UserDefaults.standard.set(grokAPIKey, forKey: Keys.grokAPIKey)
            print("UserSettings: Grok API key saved")
        }
    }
    
    @Published var primaryAIProvider: AIProvider {
        didSet {
            UserDefaults.standard.set(primaryAIProvider.rawValue, forKey: Keys.primaryAIProvider)
            print("UserSettings: Primary AI provider saved - \(primaryAIProvider.displayName)")
        }
    }
    
    @Published var fallbackAIProvider: AIProvider? {
        didSet {
            if let provider = fallbackAIProvider {
                UserDefaults.standard.set(provider.rawValue, forKey: Keys.fallbackAIProvider)
                print("UserSettings: Fallback AI provider saved - \(provider.displayName)")
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.fallbackAIProvider)
                print("UserSettings: Fallback AI provider cleared")
            }
        }
    }
    
    @Published var enableAIGatewayCache: Bool {
        didSet {
            UserDefaults.standard.set(enableAIGatewayCache, forKey: Keys.enableAIGatewayCache)
            print("UserSettings: AI Gateway cache enabled - \(enableAIGatewayCache)")
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
        self.claudeAPIKey = UserDefaults.standard.string(forKey: Keys.claudeAPIKey) ?? ""
        self.grokAPIKey = UserDefaults.standard.string(forKey: Keys.grokAPIKey) ?? ""
        self.csdAgentKey = UserDefaults.standard.string(forKey: Keys.csdAgentKey) ?? "asst_rIyzxzd2BqXyzTNpA9AWhLYw"
        self.aboutMe = UserDefaults.standard.string(forKey: Keys.aboutMe) ?? ""
        self.userGoals = UserDefaults.standard.string(forKey: Keys.userGoals) ?? ""
        
        // Load AI provider settings
        if let primaryProviderString = UserDefaults.standard.string(forKey: Keys.primaryAIProvider),
           let primaryProvider = AIProvider(rawValue: primaryProviderString) {
            self.primaryAIProvider = primaryProvider
        } else {
            self.primaryAIProvider = .openAI
        }
        
        if let fallbackProviderString = UserDefaults.standard.string(forKey: Keys.fallbackAIProvider),
           let fallbackProvider = AIProvider(rawValue: fallbackProviderString) {
            self.fallbackAIProvider = fallbackProvider
        } else {
            self.fallbackAIProvider = nil
        }
        
        self.enableAIGatewayCache = UserDefaults.standard.object(forKey: Keys.enableAIGatewayCache) != nil ?
            UserDefaults.standard.bool(forKey: Keys.enableAIGatewayCache) : true
        
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
        self.claudeAPIKey = ""
        self.grokAPIKey = ""
        self.primaryAIProvider = .openAI
        self.fallbackAIProvider = nil
        self.enableAIGatewayCache = true
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

        // Attempt one-time migration from legacy UserDefaults domains
        performLegacyUserDefaultsMigrationIfNeeded()
        
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

// MARK: - Legacy Migration
extension UserSettings {
    /// Migrate keys from old bundle identifiers (e.g., FocusMonitor) into the current domain once.
    private func performLegacyUserDefaultsMigrationIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: Self.legacyMigrationDoneKey) {
            return
        }

        // Only migrate if current values are empty, to avoid overwriting newer data
        var migratedSomething = false
        let legacyDomains = [
            "com.FocusMonitor",
            "com.cstack.FocusMonitor",
            "com.example.FocusMonitor"
        ]

        for domain in legacyDomains {
            guard let legacyDefaults = UserDefaults(suiteName: domain) else { continue }

            if self.openAIAPIKey.isEmpty, let oldKey = legacyDefaults.string(forKey: Keys.openAIAPIKey), !oldKey.isEmpty {
                self.openAIAPIKey = oldKey
                migratedSomething = true
                print("UserSettings: Migrated OpenAI API key from legacy domain \(domain)")
            }

            if self.csdAgentKey.isEmpty, let oldCSD = legacyDefaults.string(forKey: Keys.csdAgentKey), !oldCSD.isEmpty {
                self.csdAgentKey = oldCSD
                migratedSomething = true
                print("UserSettings: Migrated CSD Agent key from legacy domain \(domain)")
            }
        }

        if migratedSomething {
            defaults.set(true, forKey: Self.legacyMigrationDoneKey)
            print("UserSettings: Legacy UserDefaults migration completed")
        } else {
            // Still set the flag to avoid repeated attempts if nothing to migrate
            defaults.set(true, forKey: Self.legacyMigrationDoneKey)
        }
    }
    
    // MARK: - AI Gateway Helpers
    
    /// Get all configured API keys for AI providers
    func getAIProviderKeys() -> [AIProvider: String] {
        var keys: [AIProvider: String] = [:]
        
        if !openAIAPIKey.isEmpty {
            keys[.openAI] = openAIAPIKey
        }
        if !claudeAPIKey.isEmpty {
            keys[.claude] = claudeAPIKey
        }
        if !grokAPIKey.isEmpty {
            keys[.grok] = grokAPIKey
        }
        
        return keys
    }
    
    /// Check if the primary AI provider has a valid API key
    var hasPrimaryProviderKey: Bool {
        switch primaryAIProvider {
        case .openAI: return !openAIAPIKey.isEmpty
        case .claude: return !claudeAPIKey.isEmpty
        case .grok: return !grokAPIKey.isEmpty
        }
    }
    
    /// Check if any AI provider has a valid API key
    var hasAnyProviderKey: Bool {
        return !openAIAPIKey.isEmpty || !claudeAPIKey.isEmpty || !grokAPIKey.isEmpty
    }
    
    /// Get API key for a specific provider
    func getAPIKey(for provider: AIProvider) -> String {
        switch provider {
        case .openAI: return openAIAPIKey
        case .claude: return claudeAPIKey
        case .grok: return grokAPIKey
        }
    }
    
    /// Set API key for a specific provider
    func setAPIKey(_ key: String, for provider: AIProvider) {
        switch provider {
        case .openAI: openAIAPIKey = key
        case .claude: claudeAPIKey = key
        case .grok: grokAPIKey = key
        }
    }
}
