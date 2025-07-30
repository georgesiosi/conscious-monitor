import Foundation
import Combine

class CategoryManager: ObservableObject {
    static let shared = CategoryManager()
    
    // MARK: - Published Properties
    @Published var customCategories: [AppCategory] = []
    @Published var allCategories: [AppCategory] = []
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let customCategoryNames = "customCategoryNames"
        static let appCategoryMappings = "appCategoryMappings"
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
}