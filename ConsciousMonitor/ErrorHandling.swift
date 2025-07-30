import SwiftUI

// MARK: - Error Types

enum AppError: LocalizedError, Identifiable {
    case dataStorageError(String)
    case chromeIntegrationError(String)
    case openAIError(String)
    case permissionError(String)
    case networkError(String)
    case unknown(String)
    
    var id: String {
        switch self {
        case .dataStorageError(let message): return "dataStorage_\(message)"
        case .chromeIntegrationError(let message): return "chrome_\(message)"
        case .openAIError(let message): return "openAI_\(message)"
        case .permissionError(let message): return "permission_\(message)"
        case .networkError(let message): return "network_\(message)"
        case .unknown(let message): return "unknown_\(message)"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .dataStorageError(let message):
            return "Data Storage Error: \(message)"
        case .chromeIntegrationError(let message):
            return "Chrome Integration Error: \(message)"
        case .openAIError(let message):
            return "AI Service Error: \(message)"
        case .permissionError(let message):
            return "Permission Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .unknown(let message):
            return "Unknown Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataStorageError:
            return "Please try saving again or restart the application."
        case .chromeIntegrationError:
            return "Please check Chrome permissions in System Settings > Privacy & Security > Automation."
        case .openAIError:
            return "Please check your API key in Settings and try again."
        case .permissionError:
            return "Please grant the required permissions in System Settings."
        case .networkError:
            return "Please check your internet connection and try again."
        case .unknown:
            return "Please try again or restart the application."
        }
    }
    
    var systemImage: String {
        switch self {
        case .dataStorageError: return "externaldrive.badge.exclamationmark"
        case .chromeIntegrationError: return "globe.badge.chevron.backward"
        case .openAIError: return "brain.head.profile.badge.exclamationmark"
        case .permissionError: return "lock.shield"
        case .networkError: return "wifi.exclamationmark"
        case .unknown: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Error Alert View

struct ErrorAlertView: View {
    let error: AppError
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    
    @State private var showingDetails = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Error icon and title
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: error.systemImage)
                    .font(.system(size: 48))
                    .foregroundColor(DesignSystem.Colors.error)
                
                Text(error.errorDescription ?? "An error occurred")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Recovery suggestion
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }
            
            // Action buttons
            HStack(spacing: DesignSystem.Spacing.md) {
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                if let retry = onRetry {
                    Button("Retry") {
                        retry()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .cardStyle()
        .frame(maxWidth: 400)
    }
}

// MARK: - Loading State Views

struct LoadingStateView: View {
    let message: String
    let progress: Double?
    
    init(_ message: String, progress: Double? = nil) {
        self.message = message
        self.progress = progress
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            if let progress = progress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 200)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
            }
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .cardStyle()
        .frame(maxWidth: 300)
    }
}

// MARK: - Async Content View

/// Generic view for handling async content with loading, error, and success states
struct AsyncContentView<Content: View, LoadingContent: View, ErrorContent: View>: View {
    let content: Content
    let loadingContent: LoadingContent
    let errorContent: ErrorContent
    let state: AsyncState
    
    enum AsyncState {
        case loading
        case loaded
        case error(AppError)
    }
    
    init(
        state: AsyncState,
        @ViewBuilder content: () -> Content,
        @ViewBuilder loading: () -> LoadingContent = { LoadingView("Loading...") },
        @ViewBuilder error: @escaping (AppError) -> ErrorContent
    ) {
        self.state = state
        self.content = content()
        self.loadingContent = loading()
        self.errorContent = error(AppError.unknown(""))
    }
    
    var body: some View {
        switch state {
        case .loading:
            loadingContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            content
        case .error(let appError):
            // This will be replaced by the error content closure
            EmptyStateView(
                "Error",
                subtitle: appError.errorDescription,
                systemImage: appError.systemImage
            )
        }
    }
}

// MARK: - View Modifiers for Error Handling

extension View {
    /// Show an error alert with proper styling
    func errorAlert(
        error: Binding<AppError?>,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        self.alert(
            error.wrappedValue?.errorDescription ?? "Error",
            isPresented: .constant(error.wrappedValue != nil)
        ) {
            Button("OK", role: .cancel) {
                error.wrappedValue = nil
            }
            
            if let retry = onRetry {
                Button("Retry") {
                    retry()
                    error.wrappedValue = nil
                }
            }
        } message: {
            if let appError = error.wrappedValue {
                Text(appError.recoverySuggestion ?? "Please try again.")
            }
        }
    }
    
    /// Apply loading overlay
    func loadingOverlay(
        isLoading: Bool,
        message: String = "Loading..."
    ) -> some View {
        self.overlay {
            if isLoading {
                LoadingStateView(message)
                    .background(DesignSystem.Colors.primaryBackground.opacity(0.8))
                    .animation(.easeInOut(duration: 0.2), value: isLoading)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ErrorAlertView(
            error: .dataStorageError("Failed to save activity data"),
            onDismiss: {},
            onRetry: {}
        )
        
        LoadingStateView("Analyzing your productivity patterns...")
        
        LoadingStateView("Syncing data...", progress: 0.7)
    }
    .padding()
}