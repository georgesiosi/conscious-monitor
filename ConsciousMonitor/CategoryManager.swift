import Foundation
import Combine

class CategoryManager: ObservableObject {
    static let shared = CategoryManager()
    
    // MARK: - Published Properties
    @Published var customCategories: [AppCategory] = []
    @Published var allCategories: [AppCategory] = []
    
    // MARK: - Default Domain Mappings
    
    /// Default domain categorization mappings (Domain -> AppCategory)
    /// Similar to AppCategorizer.defaultCategoryMappings but for web domains
    static let defaultDomainMappings: [String: AppCategory] = [
        // Social Media
        "facebook.com": .socialMedia,
        "instagram.com": .socialMedia,
        "twitter.com": .socialMedia,
        "x.com": .socialMedia,
        "linkedin.com": .socialMedia,
        "reddit.com": .socialMedia,
        "tiktok.com": .socialMedia,
        "snapchat.com": .socialMedia,
        "pinterest.com": .socialMedia,
        "discord.com": .socialMedia,
        "mastodon.social": .socialMedia,
        "threads.net": .socialMedia,
        
        // Development
        "github.com": .development,
        "gitlab.com": .development,
        "bitbucket.org": .development,
        "stackoverflow.com": .development,
        "stackexchange.com": .development,
        "developer.mozilla.org": .development,
        "docs.python.org": .development,
        "nodejs.org": .development,
        "codepen.io": .development,
        "codesandbox.io": .development,
        "replit.com": .development,
        "jsbin.com": .development,
        "jsfiddle.net": .development,
        "glitch.com": .development,
        "vercel.com": .development,
        "netlify.com": .development,
        "heroku.com": .development,
        "aws.amazon.com": .development,
        "console.cloud.google.com": .development,
        "azure.microsoft.com": .development,
        
        // Productivity  
        "google.com": .productivity,
        "gmail.com": .productivity,
        "drive.google.com": .productivity,
        "docs.google.com": .productivity,
        "sheets.google.com": .productivity,
        "slides.google.com": .productivity,
        "notion.so": .productivity,
        "slack.com": .productivity,
        "trello.com": .productivity,
        "asana.com": .productivity,
        "monday.com": .productivity,
        "airtable.com": .productivity,
        "office.com": .productivity,
        "outlook.com": .productivity,
        "teams.microsoft.com": .productivity,
        "zoom.us": .productivity,
        "meet.google.com": .productivity,
        "calendly.com": .productivity,
        "toggl.com": .productivity,
        "todoist.com": .productivity,
        "any.do": .productivity,
        
        // Entertainment
        "youtube.com": .entertainment,
        "netflix.com": .entertainment,
        "hulu.com": .entertainment,
        "primevideo.com": .entertainment,
        "disneyplus.com": .entertainment,
        "hbo.com": .entertainment,
        "twitch.tv": .entertainment,
        "spotify.com": .entertainment,
        "music.apple.com": .entertainment,
        "soundcloud.com": .entertainment,
        "bandcamp.com": .entertainment,
        "steamcommunity.com": .entertainment,
        "itch.io": .entertainment,
        "epicgames.com": .entertainment,
        "battle.net": .entertainment,
        "minecraft.net": .entertainment,
        
        // News & Information
        "cnn.com": .news,
        "bbc.com": .news,
        "nytimes.com": .news,
        "theguardian.com": .news,
        "washingtonpost.com": .news,
        "reuters.com": .news,
        "ap.org": .news,
        "npr.org": .news,
        "techcrunch.com": .news,
        "arstechnica.com": .news,
        "wired.com": .news,
        "theverge.com": .news,
        "engadget.com": .news,
        "hackernews.ycombinator.com": .news,
        "news.ycombinator.com": .news,
        
        // Shopping
        "amazon.com": .shopping,
        "ebay.com": .shopping,
        "etsy.com": .shopping,
        "alibaba.com": .shopping,
        "shopify.com": .shopping,
        "walmart.com": .shopping,
        "target.com": .shopping,
        "bestbuy.com": .shopping,
        "apple.com": .shopping,
        "newegg.com": .shopping,
        "aliexpress.com": .shopping,
        
        // Education
        "coursera.org": .education,
        "udemy.com": .education,
        "khanacademy.org": .education,
        "edx.org": .education,
        "pluralsight.com": .education,
        "skillshare.com": .education,
        "codecademy.com": .education,
        "freecodecamp.org": .education,
        "duolingo.com": .education,
        "brilliant.org": .education,
        "masterclass.com": .education,
        
        // Knowledge Management & Reference
        "wikipedia.org": .knowledgeManagement,
        "archive.org": .knowledgeManagement,
        "medium.com": .knowledgeManagement,
        "substack.com": .knowledgeManagement,
        "dev.to": .knowledgeManagement,
        "hashnode.com": .knowledgeManagement,
        "confluence.atlassian.com": .knowledgeManagement,
        "gitbook.com": .knowledgeManagement,
        "readthedocs.io": .knowledgeManagement,
        
        // Finance
        "mint.com": .finance,
        "ynab.com": .finance,
        "personalcapital.com": .finance,
        "robinhood.com": .finance,
        "fidelity.com": .finance,
        "schwab.com": .finance,
        "vanguard.com": .finance,
        "coinbase.com": .finance,
        "blockchain.com": .finance,
        "xero.com": .finance,
        "quickbooks.intuit.com": .finance,
        "freshbooks.com": .finance,
        "wave.com": .finance,
        "stripe.com": .finance,
        "paypal.com": .finance,
        "square.com": .finance,
        "bankofamerica.com": .finance,
        "chase.com": .finance,
        "wellsfargo.com": .finance,
        
        // Design
        "figma.com": .design,
        "sketch.com": .design,
        "adobe.com": .design,
        "canva.com": .design,
        "dribbble.com": .design,
        "behance.net": .design,
        "unsplash.com": .design,
        "pexels.com": .design,
        
        // Travel
        "booking.com": .travel,
        "airbnb.com": .travel,
        "expedia.com": .travel,
        "tripadvisor.com": .travel,
        "kayak.com": .travel,
        "maps.google.com": .travel,
        "uber.com": .travel,
        "lyft.com": .travel,
        
        // Health & Fitness
        "myfitnesspal.com": .health,
        "strava.com": .health,
        "fitbit.com": .health,
        "headspace.com": .health,
        "calm.com": .health,
        
        // Communication (Web-based)
        "web.whatsapp.com": .communication,
        "web.telegram.org": .communication,
        "hangouts.google.com": .communication,
        "messenger.com": .communication,
        
        // Utilities
        "translate.google.com": .utilities,
        "weather.com": .utilities,
        "speedtest.net": .utilities,
        "downdetector.com": .utilities,
    ]
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let customCategoryNames = "customCategoryNames"
        static let appCategoryMappings = "appCategoryMappings"
        static let domainCategoryMappings = "domainCategoryMappings"
    }
    
    // MARK: - Initialization
    private init() {
        migrateFromAppCategorizer()
        loadCustomCategories()
        cleanupDuplicateCategories()
        updateAllCategories()
    }
    
    // MARK: - Public Methods
    
    /// Get all available categories (defaults + custom)
    var allAvailableCategories: [AppCategory] {
        return allCategories
    }
    
    /// Get category for a given bundle identifier
    func getCategory(for bundleIdentifier: String?) -> AppCategory {
        guard let bundleId = bundleIdentifier, !bundleId.isEmpty else {
            return .other
        }
        
        // Check user-defined mappings first
        if let categoryName = loadAppCategoryMappings()[bundleId] {
            if let category = allCategories.first(where: { $0.name == categoryName }) {
                return category
            }
        }
        
        // Fall back to default mappings
        if let defaultCategory = AppCategorizer.defaultCategoryMappings[bundleId] {
            return defaultCategory
        }
        
        return .other
    }
    
    /// Get category for a specific Chrome tab domain
    func getCategoryForDomain(_ domain: String) -> AppCategory? {
        let domainKey = domain.lowercased()
        
        // Check user-defined mappings first (highest priority)
        let domainMappings = loadDomainCategoryMappings()
        if let categoryName = domainMappings[domainKey] {
            return allCategories.first(where: { $0.name == categoryName })
        }
        
        // Fall back to default domain mappings
        if let defaultCategory = Self.defaultDomainMappings[domainKey] {
            return defaultCategory
        }
        
        // Check for subdomain patterns (e.g., "docs.google.com" → "google.com")
        let components = domainKey.components(separatedBy: ".")
        if components.count > 2 {
            let rootDomain = components.suffix(2).joined(separator: ".")
            if let defaultCategory = Self.defaultDomainMappings[rootDomain] {
                return defaultCategory
            }
        }
        
        return nil
    }
    
    /// Get category for Chrome tab with domain fallback
    func getCategoryForChromeTab(domain: String?) -> AppCategory {
        // First check if there's a domain-specific category
        if let domain = domain, let domainCategory = getCategoryForDomain(domain) {
            return domainCategory
        }
        
        // Fall back to Chrome app category
        return getCategory(for: "com.google.Chrome")
    }
    
    /// Add a new custom category
    func addCustomCategory(name: String) -> AppCategory? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate name
        guard !trimmedName.isEmpty else { return nil }
        
        // Check if already exists (case-insensitive)
        if allCategories.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            return allCategories.first { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
        }
        
        // Create new category
        let newCategory = AppCategory(name: trimmedName)
        
        // Add to custom categories
        customCategories.append(newCategory)
        customCategories.sort { $0.name < $1.name }
        
        // Update combined list
        updateAllCategories()
        
        // Save to UserDefaults
        saveCustomCategories()
        
        return newCategory
    }
    
    /// Remove a custom category
    func removeCustomCategory(_ category: AppCategory) {
        // Don't allow removal of default categories
        guard !AppCategory.defaultCases.contains(where: { $0.name == category.name }) else {
            return
        }
        
        // Remove from custom categories
        customCategories.removeAll { $0.name == category.name }
        
        // Update combined list
        updateAllCategories()
        
        // Remove any app mappings to this category
        var mappings = loadAppCategoryMappings()
        mappings = mappings.filter { $0.value != category.name }
        saveAppCategoryMappings(mappings)
        
        // Save custom categories
        saveCustomCategories()
    }
    
    /// Update category for a specific app
    func setCategoryForApp(bundleIdentifier: String, category: AppCategory) {
        var mappings = loadAppCategoryMappings()
        mappings[bundleIdentifier] = category.name
        saveAppCategoryMappings(mappings)
    }
    
    /// Remove category mapping for a specific app (revert to default)
    func removeCategoryForApp(bundleIdentifier: String) {
        var mappings = loadAppCategoryMappings()
        mappings.removeValue(forKey: bundleIdentifier)
        saveAppCategoryMappings(mappings)
    }
    
    /// Set category for a specific domain (for Chrome tabs)
    func setCategoryForDomain(_ domain: String, category: AppCategory) {
        var mappings = loadDomainCategoryMappings()
        mappings[domain.lowercased()] = category.name
        saveDomainCategoryMappings(mappings)
    }
    
    /// Remove category mapping for a specific domain (revert to Chrome app category)
    func removeCategoryForDomain(_ domain: String) {
        var mappings = loadDomainCategoryMappings()
        mappings.removeValue(forKey: domain.lowercased())
        saveDomainCategoryMappings(mappings)
    }
    
    // MARK: - Migration
    
    private func migrateFromAppCategorizer() {
        let oldCustomCategoryNamesKey = "userDefinedCategoryNames"
        let oldAppCategoryMappingsKey = "userCategoryMappings"
        
        // Check if we need to migrate from the old AppCategorizer keys
        let hasOldData = UserDefaults.standard.object(forKey: oldCustomCategoryNamesKey) != nil ||
                        UserDefaults.standard.object(forKey: oldAppCategoryMappingsKey) != nil
        
        let hasNewData = UserDefaults.standard.object(forKey: Keys.customCategoryNames) != nil ||
                        UserDefaults.standard.object(forKey: Keys.appCategoryMappings) != nil
        
        // Only migrate if we have old data but no new data
        guard hasOldData && !hasNewData else { return }
        
        print("CategoryManager: Migrating data from AppCategorizer...")
        
        // Migrate custom category names
        if let oldCategoryNames = UserDefaults.standard.stringArray(forKey: oldCustomCategoryNamesKey) {
            UserDefaults.standard.set(oldCategoryNames, forKey: Keys.customCategoryNames)
            print("CategoryManager: Migrated \(oldCategoryNames.count) custom categories")
        }
        
        // Migrate app category mappings
        if let oldMappingData = UserDefaults.standard.data(forKey: oldAppCategoryMappingsKey) {
            do {
                let oldMappings = try JSONDecoder().decode([String: String].self, from: oldMappingData)
                let newMappingData = try JSONEncoder().encode(oldMappings)
                UserDefaults.standard.set(newMappingData, forKey: Keys.appCategoryMappings)
                print("CategoryManager: Migrated \(oldMappings.count) app category mappings")
            } catch {
                print("CategoryManager: Failed to migrate app category mappings: \(error)")
            }
        }
        
        print("CategoryManager: Migration completed successfully")
    }
    
    // MARK: - Private Methods
    
    private func cleanupDuplicateCategories() {
        // Remove any custom categories that match default categories (case-insensitive)
        let originalCount = customCategories.count
        customCategories = customCategories.filter { customCategory in
            !AppCategory.defaultCases.contains(where: { $0.name.caseInsensitiveCompare(customCategory.name) == .orderedSame })
        }
        
        // Save the cleaned up list if we removed any duplicates
        if customCategories.count != originalCount {
            print("CategoryManager: Cleaned up \(originalCount - customCategories.count) duplicate categories")
            saveCustomCategories()
        }
    }
    
    private func loadCustomCategories() {
        let categoryNames = UserDefaults.standard.stringArray(forKey: Keys.customCategoryNames) ?? []
        customCategories = categoryNames.map { AppCategory(name: $0) }
    }
    
    private func saveCustomCategories() {
        let categoryNames = customCategories.map { $0.name }
        UserDefaults.standard.set(categoryNames, forKey: Keys.customCategoryNames)
    }
    
    private func updateAllCategories() {
        // Combine default and custom categories, removing duplicates
        var combinedCategories = AppCategory.defaultCases
        
        // Add custom categories that don't conflict with default ones
        for customCategory in customCategories {
            if !combinedCategories.contains(where: { $0.name.caseInsensitiveCompare(customCategory.name) == .orderedSame }) {
                combinedCategories.append(customCategory)
            }
        }
        
        allCategories = combinedCategories.sorted { $0.name < $1.name }
    }
    
    private func loadAppCategoryMappings() -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: Keys.appCategoryMappings) else {
            return [:]
        }
        
        do {
            return try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            print("CategoryManager: Error decoding app category mappings: \(error)")
            return [:]
        }
    }
    
    private func saveAppCategoryMappings(_ mappings: [String: String]) {
        do {
            let data = try JSONEncoder().encode(mappings)
            UserDefaults.standard.set(data, forKey: Keys.appCategoryMappings)
        } catch {
            print("CategoryManager: Error encoding app category mappings: \(error)")
        }
    }
    
    private func loadDomainCategoryMappings() -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: Keys.domainCategoryMappings) else {
            return [:]
        }
        
        do {
            return try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            print("CategoryManager: Error decoding domain category mappings: \(error)")
            return [:]
        }
    }
    
    private func saveDomainCategoryMappings(_ mappings: [String: String]) {
        do {
            let data = try JSONEncoder().encode(mappings)
            UserDefaults.standard.set(data, forKey: Keys.domainCategoryMappings)
        } catch {
            print("CategoryManager: Error encoding domain category mappings: \(error)")
        }
    }
}