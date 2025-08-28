import SwiftUI

// MARK: - Settings Navigation Structure

enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "general"
    case account = "account"  
    case aiAnalysis = "ai_analysis"
    case awareness = "awareness"
    case dataManagement = "data_management"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .general:
            return "General"
        case .account:
            return "Account"
        case .aiAnalysis:
            return "AI & Analysis"
        case .awareness:
            return "Focus Awareness"
        case .dataManagement:
            return "Data Management"
        }
    }
    
    var icon: String {
        switch self {
        case .general:
            return "gear"
        case .account:
            return "person.circle"
        case .aiAnalysis:
            return "brain.head.profile"
        case .awareness:
            return "bell.circle"
        case .dataManagement:
            return "folder.circle"
        }
    }
}

// MARK: - Main Settings View with Sidebar

struct SidebarSettingsView: View {
    @State private var selectedSection: SettingsSection = .general
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    Label(section.title, systemImage: section.icon)
                        .padding(.vertical, 2)
                }
            }
            .navigationTitle("Settings")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
        } detail: {
            // Detail view based on selection
            Group {
                switch selectedSection {
                case .general:
                    GeneralSettingsView()
                case .account:
                    AccountSettingsView()
                case .aiAnalysis:
                    AIAnalysisSettingsView()
                case .awareness:
                    AwarenessSettingsView()
                case .dataManagement:
                    DataManagementView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle(selectedSection.title)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @ObservedObject var userSettings = UserSettings.shared
    
    var body: some View {
        Form {
            Section(header: Text("Category Management")) {
                CategoryManagementView()
            }
            
            Section(header: Text("Display")) {
                Toggle("Show seconds in timestamps", isOn: $userSettings.showSecondsInTimestamps)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                Text("Enable to show seconds in timestamps for more precise tracking.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("About")) {
                VStack(alignment: .leading, spacing: 12) {
                    // App Version
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                    
                    // App Description
                    Text("ConsciousMonitor helps you understand your productivity patterns and build awareness around your technology usage.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // Copyright
                    HStack {
                        Text("Copyright")
                        Spacer()
                        Text("© 2025 Faiā")
                            .foregroundColor(.secondary)
                    }
                    
                    // License Information
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("License")
                            Spacer()
                            Text("Dual License")
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("✅")
                                    .font(.caption)
                                Text("Free for personal & internal use")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            
                            HStack {
                                Text("💼")
                                    .font(.caption)
                                Text("Commercial license required for revenue use")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .padding(.leading, 8)
                        
                        // License Link Button
                        HStack {
                            Spacer()
                            Button("View Full License Terms") {
                                if let url = URL(string: "https://github.com/georgesiosi/conscious-monitor/blob/main/LICENSE.md") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.link)
                            .font(.caption)
                        }
                    }
                    
                    Divider()
                    
                    // Commercial Licensing Contact
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Commercial Licensing")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text("For commercial use, white-labeling, or revenue-generating applications:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Contact:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button("george@faiacorp.com") {
                                if let url = URL(string: "mailto:george@faiacorp.com?subject=ConsciousMonitor Commercial License") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.link)
                            .font(.caption)
                            Spacer()
                        }
                    }
                    
                    Divider()
                    
                    // CSD Link
                    Link("Learn more about CSD", destination: URL(string: "https://consciousstack.com")!)
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Account Settings

struct AccountSettingsView: View {
    @ObservedObject var userSettings = UserSettings.shared
    
    var body: some View {
        Form {
            Section(header: Text("About Me")) {
                TextEditor(text: $userSettings.aboutMe)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                Text("Describe yourself, your role, or any relevant context you'd like the AI to consider.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Section(header: Text("My Goals")) {
                TextEditor(text: $userSettings.userGoals)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                Text("What are your current professional or productivity goals? This can help tailor AI insights.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Settings auto-save - no save button needed
        }
        .formStyle(.grouped)
        .padding()
        // Settings are now directly bound and auto-save
    }
    
    // No manual save/load methods needed - settings auto-save on change
}

// MARK: - AI & Analysis Settings

struct AIAnalysisSettingsView: View {
    @ObservedObject var userSettings = UserSettings.shared
    @State private var isOpenAIKeyVisible: Bool = false
    @State private var isClaudeKeyVisible: Bool = false
    @State private var isGrokKeyVisible: Bool = false
    
    // Formatter for the hourly rate TextField
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter
    }
    
    var body: some View {
        Form {
            Section(header: Text("Financial Settings")) {
                HStack {
                    Text("Hourly Rate:")
                    TextField("Enter rate", value: $userSettings.hourlyRate, formatter: currencyFormatter)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 120)
                        .multilineTextAlignment(.trailing)
                }
                Text("Enter your approximate hourly rate to estimate the cost of context switching.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("AI Provider Configuration")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Primary Provider:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Primary AI Provider", selection: $userSettings.primaryAIProvider) {
                        ForEach(AIProvider.allCases) { provider in
                            HStack {
                                Image(systemName: provider.icon)
                                Text(provider.displayName)
                            }
                            .tag(provider)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Text("Fallback Provider:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top, 8)
                    
                    Picker("Fallback AI Provider", selection: $userSettings.fallbackAIProvider) {
                        Text("None").tag(nil as AIProvider?)
                        ForEach(AIProvider.allCases) { provider in
                            HStack {
                                Image(systemName: provider.icon)
                                Text(provider.displayName)
                            }
                            .tag(provider as AIProvider?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Toggle("Enable Response Caching", isOn: $userSettings.enableAIGatewayCache)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    Text("Caching can reduce API costs and improve response times for similar queries.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("OpenAI API Key")) {
                HStack {
                    if isOpenAIKeyVisible {
                        TextField("Enter your OpenAI API Key", text: $userSettings.openAIAPIKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        SecureField("Enter your OpenAI API Key", text: $userSettings.openAIAPIKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    Button {
                        isOpenAIKeyVisible.toggle()
                    } label: {
                        Image(systemName: isOpenAIKeyVisible ? "eye.slash.fill" : "eye.fill")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Text("Get your API key from platform.openai.com")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("Claude API Key")) {
                HStack {
                    if isClaudeKeyVisible {
                        TextField("Enter your Claude API Key", text: $userSettings.claudeAPIKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        SecureField("Enter your Claude API Key", text: $userSettings.claudeAPIKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    Button {
                        isClaudeKeyVisible.toggle()
                    } label: {
                        Image(systemName: isClaudeKeyVisible ? "eye.slash.fill" : "eye.fill")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Text("Get your API key from console.anthropic.com")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("Grok API Key")) {
                HStack {
                    if isGrokKeyVisible {
                        TextField("Enter your Grok API Key", text: $userSettings.grokAPIKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        SecureField("Enter your Grok API Key", text: $userSettings.grokAPIKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    Button {
                        isGrokKeyVisible.toggle()
                    } label: {
                        Image(systemName: isGrokKeyVisible ? "eye.slash.fill" : "eye.fill")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Text("Get your API key from x.ai")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("Privacy & Security")) {
                Text("All API keys are stored locally on your device and are never transmitted to ConsciousMonitor servers. They are used only to communicate directly with your chosen AI providers.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Settings auto-save - no save button needed
        }
        .formStyle(.grouped)
        .padding()
        // Settings are now directly bound and auto-save
    }
    
    // No manual save/load methods needed - settings auto-save on change
}


#Preview {
    SidebarSettingsView()
        .frame(width: 800, height: 600)
}