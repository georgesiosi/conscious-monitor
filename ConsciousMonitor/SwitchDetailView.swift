import SwiftUI
import Charts

struct SwitchDetailView: View {
    let switchMetric: ContextSwitchMetrics
    @Environment(\.presentationMode) var presentationMode
    
    private var timeSpentString: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: switchMetric.timeSpent) ?? "0s"
    }
    
    private var timestampString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: switchMetric.timestamp)
    }
    
    private var timeOfDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: switchMetric.timestamp)
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: switchMetric.timestamp)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with close button
            HStack {
                Text("Switch Details")
                    .font(.title2.bold())
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom)
            
            // Main content
            VStack(alignment: .leading, spacing: 16) {
                // Switch summary
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(switchMetric.fromApp) → \(switchMetric.toApp)")
                            .font(.title3.bold())
                        
                        Spacer()
                        
                        // Switch type indicator
                        Text(switchMetric.switchType.rawValue.capitalized)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(switchMetric.switchType.color.opacity(0.2))
                            .foregroundColor(switchMetric.switchType.color)
                            .cornerRadius(4)
                    }
                    
                    // Time spent
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("Time spent: \(timeSpentString)")
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                    
                    // Timestamp
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                        Text("\(dayOfWeek) at \(timeOfDay)")
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                .cornerRadius(10)
                
                // Time spent visualization
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time Spent")
                        .font(.headline)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        VStack {
                            Rectangle()
                                .fill(switchMetric.switchType.color)
                                .frame(width: 20, height: CGFloat(min(switchMetric.timeSpent / 10, 200)))
                                .cornerRadius(4)
                            
                            Text("\(Int(switchMetric.timeSpent))s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Switch Type: \(switchMetric.switchType.description)")
                                .font(.subheadline)
                            
                            Text("Context: \(getContextDescription(for: switchMetric))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(10)
                }
                
                // Potential impact
                VStack(alignment: .leading, spacing: 8) {
                    Text("Potential Impact")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        impactRow(
                            icon: "exclamationmark.triangle",
                            title: "Productivity Impact",
                            description: getProductivityImpact(for: switchMetric),
                            color: .orange
                        )
                        
                        Divider()
                        
                        impactRow(
                            icon: "lightbulb",
                            title: "Suggestion",
                            description: getSuggestion(for: switchMetric),
                            color: .blue
                        )
                    }
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
        }
        .padding()
        .frame(width: 400, height: 500)
    }
    
    private func impactRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
    
    private func getContextDescription(for switchMetric: ContextSwitchMetrics) -> String {
        switch switchMetric.switchType {
        case .quick:
            return "Quick check - efficient reference pattern"
        case .normal:
            return "Task switch - typical work transition"
        case .focused:
            return "Focused work - sustained attention"
        }
    }
    
    private func getProductivityImpact(for switchMetric: ContextSwitchMetrics) -> String {
        switch switchMetric.switchType {
        case .quick:
            return "Minimal - Quick checks are efficient and don't harm productivity"
        case .normal:
            return "Low - Brief refocus time, typical of healthy work patterns"
        case .focused:
            return "Positive - Extended focus time significantly boosts productivity"
        }
    }
    
    private func getSuggestion(for switchMetric: ContextSwitchMetrics) -> String {
        switch switchMetric.switchType {
        case .quick:
            return "Efficient quick check! This type of brief reference is healthy for productivity."
        case .normal:
            return "Good task switching pattern. This represents healthy workflow transitions."
        case .focused:
            return "Excellent focus! Consider taking a short break to maintain this high level of concentration."
        }
    }
}

// MARK: - Preview

struct SwitchDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleSwitch = ContextSwitchMetrics(
            fromApp: "Xcode",
            toApp: "Slack",
            fromBundleId: "com.apple.dt.Xcode",
            toBundleId: "com.tinyspeck.slackmacgap",
            timeSpent: 45
        )
        
        return SwitchDetailView(switchMetric: sampleSwitch)
            .frame(width: 400, height: 500)
            .preferredColorScheme(.dark)
    }
}
