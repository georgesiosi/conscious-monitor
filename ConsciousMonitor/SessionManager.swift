import Foundation

// MARK: - Session Management Extension
extension ActivityMonitor {
    
    /// Manages session tracking for app activation events
    func manageSession(at currentTime: Date) -> (sessionId: UUID, sessionStartTime: Date, isSessionStart: Bool, switchCount: Int) {
        // Check if this is a new session
        if let lastTime = self.lastEventTime {
            let timeSinceLastEvent = currentTime.timeIntervalSince(lastTime)
            
            if timeSinceLastEvent < Self.sessionThreshold &&
               self.currentSessionId != nil &&
               (currentTime.timeIntervalSince(self.currentSessionStartTime ?? currentTime) < Self.maxSessionDuration) {
                // Continue existing session
                self.currentSessionSwitchCount += 1
                return (self.currentSessionId!, self.currentSessionStartTime!, false, self.currentSessionSwitchCount)
            } else {
                // End current session if any
                if self.currentSessionId != nil {
                    // Mark last event as session end
                    if let lastIndex = self.activationEvents.indices.first {
                        self.activationEvents[lastIndex].isSessionEnd = true
                        self.activationEvents[lastIndex].sessionEndTime = self.lastEventTime
                    }
                }
                
                // Start new session
                return startNewSession(at: currentTime)
            }
        } else {
            // First event, start new session
            return startNewSession(at: currentTime)
        }
    }
    
    /// Starts a new session
    private func startNewSession(at time: Date) -> (sessionId: UUID, sessionStartTime: Date, isSessionStart: Bool, switchCount: Int) {
        self.currentSessionId = UUID()
        self.currentSessionStartTime = time
        self.currentSessionSwitchCount = 1
        return (self.currentSessionId!, self.currentSessionStartTime!, true, self.currentSessionSwitchCount)
    }
    
    /// Updates the last event time
    func updateLastEventTime(_ time: Date) {
        self.lastEventTime = time
    }
}
