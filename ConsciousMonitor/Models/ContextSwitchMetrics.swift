import Foundation
import SwiftUI

// MARK: - Context Switch Tracking

/// Tracks metrics for context switches between applications
enum SwitchType: String, Codable, CaseIterable {
    case quick = "quick"      // < 10 seconds - brief checks/references
    case normal = "normal"    // 10s - 2 minutes - typical task switches
    case focused = "focused"  // > 2 minutes - deep work sessions
    
    var threshold: TimeInterval {
        switch self {
        case .quick: return 10
        case .normal: return 120 // 2 minutes
        case .focused: return .infinity
        }
    }
    
    var color: Color {
        switch self {
        case .quick: return .blue     // Neutral blue for quick checks
        case .normal: return .orange  // Amber for normal task switches
        case .focused: return .green  // Green for focused work
        }
    }
    
    var icon: String {
        switch self {
        case .quick: return "eye"                        // Quick glance
        case .normal: return "arrow.right.arrow.left"   // Task switching
        case .focused: return "target"                  // Focused work
        }
    }
    
    var description: String {
        switch self {
        case .quick: return "Quick Check (< 10s)"
        case .normal: return "Task Switch (10s - 2min)"
        case .focused: return "Focused Work (> 2min)"
        }
    }
}

struct ContextSwitchMetrics: Identifiable, Codable, Hashable {
    let id: UUID
    let fromApp: String
    let toApp: String
    let fromBundleId: String?
    let toBundleId: String?
    let timestamp: Date
    let timeSpent: TimeInterval // in seconds
    let switchType: SwitchType
    let fromCategory: AppCategory
    let toCategory: AppCategory
    
    // Session info
    let sessionId: UUID?
    
    init(fromApp: String, toApp: String, fromBundleId: String? = nil, toBundleId: String? = nil,
         timestamp: Date, timeSpent: TimeInterval, fromCategory: AppCategory, toCategory: AppCategory,
         sessionId: UUID? = nil) {
        self.id = UUID()
        self.fromApp = fromApp
        self.toApp = toApp
        self.fromBundleId = fromBundleId
        self.toBundleId = toBundleId
        self.timestamp = timestamp
        self.timeSpent = timeSpent
        self.fromCategory = fromCategory
        self.toCategory = toCategory
        self.sessionId = sessionId
        
        // Determine switch type based on time spent
        if timeSpent < SwitchType.quick.threshold {
            self.switchType = .quick
        } else if timeSpent < SwitchType.normal.threshold {
            self.switchType = .normal
        } else {
            self.switchType = .focused
        }
    }
    
    // Convenience initializer for backwards compatibility
    init(fromApp: String, toApp: String, fromBundleId: String? = nil, toBundleId: String? = nil,
         timeSpent: TimeInterval) {
        self.init(
            fromApp: fromApp,
            toApp: toApp,
            fromBundleId: fromBundleId,
            toBundleId: toBundleId,
            timestamp: Date(),
            timeSpent: timeSpent,
            fromCategory: CategoryManager.shared.getCategory(for: fromBundleId ?? ""),
            toCategory: CategoryManager.shared.getCategory(for: toBundleId ?? ""),
            sessionId: nil
        )
    }
}
