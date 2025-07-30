# FocusMonitor Development Patterns

A structured memory system capturing institutional knowledge for the FocusMonitor Swift/SwiftUI macOS application development.

## 1. Swift Concurrency Patterns

### 1.1 Swift Sendable Closure Pattern (Latest Fix)
**Problem**: Swift 6 concurrency warnings about non-sendable result types in async closures
**Scenario**: NSImage handling in async methods causing `Non-sendable result type 'NSImage?' cannot be sent`

**Solution**: 
- Mark classes handling UI objects with `@MainActor`
- Structure async operations to avoid crossing concurrency boundaries
- Use `@unchecked Sendable` for ObservableObject classes when needed

**Code Example**:
```swift
@MainActor
class ShareImageService: ObservableObject {
    func generateShareableImage() async -> NSImage? {
        // NSImage operations on main actor
    }
}

// For ObservableObject singletons
class AnalysisStorageService: ObservableObject, @unchecked Sendable {
    // Thread-safe service implementation
}
```

**Why Preferred**: Ensures Swift 6 concurrency compliance while maintaining UI thread safety
**Related Files**: `Services/ShareImageService.swift`, `Services/AnalysisStorageService.swift`

### 1.2 NotificationCenter Observer Pattern
**Problem**: Sendable warnings when using NotificationCenter with closures that need to remove themselves
**Scenario**: System workspace notifications for app monitoring

**Solution**: Use weak capture patterns to avoid Sendable warnings
```swift
// ❌ Causes Sendable warning
NotificationCenter.default.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: nil) { notification in
    self.handleActivation(notification)
}

// ✅ Proper weak capture
NotificationCenter.default.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: nil) { [weak self] notification in
    self?.handleActivation(notification)
}
```

**Why Preferred**: Prevents memory leaks and satisfies Swift concurrency requirements
**Related Files**: `ActivityMonitor.swift`

## 2. Performance Optimization Patterns

### 2.1 Data Caching Pattern
**Problem**: Expensive computations repeated unnecessarily in SwiftUI views
**Scenario**: Chart data calculations, analytics aggregations

**Solution**: Implement time-based caching with automatic invalidation
```swift
class DataCache: ObservableObject {
    private var cache: [String: Any] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheTimeout: TimeInterval = 30
    
    func getCachedValue<T>(for key: String, computeValue: () -> T) -> T {
        if let cachedValue = cache[key] as? T,
           let timestamp = cacheTimestamps[key],
           Date().timeIntervalSince(timestamp) < cacheTimeout {
            return cachedValue
        }
        
        let newValue = computeValue()
        cache[key] = newValue
        cacheTimestamps[key] = Date()
        return newValue
    }
}
```

**Why Preferred**: Balances performance with data freshness, prevents UI stuttering
**Related Files**: `PerformanceOptimizations.swift`

### 2.2 Debounced Updates Pattern
**Problem**: Excessive recomputation during rapid state changes
**Scenario**: User typing, rapid app switches, real-time updates

**Solution**: Implement debouncing with configurable intervals
```swift
class Debouncer: ObservableObject {
    private var workItem: DispatchWorkItem?
    
    func debounce(interval: TimeInterval = 0.3, action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: workItem!)
    }
}
```

**Why Preferred**: Reduces CPU usage and improves responsiveness during high-frequency events
**Related Files**: `PerformanceOptimizations.swift`, `ActivityMonitor.swift`

### 2.3 Lazy Loading Pattern
**Problem**: Large lists causing performance issues on initial render
**Scenario**: Activity logs, analytics data, large datasets

**Solution**: Implement lazy content loading with thresholds
```swift
struct LazyContentView<Content: View>: View {
    let content: Content
    let threshold: CGFloat
    @State private var isLoaded = false
    
    var body: some View {
        Group {
            if isLoaded {
                content
            } else {
                Rectangle().fill(Color.clear).frame(height: 50)
                    .onAppear { isLoaded = true }
            }
        }
    }
}
```

**Why Preferred**: Improves perceived performance and reduces memory usage
**Related Files**: `PerformanceOptimizations.swift`

## 3. Architecture Decision Patterns

### 3.1 Singleton Service Pattern
**Problem**: Shared state management across application lifecycle
**Scenario**: Data storage, user settings, analytics services

**Solution**: ObservableObject singletons with proper thread safety
```swift
class DataStorage: ObservableObject {
    static let shared = DataStorage()
    private init() {}
    
    @Published var data: [Model] = []
    private let dataQueue = DispatchQueue(label: "com.focusmonitor.dataStorage", qos: .utility)
}
```

