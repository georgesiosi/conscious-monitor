import SwiftUI

// MARK: - Accessibility Enhancements

/// Accessibility utilities and enhancements for FocusMonitor
struct AccessibilityUtils {
    
    // MARK: - Semantic Labels
    
    static func switchCountLabel(_ count: Int) -> String {
        if count == 0 {
            return "No application switches"
        } else if count == 1 {
            return "1 application switch"
        } else {
            return "\(count) application switches"
        }
    }
    
    static func timeLabel(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "at \(formatter.string(from: date))"
    }
    
    static func categoryLabel(for category: AppCategory) -> String {
        return "Category: \(category.name)"
    }
    
    static func percentageLabel(_ value: Double, total: Double) -> String {
        let percentage = (value / total) * 100
        return String(format: "%.0f percent", percentage)
    }
    
    // MARK: - Chart Accessibility
    
    static func chartDataDescription<T>(
        data: [(value: T, label: String)],
        title: String
    ) -> String where T: Numeric {
        let totalItems = data.count
        let description = data.enumerated().map { index, item in
            "\(item.label): \(item.value)" + (index < totalItems - 1 ? ", " : "")
        }.joined()
        
        return "\(title). \(totalItems) items. \(description)"
    }
}

// MARK: - Accessible Chart View

struct AccessiblePieChartView: View {
    let data: [(value: Double, color: Color, label: String)]
    let title: String
    
    private var totalValue: Double {
        data.reduce(0) { $0 + $1.value }
    }
    
    private var accessibilityDescription: String {
        let itemDescriptions = data.map { item in
            let percentage = (item.value / totalValue) * 100
            return "\(item.label): \(Int(item.value)) switches, \(String(format: "%.0f", percentage)) percent"
        }
        return "\(title). Total: \(Int(totalValue)) switches. " + itemDescriptions.joined(separator: ". ")
    }
    
    var body: some View {
        PieChartView(data: data, title: title)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(accessibilityDescription)
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Accessible Event Row

struct AccessibleEventRow: View {
    let event: AppActivationEvent
    let onTap: () -> Void
    
    @ObservedObject private var userSettings = UserSettings.shared
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = userSettings.showSecondsInTimestamps ? "h:mm:ss a" : "h:mm a"
        return formatter
    }
    
    private var accessibilityLabel: String {
        let appName = event.appName ?? "Unknown App"
        let category = AccessibilityUtils.categoryLabel(for: event.category)
        
        var label = "\(appName), \(category), \(AccessibilityUtils.timeLabel(from: event.timestamp))"
        
        if let tabTitle = event.chromeTabTitle {
            label += ", Tab: \(tabTitle)"
        }
        
        return label
    }
    
    var body: some View {
        EventRow(event: event)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Double tap to edit category")
    }
}

// MARK: - Accessible Stat Card

struct AccessibleStatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    let accessibilityHint: String?
    
    init(
        title: String,
        value: String,
        systemImage: String,
        color: Color,
        accessibilityHint: String? = nil
    ) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.color = color
        self.accessibilityHint = accessibilityHint
    }
    
    var body: some View {
        StatCard(title: title, value: value, systemImage: systemImage, color: color)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title): \(value)")
            .accessibilityAddTraits(.isStaticText)
            .accessibilityHint(accessibilityHint ?? "")
    }
}

// MARK: - Accessible Tab View

struct AccessibleTabItem: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Activate to view \(title.lowercased())")
    }
}

// MARK: - Keyboard Navigation Support

struct KeyboardNavigationModifier: ViewModifier {
    let onUpArrow: (() -> Void)?
    let onDownArrow: (() -> Void)?
    let onLeftArrow: (() -> Void)?
    let onRightArrow: (() -> Void)?
    let onEnter: (() -> Void)?
    let onEscape: (() -> Void)?
    
    init(
        onUpArrow: (() -> Void)? = nil,
        onDownArrow: (() -> Void)? = nil,
        onLeftArrow: (() -> Void)? = nil,
        onRightArrow: (() -> Void)? = nil,
        onEnter: (() -> Void)? = nil,
        onEscape: (() -> Void)? = nil
    ) {
        self.onUpArrow = onUpArrow
        self.onDownArrow = onDownArrow
        self.onLeftArrow = onLeftArrow
        self.onRightArrow = onRightArrow
        self.onEnter = onEnter
        self.onEscape = onEscape
    }
    
