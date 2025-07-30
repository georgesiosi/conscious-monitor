import SwiftUI

struct InfoTooltip: View {
    let text: String
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: "info.circle")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.accent)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .overlay(alignment: .top) {
            if isHovering {
                NativeTooltip(text: text, isVisible: isHovering)
                    .offset(y: -35)
                    .zIndex(1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Information")
        .accessibilityValue(text)
        .help(text) // Native macOS tooltip as fallback
    }
}

struct InfoTooltip_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            InfoTooltip(text: "This is a helpful tooltip that explains what this metric means.")
        }
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}
