import Foundation

// MARK: - AI Provider Types

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI = "openai"
    case claude = "claude"
    case grok = "grok"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .claude: return "Claude"
        case .grok: return "Grok"
        }
    }
    
    var icon: String {
        switch self {
        case .openAI: return "brain.head.profile"
        case .claude: return "sparkles"
        case .grok: return "bolt.horizontal"
        }
    }
}

// MARK: - AI Gateway Configuration

struct AIGatewayConfig {
    var primaryProvider: AIProvider = .openAI
    var fallbackProvider: AIProvider? = nil
    var enableCaching: Bool = true
    var timeout: TimeInterval = 30.0
    
    // Provider-specific settings
    var openAIModel: String = "gpt-4o"
    var claudeModel: String = "claude-3-sonnet-20240229"
    var grokModel: String = "grok-beta"
}

// MARK: - Universal AI Message Format

struct AIMessage {
    let role: String
    let content: String
    
    // Convert to provider-specific format
    func toOpenAI() -> OpenAIMessage {
        OpenAIMessage(role: role, content: content)
    }
    
    func toClaude() -> ClaudeMessage {
        ClaudeMessage(role: role, content: content)
    }
    
    func toGrok() -> GrokMessage {
        GrokMessage(role: role, content: content)
    }
}

// MARK: - Provider-Specific Message Formats

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct GrokMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Provider-Specific Request/Response Models

// Claude Models
struct ClaudeRequest: Codable {
    let model: String
    let messages: [ClaudeMessage]
    let maxTokens: Int = 4000
    
    enum CodingKeys: String, CodingKey {
        case model, messages
        case maxTokens = "max_tokens"
    }
}

struct ClaudeResponse: Codable {
    let content: [ClaudeContent]?
    let error: ClaudeError?
}

struct ClaudeContent: Codable {
    let text: String?
}

struct ClaudeError: Codable {
    let message: String
    let type: String?
}

// Grok Models
struct GrokRequest: Codable {
    let model: String
    let messages: [GrokMessage]
    let temperature: Double = 0.7
}

struct GrokResponse: Codable {
    let choices: [GrokChoice]?
    let error: GrokError?
}

struct GrokChoice: Codable {
    let message: GrokMessage?
}

struct GrokError: Codable {
    let message: String
    let code: String?
}

// MARK: - AI Gateway Service

class AIGatewayService: ObservableObject {
    @Published var config = AIGatewayConfig()
    @Published var isOnline: Bool = true
    
    private var responseCache: [String: (response: String, timestamp: Date)] = [:]
    private let cacheExpirationTime: TimeInterval = 3600 // 1 hour
    
    enum AIGatewayError: Error {
        case noValidProvider
        case allProvidersFailed([Error])
        case configurationError(String)
        case networkError(Error)
        case providerSpecificError(String)
    }
    
    // MARK: - Main Gateway Method
    
    func sendMessage(
        messages: [AIMessage],
        apiKeys: [AIProvider: String],
        useCase: String = "general"
    ) async -> Result<String, AIGatewayError> {
        // Check cache first
        if config.enableCaching {
            let cacheKey = generateCacheKey(messages: messages, provider: config.primaryProvider)
            if let cachedResult = getCachedResponse(for: cacheKey) {
                return .success(cachedResult)
            }
        }
        
        // Try primary provider first
        let primaryResult = await sendToProvider(
            config.primaryProvider,
            messages: messages,
            apiKey: apiKeys[config.primaryProvider] ?? "",
            useCase: useCase
        )
        
        switch primaryResult {
        case .success(let response):
            // Cache successful response
            if config.enableCaching {
                let cacheKey = generateCacheKey(messages: messages, provider: config.primaryProvider)
                cacheResponse(response, for: cacheKey)
            }
            return .success(response)
            
        case .failure(let primaryError):
            // Try fallback provider if available
            if let fallbackProvider = config.fallbackProvider,
               let fallbackKey = apiKeys[fallbackProvider] {
                
                let fallbackResult = await sendToProvider(
                    fallbackProvider,
                    messages: messages,
                    apiKey: fallbackKey,
                    useCase: useCase
                )
                
                switch fallbackResult {
                case .success(let response):
                    // Cache successful fallback response
                    if config.enableCaching {
                        let cacheKey = generateCacheKey(messages: messages, provider: fallbackProvider)
                        cacheResponse(response, for: cacheKey)
                    }
                    return .success(response)
                    
                case .failure(let fallbackError):
                    return .failure(.allProvidersFailed([primaryError, fallbackError]))
                }
            } else {
                return .failure(.allProvidersFailed([primaryError]))
            }
        }
    }
    
    // MARK: - Provider-Specific Methods
    
    private func sendToProvider(
        _ provider: AIProvider,
        messages: [AIMessage],
        apiKey: String,
        useCase: String
    ) async -> Result<String, Error> {
        guard !apiKey.isEmpty else {
            return .failure(AIGatewayError.configurationError("No API key for \(provider.displayName)"))
        }
        
        switch provider {
        case .openAI:
            return await sendToOpenAI(messages: messages, apiKey: apiKey)
        case .claude:
            return await sendToClaude(messages: messages, apiKey: apiKey)
        case .grok:
            return await sendToGrok(messages: messages, apiKey: apiKey)
        }
    }
    
