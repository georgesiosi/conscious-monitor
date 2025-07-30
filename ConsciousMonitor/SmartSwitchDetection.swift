import Foundation

// MARK: - Smart Switch Detection

/// Enhanced switch detection that distinguishes between productive patterns and disruptive interruptions
class SmartSwitchDetector {
    
    // MARK: - Detection Parameters
    
    /// Group rapid activations within this window as a single interaction
    private static let rapidActivationWindow: TimeInterval = 8.0 // 8 seconds
    
    /// Minimum time to consider a switch "meaningful" for productivity analysis
    private static let meaningfulSwitchThreshold: TimeInterval = 10.0 // 10 seconds
    
    /// Maximum time for a "quick reference" check
    private static let quickReferenceThreshold: TimeInterval = 15.0 // 15 seconds
    
    // MARK: - Processed Event Types
    
    struct ProcessedEvent {
        let originalEvent: AppActivationEvent
        let eventType: EventType
        let groupedEvents: [AppActivationEvent] // For rapid activation groups
        let effectiveTimestamp: Date
    }
    
    enum EventType {
        case rapidActivationGroup    // Multiple quick switches grouped together
        case quickReference         // Brief check/reference (< 15s)
        case meaningfulSwitch       // Legitimate task switch (10s - 2min)
        case focusSession          // Extended work session (> 2min)
        case isolated              // Single event, context unclear
    }
    
    // MARK: - Smart Processing
    
    /// Process a list of app activation events and group/classify them intelligently
    static func processEvents(_ events: [AppActivationEvent]) -> [ProcessedEvent] {
        guard !events.isEmpty else { return [] }
        
        let sortedEvents = events.sorted { $0.timestamp < $1.timestamp }
        var processedEvents: [ProcessedEvent] = []
        var i = 0
        
        while i < sortedEvents.count {
            let currentEvent = sortedEvents[i]
            
            // Look ahead for rapid activation groups
            let (groupedEvents, nextIndex) = groupRapidActivations(
                from: sortedEvents, 
                startingAt: i
            )
            
            if groupedEvents.count > 1 {
                // Multiple rapid activations - treat as single interaction
                let processedEvent = ProcessedEvent(
                    originalEvent: currentEvent,
                    eventType: .rapidActivationGroup,
                    groupedEvents: groupedEvents,
                    effectiveTimestamp: currentEvent.timestamp
                )
                processedEvents.append(processedEvent)
                i = nextIndex
            } else {
                // Single event - classify based on duration if possible
                let eventType = classifySingleEvent(currentEvent, in: sortedEvents, at: i)
                let processedEvent = ProcessedEvent(
                    originalEvent: currentEvent,
                    eventType: eventType,
                    groupedEvents: [currentEvent],
                    effectiveTimestamp: currentEvent.timestamp
                )
                processedEvents.append(processedEvent)
                i += 1
            }
        }
        
        return processedEvents
    }
    
    // MARK: - Rapid Activation Grouping
    
    private static func groupRapidActivations(
        from events: [AppActivationEvent], 
        startingAt index: Int
    ) -> (grouped: [AppActivationEvent], nextIndex: Int) {
        
        var groupedEvents: [AppActivationEvent] = [events[index]]
        var currentIndex = index + 1
        let startTime = events[index].timestamp
        
        // Group consecutive events within the rapid activation window
        while currentIndex < events.count {
            let nextEvent = events[currentIndex]
            let timeDelta = nextEvent.timestamp.timeIntervalSince(startTime)
            
            if timeDelta <= rapidActivationWindow {
                groupedEvents.append(nextEvent)
                currentIndex += 1
            } else {
                break
            }
        }
        
        return (groupedEvents, currentIndex)
    }
    
    // MARK: - Event Classification
    
    private static func classifySingleEvent(
        _ event: AppActivationEvent,
        in events: [AppActivationEvent],
        at index: Int
    ) -> EventType {
        
        // Look at next event to calculate duration
        guard index + 1 < events.count else {
            return .isolated
        }
        
        let nextEvent = events[index + 1]
        let duration = nextEvent.timestamp.timeIntervalSince(event.timestamp)
        
        // Classify based on duration
        if duration < meaningfulSwitchThreshold {
            return .quickReference
        } else if duration < 120 { // 2 minutes
            return .meaningfulSwitch
        } else {
            return .focusSession
        }
    }
    
    // MARK: - Context Switch Creation
    
    /// Create context switches from processed events, filtering out non-productive patterns
    static func createIntelligentContextSwitches(
        from processedEvents: [ProcessedEvent]
    ) -> [ContextSwitchMetrics] {
        
        var contextSwitches: [ContextSwitchMetrics] = []
        
        for i in 0..<processedEvents.count - 1 {
            let currentProcessed = processedEvents[i]
            let nextProcessed = processedEvents[i + 1]
            
            let currentEvent = currentProcessed.originalEvent
            let nextEvent = nextProcessed.originalEvent
            
            // Only create context switches for meaningful interactions
            guard shouldCreateContextSwitch(
                from: currentProcessed,
                to: nextProcessed
            ) else {
                continue
            }
            
            // Calculate effective time spent (may be adjusted for grouped events)
            let timeSpent = calculateEffectiveTimeSpent(
                from: currentProcessed,
                to: nextProcessed
            )
            
            // Create context switch with intelligent classification
            let contextSwitch = ContextSwitchMetrics(
                fromApp: currentEvent.appName ?? "Unknown",
                toApp: nextEvent.appName ?? "Unknown",
                fromBundleId: currentEvent.bundleIdentifier,
                toBundleId: nextEvent.bundleIdentifier,
                timestamp: nextEvent.timestamp,
                timeSpent: timeSpent,
                fromCategory: currentEvent.category,
                toCategory: nextEvent.category,
                sessionId: nextEvent.sessionId
            )
            
            contextSwitches.append(contextSwitch)
        }
        
        return contextSwitches
    }
    
