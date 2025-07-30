import Foundation

// MARK: - OpenAI Request Structures
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    // Add other parameters like temperature, max_tokens if needed
}

struct OpenAIMessage: Codable {
    let role: String // "system", "user", or "assistant"
    let content: String
}

// MARK: - OpenAI Response Structures
struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]?
    let error: OpenAIError?
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage?
}

struct OpenAIError: Codable {
    let message: String
    let type: String?
    // code, param can also be included if needed
}


// MARK: - OpenAI Service
class OpenAIService {

    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    enum OpenAIServiceError: Error {
        case invalidURL
        case requestFailed(Error)
        case noData
        case decodingError(Error)
        case apiError(String)
        case noChoices
        case noMessageContent
    }
    
    // MARK: - Chat Conversation Support
    
    /// Send a chat message with conversation context
    func sendChatMessage(
        apiKey: String,
        messages: [OpenAIMessage],
        useCSDAgent: Bool = false,
        model: String = "gpt-4o"
    ) async -> Result<String, OpenAIServiceError> {
        guard !apiKey.isEmpty else {
            return .failure(.apiError("API Key is missing."))
        }
        
        // Use different endpoint or model for CSD agents if needed
        let requestModel = useCSDAgent ? "gpt-4o" : model // You can customize this for your CSD agents
        
        let requestBody = OpenAIRequest(
            model: requestModel,
            messages: messages
        )
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            return .failure(.decodingError(error))
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.requestFailed(URLError(.badServerResponse)))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let decodedError = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
                   let apiErrorMessage = decodedError.error?.message {
                    return .failure(.apiError("API Error (\(httpResponse.statusCode)): \(apiErrorMessage)"))
                }
                return .failure(.apiError("API Error: HTTP \(httpResponse.statusCode)"))
            }
            
            let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            guard let choice = decodedResponse.choices?.first else {
                return .failure(.noChoices)
            }
            guard let messageContent = choice.message?.content else {
                return .failure(.noMessageContent)
            }
            return .success(messageContent.trimmingCharacters(in: .whitespacesAndNewlines))
            
        } catch let error as OpenAIServiceError {
            return .failure(error)
        } catch {
            return .failure(.requestFailed(error))
        }
    }
    
    /// Convert ChatMessage array to OpenAIMessage array
    static func convertChatMessages(_ chatMessages: [ChatMessage]) -> [OpenAIMessage] {
        return chatMessages.map { message in
            OpenAIMessage(role: message.role, content: message.content)
        }
    }

    func analyzeUsage(apiKey: String, appUsageStats: [AppUsageStat]) async -> Result<String, OpenAIServiceError> {
        guard !apiKey.isEmpty else {
            return .failure(.apiError("API Key is missing."))
        }

        // 1. Format the app usage data for the prompt
        let appListString = appUsageStats.map { "\($0.appName) (Switches: \($0.activationCount))" }.joined(separator: ", ")
        if appListString.isEmpty {
            return .success("No application usage data to analyze.")
        }

        // Access UserSettings for additional context
        let userSettings = UserSettings.shared
        let aboutMeContext = userSettings.aboutMe
        let userGoalsContext = userSettings.userGoals

        // 2. Construct the prompt
        let systemPrompt = """
            You are a brutally honest, culturally intelligent analysis assistant based on the Conscious Stack Design (CSD) framework. Your mission is to help users align their personal or team tool stacks with cultural fit, operational goals, and behavioral outcomes. You analyze stacks by:
            - Categorizing tools by function and cultural energy (Innovation & Creativity (CC), Communication & Collaboration (CC), Stability & Support (SS), Structure & Discipline (SD), Agility & Flexibility (AF)).
            - Identifying overused, underused, or misaligned tools.
            - Surfacing cultural tensions or drift.
            - Recommending clear, actionable optimization steps.
            You must deliver insights in detailed, structured sections with no fluff. Be blunt. Prioritize actionable alignment over feel-good commentary.
            Learn more about CSD at https://consciousstack.com and the future CSTACK platform at https://cstack.ai.
        """
        
        var userPromptString = """
        Here is my application usage data (app name and switch count today):
        \(appListString)
        """

        if !aboutMeContext.isEmpty {
            userPromptString += "\n\nAbout Me:\n\(aboutMeContext)"
        }

        if !userGoalsContext.isEmpty {
            userPromptString += "\n\nMy Current Goals:\n\(userGoalsContext)"
        }

        userPromptString += "\n\nBased on all the information provided (my app usage, about me, and my goals), what are some key insights into my workstyle and potential work culture reflections, following the Conscious Stack Design (CSD) framework you embody?"

        // 3. Create request body
        let requestBody = OpenAIRequest(
            model: "gpt-4o", // Or "gpt-4" if preferred and available
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: userPromptString) // Use the constructed string
            ]
        )

        // 4. Create URLRequest
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            return .failure(.decodingError(error)) // Technically encoding error here
        }

        // 5. Perform the API call
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.requestFailed(URLError(.badServerResponse)))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to decode error message from OpenAI
                if let decodedError = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
                   let apiErrorMessage = decodedError.error?.message {
                    return .failure(.apiError("API Error (\(httpResponse.statusCode)): \(apiErrorMessage)"))
                }
                return .failure(.apiError("API Error: HTTP \(httpResponse.statusCode)"))
            }

            let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

            guard let choice = decodedResponse.choices?.first else {
                return .failure(.noChoices)
            }
            guard let messageContent = choice.message?.content else {
                return .failure(.noMessageContent)
            }
            return .success(messageContent.trimmingCharacters(in: .whitespacesAndNewlines))

        } catch let error as OpenAIServiceError {
            return .failure(error)
        } catch {
            return .failure(.requestFailed(error))
        }
    }
}
