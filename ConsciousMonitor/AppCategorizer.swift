import Foundation

struct AppCategorizer {
    private static let userCategoryMappingsKey = "userCategoryMappings" // [BundleID: CategoryName]
    private static let userDefinedCategoryNamesKey = "userDefinedCategoryNames" // [CategoryName]

    // Default category mappings (BundleID to default AppCategory struct)
    static let defaultCategoryMappings: [String: AppCategory] = [
        // Productivity
        "com.apple.dt.Xcode": .development,
        "com.microsoft.VSCode": .development,
        "com.jetbrains.intellij": .development,
        "com.apple.Terminal": .development,
        "com.googlecode.iterm2": .development,
        "com.apple.TextEdit": .productivity,
        "com.microsoft.Word": .productivity,
        "com.microsoft.Excel": .productivity,
        "com.microsoft.Powerpoint": .productivity,
        "com.apple.iWork.Pages": .productivity,
        "com.apple.iWork.Numbers": .productivity,
        "com.apple.iWork.Keynote": .productivity,
        "com.culturedcode.ThingsMac": .productivity,
        "com.omnigroup.OmniFocus3": .productivity,
        "com.todoist.mac.Todoist": .productivity,
        "org.mozilla.firefox": .productivity, // Often for browsing/research
        "com.operasoftware.Opera": .productivity,
        "com.apple.MobileSMS": .communication, // Messages app

        // Communication
        "com.apple.Mail": .communication,
        "com.microsoft.Outlook": .communication,
        "com.google.Chrome": .productivity, // Often used for work/email
        "com.hnc.Discord": .communication,
        "com.tinyspeck.slackmacgap": .communication,
        "us.zoom.xos": .communication,
        "com.skype.skype": .communication,
        "com.teams.Teams": .communication, // Microsoft Teams

        // Social Media
        "com.facebook.Facebook": .socialMedia,
        "com.twitter.Twitter": .socialMedia,
        "com.instagram.Instagram": .socialMedia,
        "com.linkedin.LinkedIn": .socialMedia,
        "com.reddit.Reddit": .socialMedia,

        // Entertainment
        "com.apple.Music": .entertainment,
        "com.spotify.client": .entertainment,
        "com.apple.TV": .entertainment,
        "com.netflix.Netflix": .entertainment,
        "com.amazon.PrimeVideo": .entertainment,
        "com.google.YouTube": .entertainment,

        // Design
        "com.adobe.Photoshop": .design,
        "com.adobe.Illustrator": .design,
        "com.adobe.InDesign": .design,
        "com.adobe.XD": .design,
        "com.sketchapp.Sketch": .design,
        "com.figma.Desktop": .design,
        "com.seriflabs.affinitydesigner": .design,
        "com.seriflabs.affinityphoto": .design,
        "com.blenderfoundation.blender": .design, // 3D Design

        // Knowledge Management
        "notion.id": .knowledgeManagement,
        "md.obsidian": .knowledgeManagement,
        "net.shinyfrog.bear": .knowledgeManagement,
        "com.roamresearch.desktop": .knowledgeManagement,
        "com.logseq.Logseq": .knowledgeManagement,
        "com.remnote": .knowledgeManagement,
        "io.tana.app": .knowledgeManagement,
        "com.evernote.Evernote": .knowledgeManagement,
        "com.apple.Notes": .knowledgeManagement,
        "com.apple.VoiceMemos": .knowledgeManagement,
        "com.devontechnologies.thinkingspace": .knowledgeManagement, // DEVONthink
        "com.omnigroup.OmniOutliner5": .knowledgeManagement,
        "com.agiletortoise.Drafts-OSX": .knowledgeManagement,
        "com.ulysses.mac": .knowledgeManagement,
        "com.microsoft.onenote.mac": .knowledgeManagement,
        "com.google.GoogleNotesDesktop": .knowledgeManagement, // Google Keep
        "com.coppiceapp.Coppice": .knowledgeManagement,
        "com.tinderbox.TinderboxSeven": .knowledgeManagement,
        "com.qvacua.VimR": .knowledgeManagement, // VimR for note-taking
        "com.typora.Typora": .knowledgeManagement,
        "com.inkdrop.Inkdrop": .knowledgeManagement,
        "com.zettlr.Zettlr": .knowledgeManagement,
        "com.zettelkasten.TheArchive": .knowledgeManagement,
        "com.boostnote.Boostnote": .knowledgeManagement,
        "com.joplinapp.Joplin": .knowledgeManagement,
        "com.standardnotes.StandardNotes": .knowledgeManagement,
        "com.upnote.UpNote": .knowledgeManagement,
        "com.agenda.Agenda": .knowledgeManagement,
        "com.craftsapp.Craft": .knowledgeManagement,

        // Utilities
        "com.apple.systempreferences": .utilities,
        "com.apple.finder": .utilities,
        "com.apple.ActivityMonitor": .utilities,
        "com.apple.Console": .utilities,
        "com.1password.1Password": .utilities,
        "com.dropbox.DropboxMac": .utilities,
        "com.google.DriveFS": .utilities, // Google Drive
        "com.alfredapp.Alfred": .utilities,
        "com.kapeli.dashdoc": .development, // Developer Documentation
        "com.apple.ScriptEditor2": .development,
        "com.postman.Postman": .development,
        "com.docker.docker": .development,
        "com.getflume.Flume": .socialMedia, // Instagram client

        // Fallback for common system apps if not covered
        "com.apple.QuickTimePlayerX": .entertainment,
        "com.apple.Preview": .utilities,
        "com.apple.AppStore": .utilities,
        "com.apple.PhotoBooth": .entertainment,
        "com.apple.calculator": .utilities,
        "com.apple.Stickies": .productivity,
        "com.apple.weather": .news, // Or lifestyle
        "com.apple.stocks": .finance,
        "com.apple.podcasts": .entertainment,
        "com.apple.news": .news,
        "com.apple.Home": .lifestyle,
        "com.apple.Maps": .travel,
        "com.apple.Siri": .utilities,
        "com.apple.Spotlight": .utilities
    ]

