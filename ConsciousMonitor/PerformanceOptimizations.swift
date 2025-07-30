import SwiftUI
import Combine

// MARK: - Data Cache

/// Simple cache for expensive computations
class DataCache: ObservableObject {
    private var cache: [String: Any] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheTimeout: TimeInterval = 30 // 30 seconds
    
    /// Get cached value or compute and cache it
    func getCachedValue<T>(
        for key: String,
        computeValue: () -> T
    ) -> T {
        // Check if we have a valid cached value
        if let cachedValue = cache[key] as? T,
           let timestamp = cacheTimestamps[key],
           Date().timeIntervalSince(timestamp) < cacheTimeout {
            return cachedValue
        }
        
        // Compute new value and cache it
        let newValue = computeValue()
        cache[key] = newValue
        cacheTimestamps[key] = Date()
        
        return newValue
    }
    
    /// Invalidate specific cache key
    func invalidateCache(for key: String) {
        cache.removeValue(forKey: key)
        cacheTimestamps.removeValue(forKey: key)
    }
    
    /// Clear all cache
    func clearCache() {
        cache.removeAll()
        cacheTimestamps.removeAll()
    }
    
    /// Get all cached keys (for debugging)
    var cachedKeys: [String] {
        Array(cache.keys)
    }
}

// MARK: - Memoized Computed Properties

/// Property wrapper for memoized computed properties
@propertyWrapper
struct Memoized<Value> {
    private var value: Value?
    private var dependencies: [AnyHashable] = []
    
    var wrappedValue: Value {
        mutating get {
            fatalError("Memoized can only be used with computed properties")
        }
        set {
            value = newValue
        }
    }
    
    mutating func callAsFunction(_ dependencies: [AnyHashable], _ computation: () -> Value) -> Value {
        if let cachedValue = value, self.dependencies == dependencies {
            return cachedValue
        }
        
        let newValue = computation()
        self.value = newValue
        self.dependencies = dependencies
        return newValue
    }
}

// MARK: - Performance Monitoring

/// Simple performance monitoring for SwiftUI views
struct PerformanceMonitor: ViewModifier {
    let label: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                let startTime = CFAbsoluteTimeGetCurrent()
                DispatchQueue.main.async {
                    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                    if timeElapsed > 0.016 { // 16ms threshold (60fps)
                        print("⚠️ Performance: \(label) took \(String(format: "%.2f", timeElapsed * 1000))ms to render")
                    }
                }
            }
    }
}

extension View {
    /// Monitor performance of view rendering
    func performanceMonitor(_ label: String) -> some View {
        self.modifier(PerformanceMonitor(label: label))
    }
}

// MARK: - Optimized List Views

/// Optimized list row that only updates when necessary
struct OptimizedListRow<Content: View>: View {
    let id: AnyHashable
    let content: Content
    
    init<ID: Hashable>(id: ID, @ViewBuilder content: () -> Content) {
        self.id = AnyHashable(id)
        self.content = content()
    }
    
    var body: some View {
        content
            .id(id)
            .listRowStyle()
    }
}

// MARK: - Lazy Loading Views

/// Container for lazy-loaded content
struct LazyContentView<Content: View>: View {
    let content: Content
    let threshold: CGFloat
    
    @State private var isLoaded = false
    
    init(threshold: CGFloat = 100, @ViewBuilder content: () -> Content) {
        self.threshold = threshold
        self.content = content()
    }
    
    var body: some View {
        Group {
            if isLoaded {
                content
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 50)
                    .onAppear {
                        isLoaded = true
                    }
            }
        }
    }
}

// MARK: - Debounced Updates

/// Debounce updates to prevent excessive recomputation
class Debouncer: ObservableObject {
    private var workItem: DispatchWorkItem?
    
    func debounce(interval: TimeInterval = 0.3, action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: workItem!)
    }
}

// MARK: - Performance-Optimized Extensions

extension ActivityMonitor {
    /// Cached computation for app activations in last 5 minutes
    var cachedAppActivationsInLast5Minutes: Int {
        let cacheKey = "activations_5min_\(Int(Date().timeIntervalSince1970 / 60))" // Cache per minute
        return DataCache.shared.getCachedValue(for: cacheKey) {
            let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
            return activationEvents.filter { $0.timestamp > fiveMinutesAgo }.count
        }
    }
    
    /// Cached computation for today's app activations
    var cachedAppActivationsToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let cacheKey = "activations_today_\(today.timeIntervalSince1970)"
        return DataCache.shared.getCachedValue(for: cacheKey) {
            activationEvents.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }.count
        }
    }
    
    /// Invalidate relevant caches when data changes
    func invalidateComputedPropertyCaches() {
        let today = Calendar.current.startOfDay(for: Date())
        let currentMinute = Int(Date().timeIntervalSince1970 / 60)
        
        DataCache.shared.invalidateCache(for: "activations_5min_\(currentMinute)")
        DataCache.shared.invalidateCache(for: "activations_today_\(today.timeIntervalSince1970)")
    }
}

// MARK: - Shared Cache Instance

extension DataCache {
    static let shared = DataCache()
}

// MARK: - View Extensions for Performance

extension View {
    /// Apply performance optimizations to lists
    func optimizedList() -> some View {
        self
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
    }
    
    /// Lazy loading wrapper
    func lazyLoad(threshold: CGFloat = 100) -> some View {
        LazyContentView(threshold: threshold) {
            self
        }
    }
}