import SwiftUI

struct ShareableStackView: View {
    let data: ShareableStackData
    let format: ShareableStackFormat
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white,
                    Color.blue.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content based on format
                switch format {
                case .square:
                    squareContentView
                case .landscape:
                    landscapeContentView
                case .story:
                    storyContentView
                }
                
                // Footer
                footerView
            }
            .padding(format == .story ? 40 : 30)
        }
        .frame(
            width: format.dimensions.width,
            height: format.dimensions.height
        )
        .background(Color.white)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Text("FocusMonitor")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Text(timeRangeText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // App icon/logo placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                )
        }
    }
    
    // MARK: - Content Views
    
    private var squareContentView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Title
            Text("MY FOCUS STACK")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            // Main metric
            VStack(spacing: 8) {
                Text("\(Int(data.focusScore))%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(focusScoreColor)
                
                Text("FOCUS SCORE")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.1))
            )
            
            // Achievements grid
            achievementsGridView
            
            // Category breakdown
            if format != .story {
                categoryBreakdownView
            }
            
            Spacer()
        }
    }
    
    private var landscapeContentView: some View {
        HStack(spacing: 30) {
            // Left side - Main metrics
            VStack(spacing: 20) {
                Text("MY FOCUS STACK")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                VStack(spacing: 8) {
                    Text("\(Int(data.focusScore))%")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(focusScoreColor)
                    
                    Text("FOCUS SCORE")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                
                achievementsGridView
            }
            
            // Right side - Category breakdown
            VStack(spacing: 12) {
                Text("CATEGORY BREAKDOWN")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                categoryBreakdownView
            }
        }
        .padding(.vertical, 20)
    }
    
    private var storyContentView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Title
            Text("MY FOCUS STACK")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            // Main metric - larger for story format
            VStack(spacing: 12) {
                Text("\(Int(data.focusScore))%")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(focusScoreColor)
                
                Text("FOCUS SCORE")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))
            )
            
            // Achievements - stacked vertically for story
            VStack(spacing: 16) {
                ForEach(Array(data.achievements.prefix(3).enumerated()), id: \.offset) { _, achievement in
                    achievementRowView(achievement)
                }
            }
            
            // Category breakdown - simplified for story
            VStack(spacing: 12) {
                Text("TOP CATEGORIES")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    ForEach(Array(data.categoryBreakdown.prefix(3).enumerated()), id: \.offset) { _, category in
                        categoryRowView(category)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Component Views
    
    private var achievementsGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: format == .story ? 1 : 2), spacing: 12) {
            ForEach(Array(data.achievements.prefix(4).enumerated()), id: \.offset) { _, achievement in
                achievementCardView(achievement)
            }
        }
    }
    
    private func achievementCardView(_ achievement: ShareableStackData.Achievement) -> some View {
        VStack(spacing: 4) {
            Text(achievement.icon)
                .font(.system(size: 20))
            
            Text(achievement.value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(achievement.title)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private func achievementRowView(_ achievement: ShareableStackData.Achievement) -> some View {
        HStack(spacing: 12) {
            Text(achievement.icon)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(achievement.value)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var categoryBreakdownView: some View {
        VStack(spacing: 8) {
            ForEach(Array(data.categoryBreakdown.prefix(format == .story ? 3 : 5).enumerated()), id: \.offset) { _, category in
                categoryRowView(category)
            }
        }
    }
    
    private func categoryRowView(_ category: ShareableStackData.CategoryUsageData) -> some View {
        HStack(spacing: 12) {
            // Category color indicator
            Circle()
                .fill(category.color)
                .frame(width: 8, height: 8)
            
            // Category name
            Text(category.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Percentage
            Text("\(Int(category.percentage))%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            Text("Built with intention")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("#FocusStack")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("#ProductivityWins")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Computed Properties
    
    private var timeRangeText: String {
        switch data.timeRange {
        case .today:
            return "Today"
        case .thisWeek:
            return "This Week"
        case .thisMonth:
            return "This Month"
        case .custom:
            if let startDate = data.customStartDate, let endDate = data.customEndDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
            }
            return "Custom Range"
        }
    }
    
    private var focusScoreColor: Color {
        switch data.focusScore {
        case 80...100:
            return .green
        case 60...79:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Preview

struct ShareableStackView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = ShareableStackData(
            timeRange: .today,
            customStartDate: nil,
            customEndDate: nil,
            focusScore: 75.0,
            contextSwitches: 32,
            deepFocusSessions: 5,
            longestFocusSession: 3600,
            productivityCostSavings: 45.0,
            categoryBreakdown: [
                ShareableStackData.CategoryUsageData(name: "Productivity", percentage: 42.0, color: .green),
                ShareableStackData.CategoryUsageData(name: "Communication", percentage: 28.0, color: .blue),
                ShareableStackData.CategoryUsageData(name: "Development", percentage: 20.0, color: .orange),
                ShareableStackData.CategoryUsageData(name: "Entertainment", percentage: 10.0, color: .red)
            ],
            topApps: [],
            achievements: [
                ShareableStackData.Achievement(title: "Solid Focus", value: "75% Focus Score", icon: "🔥"),
                ShareableStackData.Achievement(title: "Deep Work", value: "5 sessions", icon: "🧠"),
                ShareableStackData.Achievement(title: "Focus Streak", value: "1h 0m", icon: "⏰"),
                ShareableStackData.Achievement(title: "Cost Savings", value: "$45", icon: "💰")
            ],
            privacyLevel: .detailed
        )
        
        Group {
            ShareableStackView(data: sampleData, format: .square)
                .previewDisplayName("Square Format")
            
            ShareableStackView(data: sampleData, format: .landscape)
                .previewDisplayName("Landscape Format")
            
            ShareableStackView(data: sampleData, format: .story)
                .previewDisplayName("Story Format")
        }
    }
}