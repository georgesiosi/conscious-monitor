import SwiftUI

struct SettingsWithSaveView: View {
    @ObservedObject var userSettings = UserSettings.shared
    @State private var isApiKeyVisible: Bool = false
    
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
        VStack { 
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
                
                Section(header: Text("OpenAI API Key")) {
                    HStack {
                        if isApiKeyVisible {
                            TextField("Enter your OpenAI API Key", text: $userSettings.openAIAPIKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            SecureField("Enter your OpenAI API Key", text: $userSettings.openAIAPIKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        Button {
                            isApiKeyVisible.toggle()
                        } label: {
                            Image(systemName: isApiKeyVisible ? "eye.slash.fill" : "eye.fill")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.bottom)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your API key is stored locally and used to analyze your app usage for Workstyle DNA insights. Keep it secure.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text("Get your API key from:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Button("OpenAI Platform") {
                                if let url = URL(string: "https://platform.openai.com/account/api-keys") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.link)
                            .font(.caption)
                            Spacer()
                        }
                    }
                }
                
                Section(header: Text("About Me")) {
                    TextEditor(text: $userSettings.aboutMe)
                        .frame(minHeight: 80)
                        .border(Color.gray.opacity(0.2), width: 1)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text("Describe yourself, your role, or any relevant context you'd like the AI to consider.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Section(header: Text("My Goals")) {
                    TextEditor(text: $userSettings.userGoals)
                        .frame(minHeight: 80)
                        .border(Color.gray.opacity(0.2), width: 1)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text("What are your current professional or productivity goals? This can help tailor AI insights.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Settings are now auto-saved - no save button needed

                Section(header: Text("Focus Awareness")) {
                    AwarenessSettingsView()
                }

                Section(header: Text("Display")) {
                    Toggle("Show seconds in timestamps", isOn: $userSettings.showSecondsInTimestamps)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    Text("Enable to show seconds in timestamps for more precise tracking.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Floating Focus Panel Toggle - enhanced configuration system
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Show Floating Focus Bar", isOn: $userSettings.showFloatingFocusPanel)
                            .help("Display a floating bar with real-time focus information when the main app is not active")
                        
                        if userSettings.showFloatingFocusPanel {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("The floating bar shows your current app, focus state, and session metrics. It stays on top of other windows and provides Sunsama-style awareness.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 20)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    // Opacity control (0.3-1.0 range as specified)
                                    HStack {
                                        Text("Opacity:")
                                            .font(.caption)
                                        Slider(value: $userSettings.floatingBarOpacity, in: 0.3...1.0, step: 0.1)
                                            .frame(width: 120)
                                        Text("\(Int(userSettings.floatingBarOpacity * 100))%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 20)
                                    
                                    // Auto-hide behavior toggle
                                    Toggle("Auto-hide when main window is active", isOn: $userSettings.floatingBarAutoHide)
                                        .font(.caption)
                                        .padding(.leading, 20)
                                        .help("Automatically hide the floating bar when the main FocusMonitor window is active")
                                    
                                    // Keyboard shortcut info
                                    HStack {
                                        Text("Keyboard shortcut:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("⌘⇧F")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.leading, 20)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Category Management")) {
                    CategoryManagementView()
                }
                
                Section(header: Text("Data Management")) {
                    DataManagementView()
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
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(DesignSystem.Layout.contentPadding)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.Layout.cardCornerRadius)
            .padding(DesignSystem.Layout.contentPadding)
        }
        // Settings are now directly bound and auto-save
        .navigationTitle("Settings")
    }
    
    // No manual save/load methods needed - settings auto-save on change
}

#Preview {
    SettingsWithSaveView()
        .frame(width: 600, height: 800)
}