    // MARK: - Switch Creation Logic
    
    private static func shouldCreateContextSwitch(
        from current: ProcessedEvent,
        to next: ProcessedEvent
    ) -> Bool {
        
        let currentApp = current.originalEvent.appName
        let nextApp = next.originalEvent.appName
        
        // Don't create switches between the same app
        guard currentApp != nextApp else { return false }
        
        // Don't create switches for rapid activation groups (they're not real task switches)
        if current.eventType == .rapidActivationGroup {
            return false
        }
        
        // Create switches for meaningful interactions
        switch current.eventType {
        case .meaningfulSwitch, .focusSession:
            return true
        case .quickReference:
            // Only create switch if the quick reference led to meaningful work
            return next.eventType == .meaningfulSwitch || next.eventType == .focusSession
        case .isolated:
            // Use conservative approach for unclear events
            return true
        case .rapidActivationGroup:
            return false
        }
    }
    
    private static func calculateEffectiveTimeSpent(
        from current: ProcessedEvent,
        to next: ProcessedEvent
    ) -> TimeInterval {
        
        let startTime: Date
        let endTime = next.effectiveTimestamp
        
        // For grouped events, use the timestamp of the last event in the group
        if current.eventType == .rapidActivationGroup,
           let lastEvent = current.groupedEvents.last {
            startTime = lastEvent.timestamp
        } else {
            startTime = current.effectiveTimestamp
        }
        
        return endTime.timeIntervalSince(startTime)
    }
    
    // MARK: - Productivity Insights
    
    /// Generate productivity-aware metrics from processed events
    static func generateProductivityMetrics(
        from processedEvents: [ProcessedEvent]
    ) -> ProductivityMetrics {
        
        var quickChecks = 0
        var meaningfulSwitches = 0
        var focusSessions = 0
        var rapidActivationGroups = 0
        var totalFocusTime: TimeInterval = 0
        
        for processed in processedEvents {
            switch processed.eventType {
            case .quickReference:
                quickChecks += 1
            case .meaningfulSwitch:
                meaningfulSwitches += 1
            case .focusSession:
                focusSessions += 1
                // Estimate focus time based on next event or default
                totalFocusTime += estimateFocusTime(for: processed, in: processedEvents)
            case .rapidActivationGroup:
                rapidActivationGroups += 1
            case .isolated:
                break // Don't count unclear events
            }
        }
        
        return ProductivityMetrics(
            quickChecks: quickChecks,
            meaningfulSwitches: meaningfulSwitches,
            focusSessions: focusSessions,
            rapidActivationGroups: rapidActivationGroups,
            totalFocusTime: totalFocusTime
        )
    }
    
    private static func estimateFocusTime(
        for event: ProcessedEvent,
        in allEvents: [ProcessedEvent]
    ) -> TimeInterval {
        
        guard let currentIndex = allEvents.firstIndex(where: { 
            $0.effectiveTimestamp == event.effectiveTimestamp 
        }) else {
            return 120 // Default 2 minutes if we can't find the event
        }
        
        if currentIndex + 1 < allEvents.count {
            let nextEvent = allEvents[currentIndex + 1]
            return nextEvent.effectiveTimestamp.timeIntervalSince(event.effectiveTimestamp)
        } else {
            return 120 // Default 2 minutes for last event
        }
    }
}

// MARK: - Productivity Metrics

struct ProductivityMetrics {
    let quickChecks: Int           // Brief reference checks (< 15s)
    let meaningfulSwitches: Int    // Actual task switches (10s - 2min)
    let focusSessions: Int         // Deep work sessions (> 2min)
    let rapidActivationGroups: Int // Grouped rapid switches
    let totalFocusTime: TimeInterval // Total estimated focus time
    
    /// Overall productivity score (0-100)
    var productivityScore: Double {
        let totalInteractions = quickChecks + meaningfulSwitches + focusSessions + rapidActivationGroups
        guard totalInteractions > 0 else { return 100 }
        
        // Weight different interaction types
        let focusWeight = Double(focusSessions) * 3.0      // Highly positive
        let meaningfulWeight = Double(meaningfulSwitches) * 1.0  // Neutral
        let quickWeight = Double(quickChecks) * 0.5        // Slightly positive (efficient)
        let rapidWeight = Double(rapidActivationGroups) * -1.0   // Negative (scattered)
        
        let weightedScore = (focusWeight + meaningfulWeight + quickWeight + rapidWeight) / Double(totalInteractions)
        return max(0, min(100, (weightedScore + 1) * 50)) // Normalize to 0-100
    }
    
    /// Human-readable productivity assessment
    var productivityLevel: String {
        switch productivityScore {
        case 80...100: return "Highly Focused"
        case 60..<80: return "Moderately Focused"
        case 40..<60: return "Mixed Focus"
        case 20..<40: return "Scattered Attention"
        default: return "Highly Distracted"
        }
    }
}