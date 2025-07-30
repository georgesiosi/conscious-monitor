import Foundation

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: String // "user", "assistant", or "system"
    let content: String
    let timestamp: Date
    let isFromCSDAgent: Bool // Track which agent responded
    let tokenCount: Int? // Optional: track token usage
    
    init(role: String, content: String, isFromCSDAgent: Bool = false, tokenCount: Int? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.isFromCSDAgent = isFromCSDAgent
        self.tokenCount = tokenCount
    }
}

// MARK: - Chat Mode
enum ChatMode: String, CaseIterable, Codable {
    case auto = "auto"           // Smart routing based on content
    case generalAI = "general"   // Always use user's OpenAI
    case csdCoach = "csd"        // Always use CSD agents
    
    var displayName: String {
        switch self {
        case .auto: return "Smart Routing"
        case .generalAI: return "General AI"
        case .csdCoach: return "CSD Coach"
        }
    }
    
    var icon: String {
        switch self {
        case .auto: return "brain.head.profile"
        case .generalAI: return "cpu"
        case .csdCoach: return "target"
        }
    }
    
    var description: String {
        switch self {
        case .auto: return "Automatically routes to the best AI for your question"
        case .generalAI: return "Uses your OpenAI key for all responses"
        case .csdCoach: return "Uses specialized CSD coaching agents"
        }
    }
}

// MARK: - Conversation Context
struct ConversationContext: Codable {
    let analysisId: String
    let originalAnalysis: String
    let csdInsightsSummary: String // Condensed version of insights
    let userGoals: String
    let aboutMe: String
    let categoryMetricsSummary: String // Key metrics only
    let sessionStartTime: Date
    
    init(
        analysisId: String,
        originalAnalysis: String,
        csdInsights: [CSDInsight],
        categoryMetrics: [CategoryUsageMetrics],
        userGoals: String,
        aboutMe: String
    ) {
        self.analysisId = analysisId
        self.originalAnalysis = originalAnalysis
        self.userGoals = userGoals
        self.aboutMe = aboutMe
        self.sessionStartTime = Date()
        
        // Create condensed summaries to save tokens
        self.csdInsightsSummary = Self.createInsightsSummary(insights: csdInsights)
        self.categoryMetricsSummary = Self.createMetricsSummary(metrics: categoryMetrics)
    }
    
    // Create a condensed summary of CSD insights
    private static func createInsightsSummary(insights: [CSDInsight]) -> String {
        let highPriorityInsights = insights.filter { $0.priority == .high }
        let mediumPriorityInsights = insights.filter { $0.priority == .medium }
        
        var summary = ""
        
        if !highPriorityInsights.isEmpty {
            summary += "High Priority Issues: "
            summary += highPriorityInsights.map { "\($0.category.name) - \($0.title)" }.joined(separator: ", ")
        }
        
        if !mediumPriorityInsights.isEmpty {
            if !summary.isEmpty { summary += ". " }
            summary += "Medium Priority: "
            summary += mediumPriorityInsights.map { "\($0.category.name) - \($0.title)" }.joined(separator: ", ")
        }
        
        return summary.isEmpty ? "No major issues identified." : summary
    }
    
    // Create a condensed summary of category metrics
    private static func createMetricsSummary(metrics: [CategoryUsageMetrics]) -> String {
        let violations = metrics.filter { $0.compliance == .violation }
        let warnings = metrics.filter { $0.compliance == .warning }
        let healthy = metrics.filter { $0.compliance == .healthy }
        
        return "CSD Compliance: \(healthy.count) healthy, \(warnings.count) warnings, \(violations.count) violations. " +
               "Average cognitive load: \(String(format: "%.1f", metrics.isEmpty ? 0.0 : metrics.reduce(0.0) { $0 + $1.cognitiveLoad } / Double(metrics.count)))/10"
    }
    
