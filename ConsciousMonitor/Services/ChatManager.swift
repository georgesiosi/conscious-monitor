import Foundation
import SwiftUI

@MainActor
class ChatManager: ObservableObject {
    @Published var currentSession: ChatSession?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var chatMode: ChatMode = .auto
    
    private let openAIService = OpenAIService()
    private let userSettings = UserSettings.shared
    
    // File paths for saving sessions (new canonical + legacy fallback)
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ConsciousMonitor")
            .appendingPathComponent("ChatSessions")
    }

    private var legacyDocumentsDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("FocusMonitor")
            .appendingPathComponent("ChatSessions")
    }
    
    init() {
        // Ensure new documents directory exists
        try? FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)

        // Minimal migration: if legacy directory exists with files and new is empty, copy files forward
        let fm = FileManager.default
        if fm.fileExists(atPath: legacyDocumentsDirectory.path) {
            let newIsEmpty = (try? fm.contentsOfDirectory(atPath: documentsDirectory.path).isEmpty) ?? true
            if newIsEmpty {
                if let items = try? fm.contentsOfDirectory(atPath: legacyDocumentsDirectory.path) {
                    for item in items where item.hasSuffix(".json") {
                        let src = legacyDocumentsDirectory.appendingPathComponent(item)
                        let dst = documentsDirectory.appendingPathComponent(item)
                        _ = try? fm.copyItem(at: src, to: dst)
                    }
                }
            }
        }
        
        // Initialize chat mode from user settings
        self.chatMode = userSettings.defaultChatMode
    }
    
    // MARK: - Session Management
    
    /// Start a new chat session with context
    func startNewSession(
        analysisId: String,
        originalAnalysis: String,
        csdInsights: [CSDInsight],
        categoryMetrics: [CategoryUsageMetrics]
    ) {
        let context = ConversationContext(
            analysisId: analysisId,
            originalAnalysis: originalAnalysis,
            csdInsights: csdInsights,
            categoryMetrics: categoryMetrics,
            userGoals: userSettings.userGoals,
            aboutMe: userSettings.aboutMe
        )
        
        self.currentSession = ChatSession(context: context)
        saveCurrentSession()
    }
    
    /// Load existing session for analysis ID
    func loadSessionIfExists(for analysisId: String) -> Bool {
        let primaryURL = documentsDirectory.appendingPathComponent("\(analysisId).json")
        let legacyURL = legacyDocumentsDirectory.appendingPathComponent("\(analysisId).json")

        var loadedSession: ChatSession?
        if let data = try? Data(contentsOf: primaryURL),
           let session = try? JSONDecoder().decode(ChatSession.self, from: data) {
            loadedSession = session
        } else if let data = try? Data(contentsOf: legacyURL),
                  let session = try? JSONDecoder().decode(ChatSession.self, from: data) {
            loadedSession = session
        }

        guard let session = loadedSession else { return false }
        
        self.currentSession = session
        return true
    }
    
    /// Save current session to disk
    private func saveCurrentSession() {
        guard let session = currentSession else { return }
        
        let sessionURL = documentsDirectory.appendingPathComponent("\(session.analysisId).json")
        
        do {
            let data = try JSONEncoder().encode(session)
            try data.write(to: sessionURL)
        } catch {
            print("Failed to save chat session: \(error)")
        }
    }
    
    // MARK: - Chat Operations
    
    /// Send a message and get AI response
    func sendMessage(_ content: String) async {
        guard let session = currentSession else {
            errorMessage = "No active chat session"
            return
        }
        
        // Clear any previous errors
        errorMessage = nil
        isLoading = true
        
        // Add user message
        let userMessage = ChatMessage(role: "user", content: content)
        currentSession = session.withNewMessage(userMessage)
        saveCurrentSession()
        
        // Determine which AI service to use
        let shouldUseCSD = ChatRouter.shouldUseCSDAgent(for: content, mode: chatMode)
        let apiKey = shouldUseCSD && userSettings.enableCSDCoaching ? userSettings.csdAgentKey : userSettings.openAIAPIKey
        
        // Validate API key
        guard !apiKey.isEmpty else {
            let serviceName = shouldUseCSD ? "CSD Agent" : "OpenAI"
            errorMessage = "\(serviceName) API key is required. Please add it in Settings."
            isLoading = false
            return
        }
        
        // Prepare conversation history for API call
        let conversationMessages = prepareConversationForAPI(shouldUseCSD: shouldUseCSD)
        
        // Make API call
        let result = await openAIService.sendChatMessage(
            apiKey: apiKey,
            messages: conversationMessages,
            useCSDAgent: shouldUseCSD
        )
        
        switch result {
        case .success(let response):
            // Add assistant response
            let assistantMessage = ChatMessage(
                role: "assistant",
                content: response,
                isFromCSDAgent: shouldUseCSD
            )
            
            currentSession = currentSession?.withNewMessage(assistantMessage)
            saveCurrentSession()
            
        case .failure(let error):
            switch error {
            case .apiError(let message):
                errorMessage = "API Error: \(message)"
            case .requestFailed(let underlyingError):
                errorMessage = "Network Error: \(underlyingError.localizedDescription)"
            default:
                errorMessage = "Failed to get response: \(error)"
            }
        }
        
        isLoading = false
    }
    
    /// Update chat mode and save to settings
    func updateChatMode(_ newMode: ChatMode) {
        chatMode = newMode
        userSettings.defaultChatMode = newMode
    }
    
    // MARK: - Private Helpers
    
    /// Prepare conversation messages for API call
    private func prepareConversationForAPI(shouldUseCSD: Bool) -> [OpenAIMessage] {
        guard let session = currentSession else { return [] }
        
        var apiMessages: [OpenAIMessage] = []
        
        // Add system message with context
        let systemPrompt = session.context.generateSystemPrompt(forCSDAgent: shouldUseCSD)
        apiMessages.append(OpenAIMessage(role: "system", content: systemPrompt))
        
        // Add conversation history (excluding any existing system messages)
        let conversationMessages = session.messages.filter { $0.role != "system" }
        
        // Keep only recent messages to manage token limits (last 10 messages)
        let recentMessages = Array(conversationMessages.suffix(10))
        
        for message in recentMessages {
            apiMessages.append(OpenAIMessage(
                role: message.role,
                content: message.content
            ))
        }
        
        return apiMessages
    }
}

// MARK: - Preview Support
extension ChatManager {
    static func preview() -> ChatManager {
        let manager = ChatManager()
        
        // Create a sample session for preview
        let sampleContext = ConversationContext(
            analysisId: "preview",
            originalAnalysis: "Sample analysis for preview",
            csdInsights: [],
            categoryMetrics: [],
            userGoals: "Improve productivity",
            aboutMe: "Developer working on productivity tools"
        )
        
        let sampleSession = ChatSession(context: sampleContext)
        let sampleMessage1 = ChatMessage(role: "user", content: "How can I improve my productivity?")
        let sampleMessage2 = ChatMessage(role: "assistant", content: "Based on your usage patterns, I recommend focusing on consolidating your communication tools and establishing clear focus blocks throughout your day.")
        
        manager.currentSession = sampleSession.withNewMessage(sampleMessage1).withNewMessage(sampleMessage2)
        
        return manager
    }
}