    // Load all custom category names defined by the user
    private static func loadUserDefinedCategoryNames() -> [String] {
        UserDefaults.standard.stringArray(forKey: userDefinedCategoryNamesKey) ?? []
    }

    // Save the list of custom category names
    private static func saveUserDefinedCategoryNames(_ names: [String]) {
        UserDefaults.standard.set(names, forKey: userDefinedCategoryNamesKey)
    }
    
    // Adds a new custom category name if it doesn't already exist (case-insensitive check)
    // Returns the AppCategory struct for the new or existing custom category.
    static func addUserDefinedCategory(name: String) -> AppCategory {
        var currentCustomNames = loadUserDefinedCategoryNames()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if a category with this name (case-insensitive) already exists as a custom one
        if let existingName = currentCustomNames.first(where: { $0.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            return AppCategory(name: existingName) // Return struct with the existing casing
        }
        // Also check if it clashes with a default category name (case-insensitive)
        if AppCategory.defaultCases.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            // If it clashes with a default, we just return the default category struct
            // Or, we could prevent creation. For now, let's prioritize default if name matches.
            return AppCategory.defaultCases.first { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }!
        }

        // If no clash, add the new custom name
        if !trimmedName.isEmpty {
            currentCustomNames.append(trimmedName)
            saveUserDefinedCategoryNames(currentCustomNames.sorted()) // Keep them sorted for consistency
        }
        return AppCategory(name: trimmedName)
    }

    // Get all available categories (defaults + user-defined)
    static func getAllAvailableCategories() -> [AppCategory] {
        let defaultCategories = AppCategory.defaultCases
        let customCategoryNames = loadUserDefinedCategoryNames()
        
        let customCategories = customCategoryNames.map { AppCategory(name: $0) }
        
        // Combine and remove duplicates (though addUserDefinedCategory should prevent exact name duplicates with defaults)
        let allCategories = (defaultCategories + customCategories).reduce(into: [AppCategory]()) { result, category in
            if !result.contains(where: { $0.name == category.name }) {
                result.append(category)
            }
        }
        return allCategories.sorted(by: { $0.name < $1.name }) // Sort them for the picker
    }

    // Load user-defined mappings (BundleID -> Category Name)
    private static func loadUserCategoryMappings() -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: userCategoryMappingsKey) else {
            return [:]
        }
        do {
            let mappings = try JSONDecoder().decode([String: String].self, from: data)
            return mappings
        } catch {
            print("Error decoding user category mappings: \(error)")
            return [:]
        }
    }

    // Save a user-defined mapping (BundleID -> Category Name)
    static func saveUserCategoryMapping(for bundleIdentifier: String, categoryName: String) {
        var userMappings = loadUserCategoryMappings()
        userMappings[bundleIdentifier] = categoryName
        do {
            let data = try JSONEncoder().encode(userMappings)
            UserDefaults.standard.set(data, forKey: userCategoryMappingsKey)
        } catch {
            print("Error encoding user category mappings: \(error)")
        }
    }

    static func getCategory(for bundleIdentifier: String?) -> AppCategory {
        guard let bundleId = bundleIdentifier, !bundleId.isEmpty else {
            return .other // Default AppCategory.other struct
        }

        // 1. Check user-defined mappings (BundleID -> Category Name)
        let userMappings = loadUserCategoryMappings()
        if let categoryName = userMappings[bundleId] {
            // Find this category (could be default or custom) by its name
            if let foundCategory = getAllAvailableCategories().first(where: { $0.name == categoryName }) {
                return foundCategory
            }
            // If the mapped name isn't in defaults or custom (e.g., data inconsistency), treat as Other
            // Or, better, ensure custom categories are always loaded.
            // The addUserDefinedCategory ensures custom category name exists. If a mapping exists,
            // the category name should ideally already be in userDefinedCategoryNames or be a default.
            // For robustness, if categoryName from mapping isn't a known default, assume it's a custom one.
            // This might re-add it if it somehow got deleted from userDefinedCategoryNames but not mappings.
            return addUserDefinedCategory(name: categoryName) 
        }

        // 2. Fall back to default mappings (BundleID -> AppCategory struct)
        if let defaultCat = defaultCategoryMappings[bundleId] {
            return defaultCat
        }
        
        // 3. If no mapping found, return 'Other'
        return .other
    }
}
