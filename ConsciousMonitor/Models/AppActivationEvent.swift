import Foundation
import AppKit

// Struct to hold information about an app activation event
// Make it Codable for JSON serialization
struct AppActivationEvent: Identifiable, Codable, Equatable, Sendable {
    
    // Equatable implementation that excludes NSImage properties
    static func == (lhs: AppActivationEvent, rhs: AppActivationEvent) -> Bool {
        return lhs.id == rhs.id &&
               lhs.timestamp == rhs.timestamp &&
               lhs.appName == rhs.appName &&
               lhs.bundleIdentifier == rhs.bundleIdentifier &&
               lhs.chromeTabTitle == rhs.chromeTabTitle &&
               lhs.chromeTabUrl == rhs.chromeTabUrl &&
               lhs.siteDomain == rhs.siteDomain &&
               lhs.category == rhs.category &&
               lhs.sessionId == rhs.sessionId &&
               lhs.sessionStartTime == rhs.sessionStartTime &&
               lhs.sessionEndTime == rhs.sessionEndTime &&
               lhs.isSessionStart == rhs.isSessionStart &&
               lhs.isSessionEnd == rhs.isSessionEnd &&
               lhs.sessionSwitchCount == rhs.sessionSwitchCount
    }
    let id: UUID
    let timestamp: Date
    let appName: String?
    let bundleIdentifier: String?
    
    // Chrome tab info
    var chromeTabTitle: String? = nil
    var chromeTabUrl: String? = nil
    var siteDomain: String? = nil
    var appIcon: NSImage?
    var siteFavicon: NSImage?
    var category: AppCategory
    
    // Session tracking properties
    var sessionId: UUID?
    var sessionStartTime: Date?
    var sessionEndTime: Date?
    var isSessionStart: Bool = false
    var isSessionEnd: Bool = false
    var sessionSwitchCount: Int = 1

    // Custom Codable conformance to exclude NSImage
    enum CodingKeys: String, CodingKey {
        case id, timestamp, appName, bundleIdentifier, chromeTabTitle, chromeTabUrl, siteDomain, category
        case sessionId, sessionStartTime, sessionEndTime, isSessionStart, isSessionEnd, sessionSwitchCount
        // appIcon and siteFavicon are omitted
    }

    // Custom init for decoding (appIcon and siteFavicon will be nil)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        appName = try container.decodeIfPresent(String.self, forKey: .appName)
        bundleIdentifier = try container.decodeIfPresent(String.self, forKey: .bundleIdentifier)
        chromeTabTitle = try container.decodeIfPresent(String.self, forKey: .chromeTabTitle)
        chromeTabUrl = try container.decodeIfPresent(String.self, forKey: .chromeTabUrl)
        siteDomain = try container.decodeIfPresent(String.self, forKey: .siteDomain)
        category = try container.decode(AppCategory.self, forKey: .category)
        
        // Decode session-related properties
        sessionId = try container.decodeIfPresent(UUID.self, forKey: .sessionId)
        sessionStartTime = try container.decodeIfPresent(Date.self, forKey: .sessionStartTime)
        sessionEndTime = try container.decodeIfPresent(Date.self, forKey: .sessionEndTime)
        isSessionStart = try container.decodeIfPresent(Bool.self, forKey: .isSessionStart) ?? false
        isSessionEnd = try container.decodeIfPresent(Bool.self, forKey: .isSessionEnd) ?? false
        sessionSwitchCount = try container.decodeIfPresent(Int.self, forKey: .sessionSwitchCount) ?? 1
        
        appIcon = nil // Icons are not persisted
        siteFavicon = nil // Favicons are not persisted
    }

    // Custom encode (appIcon and siteFavicon are not encoded)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(appName, forKey: .appName)
        try container.encodeIfPresent(bundleIdentifier, forKey: .bundleIdentifier)
        try container.encodeIfPresent(chromeTabTitle, forKey: .chromeTabTitle)
        try container.encodeIfPresent(chromeTabUrl, forKey: .chromeTabUrl)
        try container.encodeIfPresent(siteDomain, forKey: .siteDomain)
        try container.encode(category, forKey: .category)
        
        // Encode session-related properties
        try container.encodeIfPresent(sessionId, forKey: .sessionId)
        try container.encodeIfPresent(sessionStartTime, forKey: .sessionStartTime)
        try container.encodeIfPresent(sessionEndTime, forKey: .sessionEndTime)
        try container.encode(isSessionStart, forKey: .isSessionStart)
        try container.encode(isSessionEnd, forKey: .isSessionEnd)
        try container.encode(sessionSwitchCount, forKey: .sessionSwitchCount)
    }

    // Main initializer used when creating new events
    init(id: UUID = UUID(), timestamp: Date = Date(), appName: String?, bundleIdentifier: String?, 
         chromeTabTitle: String? = nil, chromeTabUrl: String? = nil, siteDomain: String? = nil, 
         appIcon: NSImage? = nil, siteFavicon: NSImage? = nil, category: AppCategory,
         sessionId: UUID? = nil, sessionStartTime: Date? = nil, sessionEndTime: Date? = nil,
         isSessionStart: Bool = false, isSessionEnd: Bool = false, sessionSwitchCount: Int = 1) {
        self.id = id
        self.timestamp = timestamp
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.chromeTabTitle = chromeTabTitle
        self.chromeTabUrl = chromeTabUrl
        self.siteDomain = siteDomain
        self.appIcon = appIcon
        self.siteFavicon = siteFavicon
        self.sessionId = sessionId
        self.sessionStartTime = sessionStartTime
        self.sessionEndTime = sessionEndTime
        self.isSessionStart = isSessionStart
        self.isSessionEnd = isSessionEnd
        self.sessionSwitchCount = sessionSwitchCount
        self.category = category
    }
}
