import Foundation

// MARK: - Shared Time Range Enum
// This enum provides consistent time range options across all analytics views

enum SharedTimeRange: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case all = "All Time"
    
    var id: String { self.rawValue }
    
    // Helper method to get Calendar.Component for filtering
    var calendarComponent: Calendar.Component? {
        switch self {
        case .today:
            return .day
        case .week:
            return .weekOfYear
        case .month:
            return .month
        case .all:
            return nil // No filtering
        }
    }
    
    // Helper method to determine if filtering is needed
    var needsFiltering: Bool {
        return self != .all
    }
    
    // Helper method to get a date range for the selected time range
    func dateRange(from calendar: Calendar = Calendar.current, relativeTo date: Date = Date()) -> DateInterval? {
        let startOfDay = calendar.startOfDay(for: date)
        
        switch self {
        case .today:
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            return DateInterval(start: startOfDay, end: endOfDay)
            
        case .week:
            guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start,
                  let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.end else {
                return nil
            }
            return DateInterval(start: startOfWeek, end: endOfWeek)
            
        case .month:
            guard let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start,
                  let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end else {
                return nil
            }
            return DateInterval(start: startOfMonth, end: endOfMonth)
            
        case .all:
            return nil // No date filtering
        }
    }
    
    // Enhanced filtering method that handles boundary cases properly
    func filterEvents<T>(_ events: [T], timestampKeyPath: KeyPath<T, Date>) -> [T] {
        guard let dateRange = self.dateRange() else {
            return events // All time - no filtering
        }
        
        return events.filter { event in
            let timestamp = event[keyPath: timestampKeyPath]
            // Use inclusive boundary checking instead of DateInterval.contains()
            return timestamp >= dateRange.start && timestamp < dateRange.end
        }
    }
    
    // Helper method to check if a date falls within this time range
    func contains(_ date: Date) -> Bool {
        guard let dateRange = self.dateRange() else {
            return true // All time includes everything
        }
        
        // Use inclusive start, exclusive end for proper boundary handling
        return date >= dateRange.start && date < dateRange.end
    }
}