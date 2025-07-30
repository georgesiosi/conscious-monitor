import Foundation
import Combine

enum FocusState: String, CaseIterable {
    case deepFocus = "Deep Focus"           // Long periods without switching
    case focused = "Focused"                // Normal productive switching
    case scattered = "Scattered"            // Frequent switching detected
    case overloaded = "Cognitive Overload"  // Rapid switching pattern
    
    var color: String {
        switch self {
        case .deepFocus: return "systemGreen"
        case .focused: return "systemBlue" 
        case .scattered: return "systemOrange"
        case .overloaded: return "systemRed"
        }
    }
    
    var description: String {
        switch self {
        case .deepFocus: return "You're in a great flow state with sustained focus"
        case .focused: return "Healthy switching pattern for productive work"
        case .scattered: return "Frequent switching detected - consider consolidating tasks"
        case .overloaded: return "Rapid switching may be impacting your cognitive performance"
        }
    }
}

class FocusStateDetector: ObservableObject {
    @Published var currentFocusState: FocusState = .focused
    @Published var switchingVelocity: Double = 0.0 // switches per minute
    @Published var timeInCurrentState: TimeInterval = 0
    
    private var recentSwitches: [Date] = []
    private var lastStateChange: Date = Date()
    private var stateTimer: Timer?
    
    // Thresholds for state detection (configurable)
    private let deepFocusThreshold: TimeInterval = 600    // 10 minutes without switching
    private let scatteredThreshold: Double = 4.0         // 4+ switches per minute
    private let overloadedThreshold: Double = 8.0        // 8+ switches per minute
    private let evaluationWindow: TimeInterval = 300     // 5 minute window for analysis
    
    init() {
        startStateTimer()
    }
    
    deinit {
        stateTimer?.invalidate()
    }
    
    private func startStateTimer() {
        stateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateTimeInCurrentState()
        }
    }
    
    private func updateTimeInCurrentState() {
        timeInCurrentState = Date().timeIntervalSince(lastStateChange)
        objectWillChange.send()
    }
    
    func recordContextSwitch(at timestamp: Date = Date()) {
        // Add to recent switches
        recentSwitches.append(timestamp)
        
        // Clean old switches outside evaluation window
        let cutoffTime = timestamp.addingTimeInterval(-evaluationWindow)
        recentSwitches = recentSwitches.filter { $0 > cutoffTime }
        
        // Calculate switching velocity (switches per minute)
        let switchesInWindow = recentSwitches.count
        switchingVelocity = Double(switchesInWindow) / (evaluationWindow / 60.0)
        
        // Determine new focus state
        let newState = determineFocusState(timestamp: timestamp)
        
        if newState != currentFocusState {
            currentFocusState = newState
            lastStateChange = timestamp
            timeInCurrentState = 0
            
            // Notify observers of state change
            NotificationCenter.default.post(
                name: .focusStateChanged,
                object: nil,
                userInfo: [
                    "newState": newState,
                    "switchingVelocity": switchingVelocity,
                    "timestamp": timestamp
                ]
            )
        }
        
        objectWillChange.send()
    }
    
    private func determineFocusState(timestamp: Date) -> FocusState {
        // Check for cognitive overload first (highest priority)
        if switchingVelocity >= overloadedThreshold {
            return .overloaded
        }
        
        // Check for scattered attention
        if switchingVelocity >= scatteredThreshold {
            return .scattered
        }
        
        // Check for deep focus (no switches for extended period)
        if recentSwitches.isEmpty || 
           timestamp.timeIntervalSince(recentSwitches.last ?? timestamp) >= deepFocusThreshold {
            return .deepFocus
        }
        
        // Default to focused state
        return .focused
    }
    
    // Public method to get current state summary
    func getCurrentStateSummary() -> (state: FocusState, velocity: Double, duration: TimeInterval) {
        return (currentFocusState, switchingVelocity, timeInCurrentState)
    }
    
    // Method to reset state (useful for new sessions)
    func resetState() {
        recentSwitches.removeAll()
        currentFocusState = .focused
        switchingVelocity = 0.0
        lastStateChange = Date()
        timeInCurrentState = 0
    }
    
    // Method to check if intervention is needed
    func shouldTriggerIntervention() -> Bool {
        switch currentFocusState {
        case .overloaded:
            return true
        case .scattered:
            // Only trigger if scattered for more than 2 minutes
            return timeInCurrentState > 120
        default:
            return false
        }
    }
    
    // Get intervention message based on current state
    func getInterventionMessage() -> String? {
        guard shouldTriggerIntervention() else { return nil }
        
        switch currentFocusState {
        case .overloaded:
            return "You've been switching rapidly between tasks. Consider taking a brief pause to refocus."
        case .scattered:
            return "Frequent task switching detected. Would you like to set a focus intention for the next 25 minutes?"
        default:
            return nil
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let focusStateChanged = Notification.Name("FocusStateChanged")
}