**Why Preferred**: Ensures single source of truth while maintaining SwiftUI reactivity
**Related Files**: `DataStorage.swift`, `UserSettings.swift`, various Services/

### 3.2 MVVM with Central ViewModel Pattern
**Problem**: Complex state coordination across multiple views
**Scenario**: Activity monitoring, analytics calculations, UI coordination

**Solution**: Central view model (ActivityMonitor) serving as primary coordinator
```swift
class ActivityMonitor: ObservableObject {
    @Published var activationEvents: [AppActivationEvent] = []
    @Published var contextSwitches: [ContextSwitchMetrics] = []
    
    // Service dependencies
    internal let analyticsService = AnalyticsService()
    private let dataStorage = DataStorage.shared
}
```

**Why Preferred**: Centralizes business logic while maintaining clear separation of concerns
**Related Files**: `ActivityMonitor.swift`, `ContentView.swift`

### 3.3 Service Layer Architecture Pattern
**Problem**: Separating business logic from UI and data persistence
**Scenario**: Report generation, data analysis, external integrations

**Solution**: Dedicated service classes for each domain
```swift
// Services/
├── AnalyticsService.swift      # Data analysis and metrics
├── DataExportService.swift     # File export operations
├── ReportGenerationService.swift # Report creation
└── ShareImageService.swift     # Image sharing functionality
```

**Why Preferred**: Enables testability, reusability, and clear responsibility boundaries
**Related Files**: `Services/` directory

## 4. Common Fix Patterns

### 4.1 macOS vs iOS API Compatibility Pattern
**Problem**: iOS-specific APIs causing compilation errors on macOS
**Scenario**: Navigation modifiers, UI components, system APIs

**Solution**: Use macOS-specific alternatives or conditional compilation
```swift
// ❌ iOS-specific
.navigationBarTitleDisplayMode(.inline)

// ✅ macOS-compatible
.navigationTitle("Title")
.toolbar { /* macOS toolbar items */ }
```

**Why Preferred**: Ensures proper platform compatibility and native user experience
**Related Files**: Various View files, documented in `COMPILATION_FIXES.md`

### 4.2 Unused Variable Warning Pattern
**Problem**: Intentionally unused variables causing compiler warnings
**Scenario**: Test data, placeholder implementations, debugging code

**Solution**: Use `let _ = variable` pattern to indicate intentional discard
```swift
// ❌ Compiler warning
let yesterday = Date().addingTimeInterval(-24*60*60)

// ✅ Intentional discard
let _ = Date().addingTimeInterval(-24*60*60)
```

**Why Preferred**: Clearly communicates intent while satisfying compiler
**Related Files**: Test files, development code

### 4.3 AppleScript Permission Handling Pattern
**Problem**: Chrome integration requiring AppleScript permissions
**Scenario**: Browser tab tracking, system automation

**Solution**: Graceful degradation with user feedback
```swift
func requestChromePermission() {
    // Attempt AppleScript execution
    // If fails, provide clear error message with recovery steps
    self.lastDataError = "Chrome Integration Error: Please check Chrome permissions in System Settings > Privacy & Security > Automation."
}
```

**Why Preferred**: Provides clear user guidance for permission-related issues
**Related Files**: `ChromeIntegration.swift`, `AppleScriptRunner.swift`

## 5. UI/UX Patterns

### 5.1 Design System Pattern
**Problem**: Inconsistent styling and spacing across the application
**Scenario**: Colors, typography, spacing, component styling

**Solution**: Centralized design system with semantic naming
```swift
struct DesignSystem {
    struct Colors {
        static let primaryBackground = Color(NSColor.controlBackgroundColor)
        static let contentBackground = Color(NSColor.controlBackgroundColor)
        static let chartColors: [Color] = [.blue, .green, .orange, .red, .purple]
    }
    
    struct Spacing {
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
    }
}
```

**Why Preferred**: Ensures consistent native macOS appearance and maintainable styling
**Related Files**: `DesignSystem.swift`

### 5.2 Accessibility Enhancement Pattern
**Problem**: Poor accessibility for users with disabilities
**Scenario**: VoiceOver support, keyboard navigation, reduced motion

**Solution**: Comprehensive accessibility framework
```swift
struct AccessibleStatCard: View {
    var body: some View {
        StatCard(title: title, value: value, systemImage: systemImage, color: color)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title): \(value)")
            .accessibilityAddTraits(.isStaticText)
    }
}
```

**Why Preferred**: Ensures inclusive user experience following accessibility guidelines
**Related Files**: `AccessibilityEnhancements.swift`

### 5.3 Error Handling UI Pattern
**Problem**: Poor error communication and recovery options
**Scenario**: Data loading failures, network errors, permission issues

