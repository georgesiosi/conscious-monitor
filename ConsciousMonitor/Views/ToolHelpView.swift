import SwiftUI
import MarkdownUI

struct ToolHelpView: View {
    @ObservedObject var activityMonitor: ActivityMonitor
    @ObservedObject var userSettings = UserSettings.shared
    let openAIService: OpenAIService
    @StateObject private var aiGateway = AIGatewayService()
    
    @State private var selectedTool: String = ""
    @State private var questionText: String = ""
    @State private var isLoading: Bool = false
    @State private var helpResponse: String = ""
    @State private var errorMessage: String? = nil
    
    private var frequentlyUsedApps: [AppUsageStat] {
        activityMonitor.appUsageStats
            .filter { $0.activationCount > 5 } // Only apps used more than 5 times
            .sorted { $0.activationCount > $1.activationCount }
            .prefix(10) // Top 10 most used apps
            .compactMap { $0 }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.xl) {
                // Tool selection card
                AnalyticsCard(title: "Select Your Tool", icon: "apps.iphone") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        Text("Choose from your frequently used applications to get contextual help and tips.")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        if frequentlyUsedApps.isEmpty {
                            Text("No frequently used apps found. Use your Mac for a while to see your tools here.")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                                .padding(DesignSystem.Spacing.lg)
                                .background(DesignSystem.Colors.hoverBackground)
                                .cornerRadius(DesignSystem.Layout.cornerRadius)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 120), spacing: DesignSystem.Spacing.sm)
                            ], spacing: DesignSystem.Spacing.sm) {
                                ForEach(frequentlyUsedApps, id: \.appName) { app in
                                    ToolSelectionCard(
                                        app: app,
                                        isSelected: selectedTool == app.appName
                                    ) {
                                        selectedTool = app.appName
                                        // Clear previous response when tool changes
                                        helpResponse = ""
                                        errorMessage = nil
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Question input card
                if !selectedTool.isEmpty {
                    AnalyticsCard(title: "Ask About \(selectedTool)", icon: "questionmark.bubble") {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                            Text("What would you like to know about \(selectedTool)? Ask specific questions about features, workflows, or tips.")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Your Question:")
                                    .font(DesignSystem.Typography.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                TextEditor(text: $questionText)
                                    .frame(minHeight: 80)
                                    .padding(DesignSystem.Spacing.sm)
                                    .background(DesignSystem.Colors.contentBackground)
                                    .cornerRadius(DesignSystem.Layout.cornerRadius)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                                            .stroke(DesignSystem.Colors.tertiaryText.opacity(0.3), lineWidth: 1)
                                    )
                                
                                if questionText.isEmpty {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                        Text("Example questions:")
                                            .font(DesignSystem.Typography.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            exampleQuestion(for: selectedTool)
                                        }
                                    }
                                }
                            }
                            
                            HStack {
                                Spacer()
                                Button(action: {
                                    Task { await getToolHelp() }
                                }) {
                                    HStack(spacing: DesignSystem.Spacing.sm) {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 16))
                                        }
                                        
                                        Text(isLoading ? "Getting Help..." : "Get Help")
                                            .font(DesignSystem.Typography.body)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, DesignSystem.Spacing.xl)
                                    .padding(.vertical, DesignSystem.Spacing.md)
                                    .background(questionText.isEmpty || isLoading ? DesignSystem.Colors.tertiaryText : DesignSystem.Colors.accent)
                                    .cornerRadius(DesignSystem.Layout.cornerRadius)
                                }
                                .disabled(questionText.isEmpty || isLoading)
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // Response card
                if isLoading {
                    AnalyticsCard(title: "Getting Help", icon: "brain") {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.2)
                            
                            Text("AI is researching \(selectedTool) to answer your question...")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(minHeight: 100)
                    }
                } else if let error = errorMessage {
                    AnalyticsCard(title: "Error", icon: "exclamationmark.triangle") {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text(error)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.error)
                            
                            Text("Please try again. If the problem persists, check your API key and internet connection.")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                } else if !helpResponse.isEmpty {
                    AnalyticsCard(title: "Help for \(selectedTool)", icon: "lightbulb") {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Markdown(helpResponse)
                                .markdownTextStyle(\.text) {
                                    ForegroundColor(DesignSystem.Colors.primaryText)
                                }
                                .markdownTextStyle(\.strong) {
                                    ForegroundColor(DesignSystem.Colors.primaryText)
                                    FontWeight(.semibold)
                                }
                                .markdownTextStyle(\.emphasis) {
                                    ForegroundColor(DesignSystem.Colors.primaryText)
                                    FontStyle(.italic)
                                }
                                .markdownTextStyle(\.code) {
                                    ForegroundColor(DesignSystem.Colors.primaryText)
                                    BackgroundColor(DesignSystem.Colors.hoverBackground)
                                }
                                .markdownBlockStyle(\.codeBlock) { configuration in
                                    configuration.label
                                        .padding(DesignSystem.Spacing.sm)
                                        .background(DesignSystem.Colors.hoverBackground)
                                        .cornerRadius(DesignSystem.Layout.cornerRadius)
                                }
                                .textSelection(.enabled)
                                .padding(DesignSystem.Spacing.md)
                                .background(DesignSystem.Colors.contentBackground)
                                .cornerRadius(DesignSystem.Layout.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                                        .stroke(DesignSystem.Colors.tertiaryText.opacity(0.2), lineWidth: 1)
                                )
                            
                            Text("💡 This help is based on current knowledge about \(selectedTool) and your usage patterns.")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                                .padding(.top, DesignSystem.Spacing.sm)
                        }
                    }
                }
            }
            .padding(DesignSystem.Layout.contentPadding)
        }
    }
    
    @ViewBuilder
    private func exampleQuestion(for tool: String) -> some View {
        let examples = getExampleQuestions(for: tool)
        ForEach(examples.indices, id: \.self) { index in
            Button(action: {
                questionText = examples[index]
            }) {
                Text("• \(examples[index])")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.accent)
                    .multilineTextAlignment(.leading)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func getExampleQuestions(for tool: String) -> [String] {
        let lowercaseTool = tool.lowercased()
        
        if lowercaseTool.contains("notion") {
            return [
                "How do I create recurring tasks in Notion?",
                "What's the best way to organize projects in Notion?",
                "How can I use Notion templates effectively?"
            ]
        } else if lowercaseTool.contains("chrome") || lowercaseTool.contains("safari") {
            return [
                "How can I manage my tabs more efficiently?",
                "What keyboard shortcuts can improve my browsing?",
                "How do I organize bookmarks for better productivity?"
            ]
        } else if lowercaseTool.contains("slack") {
            return [
                "How can I reduce Slack distractions while staying connected?",
                "What are the best practices for Slack channel organization?",
                "How do I use Slack shortcuts to save time?"
            ]
        } else if lowercaseTool.contains("xcode") {
            return [
                "What are the most useful Xcode shortcuts for faster development?",
                "How can I optimize my Xcode workflow?",
                "What debugging techniques work best in Xcode?"
            ]
        } else if lowercaseTool.contains("figma") {
            return [
                "How can I speed up my design workflow in Figma?",
                "What are the best collaboration features in Figma?",
                "How do I organize components efficiently in Figma?"
            ]
        } else {
            return [
                "What are the key features I should be using in \(tool)?",
                "How can I be more productive with \(tool)?",
                "What shortcuts or tips can save me time in \(tool)?"
            ]
        }
    }
    
    private func getToolHelp() async {
        guard !questionText.isEmpty && !selectedTool.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        helpResponse = ""
        
        let usageContext = generateUsageContext(for: selectedTool)
        
        let systemPrompt = """
        You are a helpful assistant specialized in providing practical, actionable advice about software tools and applications. 
        Your responses should be:
        - Specific and actionable
        - Based on current features and capabilities
        - Focused on productivity and efficiency
        - Include step-by-step instructions when relevant
        - Mention keyboard shortcuts and advanced features when applicable
        
        Format your responses in clear markdown with headings, lists, and code blocks where appropriate.
        """
        
        let userPrompt = """
        I'm asking about \(selectedTool). Here's my usage context:
        \(usageContext)
        
        My question: \(questionText)
        
        Please provide a comprehensive answer with practical steps, tips, and any relevant shortcuts or advanced features.
        """
        
        let messages = [
            AIMessage(role: "system", content: systemPrompt),
            AIMessage(role: "user", content: userPrompt)
        ]
        
        // Configure AI Gateway with user settings
        aiGateway.config.primaryProvider = userSettings.primaryAIProvider
        aiGateway.config.fallbackProvider = userSettings.fallbackAIProvider
        aiGateway.config.enableCaching = userSettings.enableAIGatewayCache
        
        let result = await aiGateway.sendMessage(
            messages: messages,
            apiKeys: userSettings.getAIProviderKeys(),
            useCase: "tool_help"
        )
        
        switch result {
        case .success(let response):
            helpResponse = response
        case .failure(let error):
            errorMessage = aiGateway.formatError(error)
        }
        
        isLoading = false
    }
    
    private func generateUsageContext(for tool: String) -> String {
        guard let appStat = activityMonitor.appUsageStats.first(where: { $0.appName == tool }) else {
            return "I use \(tool) occasionally."
        }
        
        let category = appStat.category.name
        let activationCount = appStat.activationCount
        
        var context = "I'm a frequent user of \(tool) (activated \(activationCount) times recently). "
        context += "I primarily use it for \(category.lowercased()) tasks. "
        
        // Add role context if available
        if !userSettings.aboutMe.isEmpty {
            context += "My role/context: \(userSettings.aboutMe). "
        }
        
        // Add goals context if available
        if !userSettings.userGoals.isEmpty {
            context += "My current goals: \(userSettings.userGoals). "
        }
        
        return context
    }
    
    private func formatError(_ error: OpenAIService.OpenAIServiceError) -> String {
        switch error {
        case .apiError(let message):
            return "API Error: \(message)"
        case .decodingError(let underlyingError):
            return "Failed to decode response: \(underlyingError.localizedDescription)"
        case .noData:
            return "No data received from the server."
        case .noChoices:
            return "No response choices returned."
        case .noMessageContent:
            return "No message content found in the response."
        case .requestFailed(let underlyingError):
            return "Network request failed: \(underlyingError.localizedDescription)"
        case .invalidURL:
            return "Invalid URL configuration."
        }
    }
}

// MARK: - Tool Selection Card

struct ToolSelectionCard: View {
    let app: AppUsageStat
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                // App icon
                if let nsIcon = app.appIcon {
                    Image(nsImage: nsIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                
                VStack(spacing: 2) {
                    Text(app.appName)
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? DesignSystem.Colors.primaryText : DesignSystem.Colors.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text("\(app.activationCount) uses")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
            .frame(width: 120, height: 80)
            .padding(DesignSystem.Spacing.sm)
            .background(backgroundColor)
            .cornerRadius(DesignSystem.Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return DesignSystem.Colors.accent.opacity(0.1)
        } else if isHovered {
            return DesignSystem.Colors.hoverBackground
        } else {
            return DesignSystem.Colors.cardBackground
        }
    }
    
    private var borderColor: Color {
        isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.tertiaryText.opacity(0.2)
    }
}

#Preview {
    ToolHelpView(activityMonitor: ActivityMonitor(), openAIService: OpenAIService())
}