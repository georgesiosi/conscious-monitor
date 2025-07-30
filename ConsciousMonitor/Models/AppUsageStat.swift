import Foundation
import AppKit

// Struct to hold app usage statistics
struct AppUsageStat: Identifiable, Codable {
    let id: UUID
    let appName: String
    let bundleIdentifier: String?
    let activationCount: Int
    var appIcon: NSImage?
    let lastActiveTimestamp: Date
    var category: AppCategory
    var siteBreakdown: [SiteUsageStat]? = nil // For Chrome, a breakdown of sites visited
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        appName: String,
        bundleIdentifier: String?,
        activationCount: Int,
        appIcon: NSImage? = nil,
        lastActiveTimestamp: Date,
        category: AppCategory,
        siteBreakdown: [SiteUsageStat]? = nil
    ) {
        self.id = id
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.activationCount = activationCount
        self.appIcon = appIcon
        self.lastActiveTimestamp = lastActiveTimestamp
        self.category = category
        self.siteBreakdown = siteBreakdown
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, appName, bundleIdentifier, activationCount
        case lastActiveTimestamp, category, siteBreakdown
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        appName = try container.decode(String.self, forKey: .appName)
        bundleIdentifier = try container.decodeIfPresent(String.self, forKey: .bundleIdentifier)
        activationCount = try container.decode(Int.self, forKey: .activationCount)
        lastActiveTimestamp = try container.decode(Date.self, forKey: .lastActiveTimestamp)
        category = try container.decode(AppCategory.self, forKey: .category)
        siteBreakdown = try container.decodeIfPresent([SiteUsageStat].self, forKey: .siteBreakdown)
        appIcon = nil // Icons are not persisted
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(appName, forKey: .appName)
        try container.encodeIfPresent(bundleIdentifier, forKey: .bundleIdentifier)
        try container.encode(activationCount, forKey: .activationCount)
        try container.encode(lastActiveTimestamp, forKey: .lastActiveTimestamp)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(siteBreakdown, forKey: .siteBreakdown)
        // appIcon is not encoded as NSImage is not Codable
    }
}

// Struct to hold site usage statistics for Chrome
struct SiteUsageStat: Identifiable, Codable {
    let id: UUID
    let siteDomain: String
    var displayTitle: String // e.g., siteDomain or a recent tab title
    var siteFavicon: NSImage?
    let activationCount: Int
    var lastActiveTimestamp: Date
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        siteDomain: String,
        displayTitle: String,
        siteFavicon: NSImage? = nil,
        activationCount: Int,
        lastActiveTimestamp: Date
    ) {
        self.id = id
        self.siteDomain = siteDomain
        self.displayTitle = displayTitle
        self.siteFavicon = siteFavicon
        self.activationCount = activationCount
        self.lastActiveTimestamp = lastActiveTimestamp
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, siteDomain, displayTitle, activationCount, lastActiveTimestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        siteDomain = try container.decode(String.self, forKey: .siteDomain)
        displayTitle = try container.decode(String.self, forKey: .displayTitle)
        activationCount = try container.decode(Int.self, forKey: .activationCount)
        lastActiveTimestamp = try container.decode(Date.self, forKey: .lastActiveTimestamp)
        siteFavicon = nil // Favicons are not persisted
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(siteDomain, forKey: .siteDomain)
        try container.encode(displayTitle, forKey: .displayTitle)
        try container.encode(activationCount, forKey: .activationCount)
        try container.encode(lastActiveTimestamp, forKey: .lastActiveTimestamp)
        // siteFavicon is not encoded as NSImage is not Codable
    }
}
