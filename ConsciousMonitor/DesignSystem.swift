import SwiftUI

// MARK: - Design System Foundation

/// Native macOS design system for FocusMonitor
/// Provides consistent theming, spacing, and components following macOS HIG
struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Primary content colors
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(NSColor.tertiaryLabelColor)
        
        // Background colors - Semantic usage defined
        static let primaryBackground = Color(NSColor.controlBackgroundColor)      // Main app background & page headers
        static let contentBackground = Color(NSColor.controlBackgroundColor)     // Main content areas (was secondaryBackground)
        static let cardBackground = Color(NSColor.controlBackgroundColor)        // Individual cards and components
        static let groupedBackground = Color(NSColor.controlBackgroundColor)     // Form sections and grouped content
        static let hoverBackground = Color(NSColor.quaternaryLabelColor).opacity(0.1)  // Hover states (was tertiaryBackground)
        
        // Accent and semantic colors
        static let accent = Color.accentColor
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        // Chart colors - using macOS system colors
        static let chartColors: [Color] = [
            Color.blue,
            Color.green,
            Color.orange,
            Color.red,
            Color.purple,
            Color.pink,
            Color.yellow,
            Color.cyan
        ]
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle
        static let title = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let headline = Font.headline
        static let subheadline = Font.subheadline
        static let body = Font.body
        static let callout = Font.callout
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        // Specialized fonts
        static let monospacedDigit = Font.body.monospacedDigit()
        static let monospacedBody = Font.system(.body, design: .monospaced)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 2
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        
        // Semantic spacing
        static let cardPadding: CGFloat = xl
        static let sectionSpacing: CGFloat = xxl
        static let itemSpacing: CGFloat = md
    }
    
    // MARK: - Layout
    struct Layout {
        static let cornerRadius: CGFloat = 8
        static let cardCornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 1
        
        // Window sizing
        static let minWindowWidth: CGFloat = 800
        static let minWindowHeight: CGFloat = 600
        static let idealWindowWidth: CGFloat = 1000
        static let idealWindowHeight: CGFloat = 700
        
        // Component sizing
        static let iconSize: CGFloat = 20
        static let smallIconSize: CGFloat = 16
        static let largeIconSize: CGFloat = 24
        static let tabBarHeight: CGFloat = 28
        
        // Page layout standards
        static let pageHeaderPadding: CGFloat = 40  // 40pt top padding for page headers
        static let contentPadding: CGFloat = 40     // 40pt for general content
        static let sectionSpacing: CGFloat = 32     // 32pt between major sections
        static let titleSpacing: CGFloat = 12       // 12pt below titles
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let card = Color.black.opacity(0.1)
        static let elevation1 = Color.black.opacity(0.05)
        static let elevation2 = Color.black.opacity(0.1)
    }
}

// MARK: - Reusable Components

/// Card container with native macOS styling
struct CardView<Content: View>: View {
    let content: Content
    let padding: CGFloat
    
    init(padding: CGFloat = DesignSystem.Spacing.cardPadding, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius))
            .shadow(color: DesignSystem.Shadows.card, radius: 2, y: 1)
    }
}

/// Section header with consistent styling
struct SectionHeaderView: View {
    let title: String
    let subtitle: String?
    
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Loading indicator with native macOS styling
struct LoadingView: View {
    let message: String?
    
    init(_ message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(0.8)
            
            if let message = message {
                Text(message)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.primaryBackground.opacity(0.8))
    }
}

/// Empty state view with native styling
struct EmptyStateView: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        _ title: String,
        subtitle: String? = nil,
        systemImage: String = "tray",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            
            if let action = action, let actionTitle = actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xxxl)
    }
}

/// Enhanced tooltip with native macOS styling
struct NativeTooltip: View {
    let text: String
    let isVisible: Bool
    
    var body: some View {
        if isVisible {
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                        .fill(DesignSystem.Colors.cardBackground)
                        .shadow(color: DesignSystem.Shadows.elevation2, radius: 4, y: 2)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}

// MARK: - View Modifiers

// MARK: - Settings UI Components

// Clean, simple settings components without complex auto-save feedback

extension View {
    /// Apply card-like styling to any view
    func cardStyle(padding: CGFloat = DesignSystem.Spacing.cardPadding) -> some View {
        self
            .padding(padding)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius))
            .shadow(color: DesignSystem.Shadows.card, radius: 2, y: 1)
    }
    
    /// Apply native macOS list row styling
    func listRowStyle() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
    
    /// Apply proper content margins
    func contentMargins() -> some View {
        self.padding(.horizontal, DesignSystem.Spacing.xl)
    }
}
