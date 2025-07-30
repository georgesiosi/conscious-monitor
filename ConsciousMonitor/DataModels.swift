import SwiftUI // For Color

struct AppSwitchChartData: Identifiable, Equatable {
    let id = UUID()
    var appName: String
    var bundleIdentifier: String?
    var activationCount: Int
    var category: AppCategory // Assumes AppCategory struct is defined and accessible

    var color: Color {
        return category.color
    }

    static func == (lhs: AppSwitchChartData, rhs: AppSwitchChartData) -> Bool {
        lhs.id == rhs.id
    }
}
