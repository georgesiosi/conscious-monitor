import SwiftUI
import MarkdownUI

struct ChatInterface: View {
    @ObservedObject var chatManager: ChatManager
    @ObservedObject var userSettings = UserSettings.shared
    
    @State private var messageInput: String = ""
    @State private var showingModeSelector: Bool = false
    @State private var isInputFocused: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header with mode selector
            chatHeader
            
            Divider()
            
            // Messages area
            if let session = chatManager.currentSession, !session.messages.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            ForEach(session.messages) { message in
                                if message.role != "system" {
                                    ChatMessageView(message: message)
                                        .id(message.id)
                                }
                            }
                            
                            // Loading indicator
                            if chatManager.isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Thinking...")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                .padding(.vertical, DesignSystem.Spacing.sm)
                            }
                        }
                        .padding(DesignSystem.Spacing.lg)
                    }
                    .onChange(of: session.messages.count) {
                        // Auto-scroll to latest message
                        if let lastMessage = session.messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: chatManager.isLoading) {
                        // Scroll when loading state changes
                        if let lastMessage = session.messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            } else {
                // Empty state
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("Start a conversation about your analysis")
                            .font(DesignSystem.Typography.headline)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("Ask questions about your productivity patterns, workflow optimization, or CSD framework insights.")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Suggested questions
                    suggestedQuestionsView
                }
                .padding(DesignSystem.Spacing.xl)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Error message
            if let error = chatManager.errorMessage {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignSystem.Colors.error)
                    Text(error)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.error)
                    Spacer()
                    Button("Dismiss") {
                        chatManager.errorMessage = nil
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.accent)
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.error.opacity(0.1))
                .cornerRadius(DesignSystem.Layout.cornerRadius)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.sm)
            }
            
            Divider()
            
            // Input area
            chatInputArea
        }
    }
    
    // MARK: - Chat Header
    
    private var chatHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("AI Chat")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: chatManager.chatMode.icon)
                        .font(.system(size: 12))
                        .foregroundColor(getModeColor())
                    
                    Text(chatManager.chatMode.displayName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            // Mode selector button
            if userSettings.enableCSDCoaching && !userSettings.csdAgentKey.isEmpty {
                Button(action: { showingModeSelector.toggle() }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Mode")
                            .font(DesignSystem.Typography.caption)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(DesignSystem.Colors.accent)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingModeSelector) {
                    chatModeSelector
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
    }
    
    // MARK: - Chat Mode Selector
    
    private var chatModeSelector: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Chat Mode")
                .font(DesignSystem.Typography.headline)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            ForEach(ChatMode.allCases, id: \.self) { mode in
                Button(action: {
                    chatManager.updateChatMode(mode)
                    showingModeSelector = false
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14))
                            .foregroundColor(chatManager.chatMode == mode ? DesignSystem.Colors.accent : DesignSystem.Colors.tertiaryText)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.displayName)
                                .font(DesignSystem.Typography.body)
                                .fontWeight(chatManager.chatMode == mode ? .medium : .regular)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text(mode.description)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        if chatManager.chatMode == mode {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(chatManager.chatMode == mode ? DesignSystem.Colors.accent.opacity(0.1) : Color.clear)
                    .cornerRadius(DesignSystem.Layout.cornerRadius)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(width: 300)
    }
    
    // MARK: - Suggested Questions
    
    private var suggestedQuestionsView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Suggested questions:")
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.sm) {
                ForEach(getSuggestedQuestions(), id: \.self) { question in
                    Button(action: {
                        messageInput = question
                        isInputFocused = true
                    }) {
                        Text(question)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.accent)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.accent.opacity(0.1))
                            .cornerRadius(DesignSystem.Layout.cornerRadius)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Chat Input Area
    
    private var chatInputArea: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            TextField("Ask about your analysis, productivity patterns, or workflow optimization...", text: $messageInput, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .font(DesignSystem.Typography.body)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                   DesignSystem.Colors.tertiaryText : DesignSystem.Colors.accent)
            }
            .buttonStyle(.plain)
            .disabled(messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatManager.isLoading)
        }
        .padding(DesignSystem.Spacing.lg)
    }
    
    // MARK: - Helper Methods
    
    private func sendMessage() {
        let trimmedInput = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        messageInput = ""
        
        Task {
            await chatManager.sendMessage(trimmedInput)
        }
    }
    
    private func getModeColor() -> Color {
        switch chatManager.chatMode {
        case .auto: return DesignSystem.Colors.accent
        case .generalAI: return DesignSystem.Colors.primaryText
        case .csdCoach: return DesignSystem.Colors.success
        }
    }
    
    private func getSuggestedQuestions() -> [String] {
        return [
            "How can I improve my productivity?",
            "What's causing my context switching?",
            "Help me consolidate my tools",
            "Explain my CSD compliance",
            "Which apps should I focus on?",
            "How to reduce cognitive load?"
        ]
    }
}

// MARK: - Chat Message View

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            // Avatar
            Circle()
                .fill(message.role == "user" ? DesignSystem.Colors.accent : 
                     (message.isFromCSDAgent ? DesignSystem.Colors.success : DesignSystem.Colors.secondaryText))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: message.role == "user" ? "person.fill" : 
                         (message.isFromCSDAgent ? "target" : "brain.head.profile"))
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // Header with name and timestamp
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(message.role == "user" ? "You" : 
                         (message.isFromCSDAgent ? "CSD Coach" : "AI Assistant"))
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    Spacer()
                }
                
                // Message content
                if message.role == "user" {
                    Text(message.content)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .textSelection(.enabled)
                } else {
                    Markdown(message.content)
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
                        .font(DesignSystem.Typography.body)
                        .textSelection(.enabled)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

#Preview {
    ChatInterface(chatManager: ChatManager())
        .frame(width: 500, height: 400)
}