    private func sendToOpenAI(messages: [AIMessage], apiKey: String) async -> Result<String, Error> {
        let openAIMessages = messages.map { $0.toOpenAI() }
        let openAIService = OpenAIService()
        
        let result = await openAIService.sendChatMessage(
            apiKey: apiKey,
            messages: openAIMessages,
            model: config.openAIModel
        )
        
        switch result {
        case .success(let response):
            return .success(response)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    private func sendToClaude(messages: [AIMessage], apiKey: String) async -> Result<String, Error> {
        let claudeMessages = messages.map { $0.toClaude() }
        
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return .failure(AIGatewayError.configurationError("Invalid Claude API URL"))
        }
        
        let requestBody = ClaudeRequest(
            model: config.claudeModel,
            messages: claudeMessages
        )
        
        var request = URLRequest(url: url, timeoutInterval: config.timeout)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(AIGatewayError.networkError(URLError(.badServerResponse)))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let decodedError = try? JSONDecoder().decode(ClaudeResponse.self, from: data),
                   let errorMessage = decodedError.error?.message {
                    return .failure(AIGatewayError.providerSpecificError("Claude API Error (\(httpResponse.statusCode)): \(errorMessage)"))
                }
                return .failure(AIGatewayError.providerSpecificError("Claude API Error: HTTP \(httpResponse.statusCode)"))
            }
            
            let decodedResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            
            guard let content = decodedResponse.content?.first?.text else {
                return .failure(AIGatewayError.providerSpecificError("No content in Claude response"))
            }
            
            return .success(content.trimmingCharacters(in: .whitespacesAndNewlines))
            
        } catch {
            return .failure(AIGatewayError.networkError(error))
        }
    }
    
    private func sendToGrok(messages: [AIMessage], apiKey: String) async -> Result<String, Error> {
        let grokMessages = messages.map { $0.toGrok() }
        
        guard let url = URL(string: "https://api.x.ai/v1/chat/completions") else {
            return .failure(AIGatewayError.configurationError("Invalid Grok API URL"))
        }
        
        let requestBody = GrokRequest(
            model: config.grokModel,
            messages: grokMessages
        )
        
        var request = URLRequest(url: url, timeoutInterval: config.timeout)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(AIGatewayError.networkError(URLError(.badServerResponse)))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let decodedError = try? JSONDecoder().decode(GrokResponse.self, from: data),
                   let errorMessage = decodedError.error?.message {
                    return .failure(AIGatewayError.providerSpecificError("Grok API Error (\(httpResponse.statusCode)): \(errorMessage)"))
                }
                return .failure(AIGatewayError.providerSpecificError("Grok API Error: HTTP \(httpResponse.statusCode)"))
            }
            
            let decodedResponse = try JSONDecoder().decode(GrokResponse.self, from: data)
            
            guard let choice = decodedResponse.choices?.first,
                  let messageContent = choice.message?.content else {
                return .failure(AIGatewayError.providerSpecificError("No content in Grok response"))
            }
            
            return .success(messageContent.trimmingCharacters(in: .whitespacesAndNewlines))
            
        } catch {
            return .failure(AIGatewayError.networkError(error))
        }
    }
    
    // MARK: - Caching Methods
    
    private func generateCacheKey(messages: [AIMessage], provider: AIProvider) -> String {
        let messagesString = messages.map { "\($0.role):\($0.content)" }.joined(separator: "|")
        return "\(provider.rawValue):\(messagesString.hash)"
    }
    
    private func getCachedResponse(for key: String) -> String? {
        guard let cached = responseCache[key] else { return nil }
        
        // Check if cache is still valid
        if Date().timeIntervalSince(cached.timestamp) > cacheExpirationTime {
            responseCache.removeValue(forKey: key)
            return nil
        }
        
        return cached.response
    }
    
    private func cacheResponse(_ response: String, for key: String) {
        responseCache[key] = (response: response, timestamp: Date())
    }
    
    // MARK: - Configuration Methods
    
    func updateConfig(_ newConfig: AIGatewayConfig) {
        config = newConfig
    }
    
    func clearCache() {
        responseCache.removeAll()
    }
    
    func getProviderStatus() -> [AIProvider: Bool] {
        // This could be enhanced to actually ping providers
        return [
            .openAI: true,
            .claude: true,
            .grok: true
        ]
    }
    
    // MARK: - Utility Methods
    
    func formatError(_ error: AIGatewayError) -> String {
        switch error {
        case .noValidProvider:
            return "No valid AI provider available."
        case .allProvidersFailed(let errors):
            let errorMessages = errors.map { $0.localizedDescription }.joined(separator: ", ")
            return "All AI providers failed: \(errorMessages)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .providerSpecificError(let message):
            return message
        }
    }
}