    // Generate system prompt with full context
    func generateSystemPrompt(forCSDAgent: Bool = false) -> String {
        let basePrompt = forCSDAgent ? 
            """
            You are a specialized Conscious Stack Design (CSD) productivity coach. You help users optimize their tool stacks using the 5:3:1 framework and improve their productivity workflows. You have deep knowledge of the CSD methodology and can provide personalized coaching based on their specific usage patterns.
            """ :
            """
            You are a helpful AI assistant analyzing productivity and app usage patterns. You provide practical advice based on the user's digital behavior and workflow data.
            """
        
        return """
        \(basePrompt)
        
        CURRENT USER CONTEXT:
        - Analysis ID: \(analysisId)
        - Session started: \(sessionStartTime.formatted(date: .abbreviated, time: .shortened))
        
        USER PROFILE:
        About: \(aboutMe.isEmpty ? "Not provided" : aboutMe)
        Goals: \(userGoals.isEmpty ? "Not provided" : userGoals)
        
        RECENT ANALYSIS SUMMARY:
        \(originalAnalysis.prefix(500))...
        
        CSD INSIGHTS: \(csdInsightsSummary)
        STACK HEALTH: \(categoryMetricsSummary)
        
        INSTRUCTIONS:
        - Reference their specific analysis and insights in your responses
        - Provide actionable, personalized advice
        - Keep responses concise but helpful
        - Ask clarifying questions when needed
        """
    }
}

// MARK: - Chat Session
struct ChatSession: Identifiable, Codable {
    let id: UUID
    let analysisId: String
    let startDate: Date
    let lastUpdated: Date
    let context: ConversationContext
    let messages: [ChatMessage]
    let totalTokensUsed: Int
    
    init(context: ConversationContext) {
        self.id = UUID()
        self.analysisId = context.analysisId
        self.startDate = Date()
        self.lastUpdated = Date()
        self.context = context
        self.messages = []
        self.totalTokensUsed = 0
    }
    
    // Update session with new message
    func withNewMessage(_ message: ChatMessage) -> ChatSession {
        var updatedMessages = self.messages
        updatedMessages.append(message)
        
        return ChatSession(
            id: self.id,
            analysisId: self.analysisId,
            startDate: self.startDate,
            lastUpdated: Date(),
            context: self.context,
            messages: updatedMessages,
            totalTokensUsed: self.totalTokensUsed + (message.tokenCount ?? 0)
        )
    }
    
    private init(
        id: UUID,
        analysisId: String,
        startDate: Date,
        lastUpdated: Date,
        context: ConversationContext,
        messages: [ChatMessage],
        totalTokensUsed: Int
    ) {
        self.id = id
        self.analysisId = analysisId
        self.startDate = startDate
        self.lastUpdated = lastUpdated
        self.context = context
        self.messages = messages
        self.totalTokensUsed = totalTokensUsed
    }
}

// MARK: - Smart Routing Logic
struct ChatRouter {
    
    /// Determine if a message should route to CSD agents based on content analysis
    static func shouldUseCSDAgent(for message: String, mode: ChatMode) -> Bool {
        switch mode {
        case .generalAI:
            return false
        case .csdCoach:
            return true
        case .auto:
            return analyzeMessageForCSDRelevance(message)
        }
    }
    
    /// Analyze message content to determine CSD relevance
    private static func analyzeMessageForCSDRelevance(_ message: String) -> Bool {
        let csdKeywords = [
            // CSD Framework terms
            "5:3:1", "five three one", "conscious stack", "csd",
            "stack health", "compliance", "cognitive load",
            
            // Productivity/workflow terms
            "productivity", "workflow", "workstyle", "efficiency",
            "consolidate", "consolidation", "optimize", "streamline",
            "focus", "context switching", "distraction",
            
            // Tool management
            "too many tools", "app switching", "tool stack",
            "simplify", "reduce apps", "primary tool",
            
            // Category-specific
            "communication tools", "development tools", "design tools",
            "productivity apps", "collaboration"
        ]
        
        let lowercaseMessage = message.lowercased()
        
        // Check for exact keyword matches
        for keyword in csdKeywords {
            if lowercaseMessage.contains(keyword) {
                return true
            }
        }
        
        // Check for productivity-related questions
        let productivityPatterns = [
            "how can i improve",
            "what should i do about",
            "help me optimize",
            "reduce my",
            "better workflow",
            "more efficient"
        ]
        
        for pattern in productivityPatterns {
            if lowercaseMessage.contains(pattern) {
                return true
            }
        }
        
        return false
    }
}