    func body(content: Content) -> some View {
        content
            .onKeyPress(.upArrow) {
                onUpArrow?()
                return .handled
            }
            .onKeyPress(.downArrow) {
                onDownArrow?()
                return .handled
            }
            .onKeyPress(.leftArrow) {
                onLeftArrow?()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                onRightArrow?()
                return .handled
            }
            .onKeyPress(.return) {
                onEnter?()
                return .handled
            }
            .onKeyPress(.escape) {
                onEscape?()
                return .handled
            }
    }
}

// MARK: - View Extensions for Accessibility

extension View {
    /// Add keyboard navigation support
    func keyboardNavigation(
        onUpArrow: (() -> Void)? = nil,
        onDownArrow: (() -> Void)? = nil,
        onLeftArrow: (() -> Void)? = nil,
        onRightArrow: (() -> Void)? = nil,
        onEnter: (() -> Void)? = nil,
        onEscape: (() -> Void)? = nil
    ) -> some View {
        self.modifier(KeyboardNavigationModifier(
            onUpArrow: onUpArrow,
            onDownArrow: onDownArrow,
            onLeftArrow: onLeftArrow,
            onRightArrow: onRightArrow,
            onEnter: onEnter,
            onEscape: onEscape
        ))
    }
    
    /// Enhanced accessibility for interactive elements
    func enhancedAccessibility(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Make view focusable with proper accessibility
    func accessibleFocus() -> some View {
        self
            .focusable()
            .accessibilityAddTraits(.allowsDirectInteraction)
    }
}

// MARK: - Reduced Motion Support

struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    let animation: Animation
    let fallbackAnimation: Animation?
    
    init(animation: Animation, fallback: Animation? = nil) {
        self.animation = animation
        self.fallbackAnimation = fallback
    }
    
    func body(content: Content) -> some View {
        content
            .animation(
                reduceMotion ? (fallbackAnimation ?? .none) : animation,
                value: UUID() // This should be replaced with actual value in usage
            )
    }
}

extension View {
    /// Respect user's reduce motion preference
    func respectReducedMotion(
        animation: Animation,
        fallback: Animation? = nil
    ) -> some View {
        self.modifier(ReducedMotionModifier(animation: animation, fallback: fallback))
    }
}

// MARK: - High Contrast Support

extension DesignSystem.Colors {
    /// Colors that adapt to high contrast mode
    static var adaptiveText: Color {
        Color.primary
    }
    
    static var adaptiveSecondaryText: Color {
        Color.secondary
    }
    
    static var adaptiveBackground: Color {
        Color(NSColor.controlBackgroundColor)
    }
    
    static var adaptiveBorder: Color {
        Color(NSColor.separatorColor)
    }
}

// MARK: - VoiceOver Announcements

class VoiceOverAnnouncer: ObservableObject {
    static let shared = VoiceOverAnnouncer()
    
    private init() {}
    
    /// Announce important changes to VoiceOver users
    func announce(_ message: String, priority: AccessibilityNotificationPriority = .medium) {
        DispatchQueue.main.async {
            switch priority {
            case .high:
                if let app = NSApp {
                    NSAccessibility.post(element: app, notification: .announcementRequested, userInfo: [
                        .announcement: message,
                        .priority: NSAccessibilityPriorityLevel.high.rawValue
                    ])
                }
            default:
                if let app = NSApp {
                    NSAccessibility.post(element: app, notification: .announcementRequested, userInfo: [
                        .announcement: message
                    ])
                }
            }
        }
    }
}

enum AccessibilityNotificationPriority {
    case low, medium, high
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AccessibleStatCard(
            title: "Today's Switches",
            value: "42",
            systemImage: "arrow.left.arrow.right",
            color: .blue,
            accessibilityHint: "Number of times you switched between applications today"
        )
        
        AccessiblePieChartView(
            data: [
                (15, .blue, "Quick"),
                (25, .orange, "Normal"),
                (60, .green, "Focused")
            ],
            title: "Switch Types Distribution"
        )
    }
    .padding()
}