**Solution**: Structured error types with recovery suggestions
```swift
enum AppError: LocalizedError, Identifiable {
    case dataStorageError(String)
    case chromeIntegrationError(String)
    
    var recoverySuggestion: String? {
        switch self {
        case .dataStorageError:
            return "Please try saving again or restart the application."
        case .chromeIntegrationError:
            return "Please check Chrome permissions in System Settings."
        }
    }
}
```

**Why Preferred**: Provides actionable feedback and improves user experience during failures
**Related Files**: `ErrorHandling.swift`

### 5.4 Progressive Loading Pattern
**Problem**: App freezing during startup due to heavy operations
**Scenario**: Large dataset loading, expensive computations

**Solution**: Defer heavy operations and show loading states
```swift
struct LoadingStateView: View {
    let message: String
    let progress: Double?
    
    var body: some View {
        VStack {
            if let progress = progress {
                ProgressView(value: progress)
            } else {
                ProgressView()
            }
            Text(message)
        }
    }
}
```

**Why Preferred**: Improves perceived performance and prevents UI freezing
**Related Files**: `ErrorHandling.swift`, various View files

### 5.5 Smart Analytics Integration Pattern
**Problem**: Raw data doesn't provide meaningful insights
**Scenario**: App switch detection, productivity metrics, pattern recognition

**Solution**: Intelligent event processing with contextual analysis
```swift
class SmartSwitchDetector {
    enum EventType {
        case rapidActivationGroup    // Multiple quick switches grouped
        case quickReference         // Brief check/reference
        case meaningfulSwitch       // Legitimate task switch
        case focusSession          // Extended work session
    }
    
    static func processEvents(_ events: [AppActivationEvent]) -> [ProcessedEvent] {
        // Intelligent grouping and classification logic
    }
}
```

**Why Preferred**: Transforms raw data into actionable productivity insights
**Related Files**: `SmartSwitchDetection.swift`, `AnalyticsService.swift`

## 6. Data Management Patterns

### 6.1 Thread-Safe Data Access Pattern
**Problem**: Data corruption from concurrent access
**Scenario**: Background data processing, UI updates

**Solution**: Dedicated dispatch queues for data operations
```swift
class DataStorage {
    private let dataQueue = DispatchQueue(label: "com.focusmonitor.dataStorage", qos: .utility)
    
    func saveData(_ data: [Model]) {
        dataQueue.async {
            // Perform thread-safe data operations
            DispatchQueue.main.async {
                // Update UI on main thread
            }
        }
    }
}
```

**Why Preferred**: Prevents data races while maintaining UI responsiveness
**Related Files**: `DataStorage.swift`, `ActivityMonitor.swift`

### 6.2 File Export Feedback Pattern
**Problem**: Users losing track of exported files
**Scenario**: Report generation, data export, file sharing

**Solution**: Always provide file paths and direct access options
```swift
func exportReport() {
    // Generate and save file
    let filePath = saveToUserDocuments()
    
    // Provide feedback with actions
    showAlert(
        title: "Report Exported",
        message: "Saved to: \(filePath)",
        actions: [
            "Show in Finder": { NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: "") },
            "OK": { }
        ]
    )
}
```

**Why Preferred**: Completes the user workflow and provides immediate file access
**Related Files**: Service files, export-related views

## Usage Guidelines

### When to Apply These Patterns
- **New Feature Development**: Use these patterns as starting templates
- **Code Reviews**: Verify adherence to established patterns
- **Refactoring**: Migrate legacy code to follow these patterns
- **Bug Fixes**: Apply pattern-based solutions for common issues

### Pattern Priority
1. **Swift Concurrency**: Critical for Swift 6 compliance
2. **Performance**: Essential for responsive UI
3. **Architecture**: Important for maintainability
4. **UI/UX**: Required for user satisfaction
5. **Common Fixes**: Necessary for compilation and stability

### Integration with Existing Systems
These patterns leverage the comprehensive infrastructure already in place:
- **SessionManager.swift** - Session tracking and UUID management
- **PerformanceOptimizations.swift** - Caching and optimization framework
- **AccessibilityEnhancements.swift** - VoiceOver and keyboard navigation
- **ErrorHandling.swift** - Structured error management
- **SmartSwitchDetection.swift** - Intelligent analytics processing

### Documentation Updates
When patterns evolve or new patterns emerge:
1. Update this document with the new pattern
2. Include problem/solution context
3. Provide code examples
4. Reference related files
5. Document why the approach is preferred

This memory system should prevent rediscovering solutions and ensure consistency across the codebase while preserving the quality architecture already established.