import Foundation
import SwiftUI // For Color

struct AppCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    // We might add 'isDefault: Bool' later if needed for specific UI handling,
    // but for now, AppCategorizer can manage the distinction.

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    // Default Categories
    static let productivity = AppCategory(name: "Productivity")
    static let communication = AppCategory(name: "Communication")
    static let socialMedia = AppCategory(name: "Social Media")
    static let development = AppCategory(name: "Development")
    static let entertainment = AppCategory(name: "Entertainment")
    static let design = AppCategory(name: "Design")
    static let utilities = AppCategory(name: "Utilities")
    static let education = AppCategory(name: "Education")
    static let finance = AppCategory(name: "Finance")
    static let health = AppCategory(name: "Health & Fitness")
    static let lifestyle = AppCategory(name: "Lifestyle")
    static let news = AppCategory(name: "News")
    static let shopping = AppCategory(name: "Shopping")
    static let travel = AppCategory(name: "Travel")
    static let knowledgeManagement = AppCategory(name: "Knowledge Management")
    static let other = AppCategory(name: "Other") // The crucial one for initiating custom categories

    // For Picker usage - this will be expanded by AppCategorizer later
    // to include user-defined categories.
    static var defaultCases: [AppCategory] {
        [
            .productivity,
            .communication,
            .socialMedia,
            .development,
            .entertainment,
            .design,
            .utilities,
            .education,
            .finance,
            .health,
            .lifestyle,
            .news,
            .shopping,
            .travel,
            .knowledgeManagement,
            .other
        ]
    }
    
    // Color for this category
    var color: Color {
        AppCategory.color(forName: self.name)
    }
    
    // Description for this category
    var description: String {
        AppCategory.description(forName: self.name)
    }
    
    // Static method to get color for a category name
    static func color(forName name: String) -> Color {
        let defaultColors: [String: Color] = [
            AppCategory.communication.name: .blue,
            AppCategory.productivity.name: .green,
            AppCategory.development.name: .orange,
            AppCategory.entertainment.name: .red,
            AppCategory.design.name: .pink,
            AppCategory.utilities.name: .gray,
            AppCategory.other.name: .yellow,
            AppCategory.education.name: .teal,
            AppCategory.finance.name: .purple,    // Was .mint
            AppCategory.news.name: Color(red: 0.6, green: 0.4, blue: 0.2), // Custom Brown
            AppCategory.lifestyle.name: .indigo,   // Was .purple
            AppCategory.travel.name: .orange,
            // Added from AppCategory.swift definition
            AppCategory.health.name: Color(red: 0.9, green: 0.5, blue: 0.5), // Light Red/Pink
            AppCategory.shopping.name: Color(red: 0.8, green: 0.2, blue: 0.2),  // Deep Red
            AppCategory.socialMedia.name: .cyan,
            AppCategory.knowledgeManagement.name: Color(red: 0.5, green: 0.2, blue: 0.8) // Deep Purple
        ]

        if let predefinedColor = defaultColors[name] {
            return predefinedColor
        }

        // Fallback for user-defined categories or those not in the map
        var hash = 0
        for char in name.unicodeScalars {
            hash = 31 &* hash &+ Int(char.value)
        }
        let hue = Double(abs(hash) % 256) / 256.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
    
    // Static method to get description for a category name
    static func description(forName name: String) -> String {
        let defaultDescriptions: [String: String] = [
            AppCategory.productivity.name: "Tools for getting work done efficiently - note-taking, task management, and planning apps",
            AppCategory.communication.name: "Apps for connecting with others - email, messaging, video calls, and collaboration tools",
            AppCategory.socialMedia.name: "Social networking platforms and community apps for staying connected",
            AppCategory.development.name: "Programming tools, IDEs, version control, and software development utilities",
            AppCategory.entertainment.name: "Apps for leisure and fun - games, streaming, music, and media consumption",
            AppCategory.design.name: "Creative tools for visual design, graphics, prototyping, and artistic work",
            AppCategory.utilities.name: "System tools and helpful utilities that enhance your Mac experience",
            AppCategory.education.name: "Learning apps, courses, references, and educational resources",
            AppCategory.finance.name: "Banking, budgeting, investing, and personal finance management tools",
            AppCategory.health.name: "Wellness, fitness tracking, medical apps, and health monitoring tools",
            AppCategory.lifestyle.name: "Apps for daily living - home management, shopping, travel, and personal organization",
            AppCategory.news.name: "News readers, current events, and information consumption apps",
            AppCategory.shopping.name: "E-commerce, price comparison, and online shopping applications",
            AppCategory.travel.name: "Trip planning, booking, navigation, and travel-related applications",
            AppCategory.knowledgeManagement.name: "Note-taking, knowledge bases, documentation, and information organization tools",
            AppCategory.other.name: "Apps that don't fit into the standard categories - perfect for specialized tools"
        ]
        
        return defaultDescriptions[name] ?? "Custom category for organizing your specialized tools"
    }
    
    // Conformance to Hashable (name is sufficient for uniqueness among defaults and user-added)
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    // Conformance to Equatable (name is sufficient for uniqueness)
    static func == (lhs: AppCategory, rhs: AppCategory) -> Bool {
        lhs.name == rhs.name
    }
}
