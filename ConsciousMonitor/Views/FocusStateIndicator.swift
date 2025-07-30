import SwiftUI

struct FocusStateIndicator: View {
    @ObservedObject var focusStateDetector: FocusStateDetector
    @State private var isHovered = false
    @State private var showingDetails = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Focus state indicator dot
            Circle()
                .fill(focusStateColor)
                .frame(width: 12, height: 12)
                .shadow(color: focusStateColor.opacity(0.3), radius: 2)
                .animation(.easeInOut(duration: 0.3), value: focusStateDetector.currentFocusState)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(focusStateDetector.currentFocusState.rawValue)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if focusStateDetector.switchingVelocity > 0 {
                    Text("\(String(format: "%.1f", focusStateDetector.switchingVelocity)) switches/min")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
            
            Spacer()
            
            // Info button
            Button(action: { showingDetails.toggle() }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1.0 : 0.7)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .fill(DesignSystem.Colors.contentBackground)
                .stroke(focusStateColor.opacity(0.3), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .popover(isPresented: $showingDetails, arrowEdge: .bottom) {
            FocusStateDetailsView(focusStateDetector: focusStateDetector)
        }
    }
    
    private var focusStateColor: Color {
        switch focusStateDetector.currentFocusState {
        case .deepFocus:
            return DesignSystem.Colors.success
        case .focused:
            return DesignSystem.Colors.accent
        case .scattered:
            return DesignSystem.Colors.warning
        case .overloaded:
            return DesignSystem.Colors.error
        }
    }
}

struct FocusStateDetailsView: View {
    @ObservedObject var focusStateDetector: FocusStateDetector
    @ObservedObject private var notificationService = AwarenessNotificationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            HStack {
                Circle()
                    .fill(focusStateColor)
                    .frame(width: 16, height: 16)
                
                Text("Focus State Details")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
            
            Divider()
            
            // Current state info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                InfoRow(label: "Current State", value: focusStateDetector.currentFocusState.rawValue)
                InfoRow(label: "Switching Velocity", value: "\(String(format: "%.1f", focusStateDetector.switchingVelocity)) per minute")
                InfoRow(label: "Time in State", value: formatDuration(focusStateDetector.timeInCurrentState))
                
                Text(focusStateDetector.currentFocusState.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(.top, DesignSystem.Spacing.sm)
            }
            
            Divider()
            
            // Intervention suggestions
            if let interventionMessage = focusStateDetector.getInterventionMessage() {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("💡 Suggestion")
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(interventionMessage)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(.bottom, DesignSystem.Spacing.sm)
            }
            
            // Quick actions
            HStack {
                Button("Reset State") {
                    focusStateDetector.resetState()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Snooze Alerts") {
                    notificationService.snoozeNotifications(for: 900) // 15 minutes
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(minWidth: 280, maxWidth: 400)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private var focusStateColor: Color {
        switch focusStateDetector.currentFocusState {
        case .deepFocus:
            return DesignSystem.Colors.success
        case .focused:
            return DesignSystem.Colors.accent
        case .scattered:
            return DesignSystem.Colors.warning
        case .overloaded:
            return DesignSystem.Colors.error
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
    }
}

// MARK: - Compact Focus State Indicator

struct CompactFocusStateIndicator: View {
    @ObservedObject var focusStateDetector: FocusStateDetector
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(focusStateColor)
                .frame(width: 8, height: 8)
            
            Text(focusStateDetector.currentFocusState.rawValue)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }
    
    private var focusStateColor: Color {
        switch focusStateDetector.currentFocusState {
        case .deepFocus:
            return DesignSystem.Colors.success
        case .focused:
            return DesignSystem.Colors.accent
        case .scattered:
            return DesignSystem.Colors.warning
        case .overloaded:
            return DesignSystem.Colors.error
        }
    }
}

#Preview {
    VStack {
        FocusStateIndicator(focusStateDetector: FocusStateDetector())
        CompactFocusStateIndicator(focusStateDetector: FocusStateDetector())
    }
    .padding()
}