# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ConsciousMonitor (formerly FocusMonitor) is a native macOS application built with SwiftUI that tracks application usage and context switching patterns to help users understand their productivity habits. The app monitors active applications, Chrome tab switches, and provides analytics on focus and distraction patterns.

## Development Commands

### Building and Running

- **Build and run**: Open `ConsciousMonitor.xcodeproj` in Xcode, select the ConsciousMonitor scheme and "My Mac" as destination, then click Run
- **Archive for distribution**: Product → Archive in Xcode
- **Create DMG installer**: `./create-installer.sh` (requires `create-dmg` via Homebrew)
- **Version management**: `./bump-version.sh [major|minor|patch]`

### Release Management

- **DMG Creation**: Run `./create-installer.sh` after building (requires `brew install create-dmg`)
- **Distribution preparation**: Ensure releases/ directory is gitignored
- **GitHub Release Process**: Tag → DMG → Upload → Publish
- **Release naming**: Use standard `v1.0.0` format

### Release & Distribution

- **Branch strategy**: Use trunk-based development with `main` as single source of truth
- **Releases**: Create git tags for stable releases (e.g., `v1.0.0`, `v1.1.0`)
- **Distribution**: DMG files can be created directly from tagged commits
- **No separate prod branch**: Deploy and distribute from `main` using tags

#### GitHub Release Workflow

1. **Create and push tag**: `git tag v1.0.0 && git push origin v1.0.0`
2. **Go to GitHub**: Visit repository releases page
3. **Create new release**: Select the tag, title as "ConsciousMonitor v1.0.0"
4. **Upload DMG**: Attach the DMG file from `./create-installer.sh`
5. **Write release notes**: Include features, installation instructions, and requirements
6. **Publish**: Users get direct download link for the DMG

### Testing

- **Run tests**: Use Xcode's Test navigator or Cmd+U
- **Testing framework**: Uses Swift Testing (not XCTest)
- **Test targets**: `ConsciousMonitor-Tests` (unit tests), `ConsciousMonitor-UITests` (UI tests)

### Development Workflow Best Practices

- **Warning Management**: Use `let _ = variable` pattern for intentionally unused variables
- **Enum Completeness**: Always handle all cases in switch statements or add default cases
- **Service Integration**: When adding new features, leverage existing service infrastructure rather than creating parallel systems
- **UI Consistency**: Follow established DesignSystem patterns and subtab navigation for complex settings pages
- **Build Validation**: Always test compilation after significant changes - fix warnings promptly to prevent accumulation
- **Functional Simplicity**: **Always prioritize working functionality over complex non-functional features** - start simple, build up gradually to ensure testable foundations before adding complexity

## Architecture

### Core Architecture Pattern

- **MVVM**: Model-View-ViewModel using SwiftUI's reactive programming
- **Central ViewModel**: `ActivityMonitor` serves as the primary view model tracking app activations
- **Data Layer**: `DataStorage.shared` singleton handles JSON file persistence
- **Services**: External integrations (Chrome, OpenAI) handled by dedicated service classes

### Key Components

- **ActivityMonitor.swift**: Central view model tracking app activations and context switches
- **ContentView.swift**: Main tabbed UI (Activity, Analytics, Usage Stack, AI Insights, Settings)
- **DataStorage.swift**: File-based persistence to `~/Library/Application Support/`
- **ChromeIntegration.swift**: AppleScript-based Chrome tab tracking
- **AppCategorizer.swift**: App categorization system with color coding

### Data Flow

```text
NSWorkspace notifications → ActivityMonitor → SwiftUI Views
                                   ↓
                          DataStorage (JSON files)
```

### Dependencies

- **MarkdownUI**: Markdown content rendering
- **NetworkImage**: Network image loading for favicons
- Managed via Swift Package Manager through Xcode

## Development Considerations

### Swift/macOS Compatibility

- **IMPORTANT**: Recent macOS/Swift updates have caused compatibility issues
- Always test on minimum supported macOS version (13.0+) and latest version
- See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed compatibility guidelines
- Monitor SwiftUI state mutations carefully to prevent crashes
- Keep dependencies updated but test thoroughly

### Permissions & Security

- App uses App Sandbox (see `ConsciousMonitor.entitlements` in `ConsciousMonitor/` directory)
- Requires AppleEvents permission for Chrome integration
- All data stored locally in JSON format for privacy

### Build Artifacts Management

- **Never commit**: releases/, *.dmg, built app bundles
- **Distribution**: Use GitHub Releases for DMG distribution, not git storage
- **Storage**: Build artifacts are large, platform-specific, and change frequently

### Code Patterns

- Extensive use of SwiftUI's `@ObservedObject` and `@Published` for reactive updates
- Singleton pattern for shared services (`DataStorage.shared`, `UserSettings.shared`)
- Modular UI components with reusable views like `PieChartView`, `InfoTooltip`

### Swift Concurrency Patterns
- **NotificationCenter Observer Pattern**: When using `NotificationCenter.addObserver` with closures that need to remove themselves, use weak capture to avoid Sendable warnings:

  ```swift
  // ❌ Causes Sendable warning
  var observer: NSObjectProtocol?
  observer = NotificationCenter.default.addObserver(...) { _ in
      if let observer = observer {  // Mutation after capture
          NotificationCenter.default.removeObserver(observer)
      }
  }
  
  // ✅ Correct pattern
  var observer: NSObjectProtocol?
  observer = NotificationCenter.default.addObserver(...) { [weak observer] _ in
      if let observer = observer {
          NotificationCenter.default.removeObserver(observer)
      }
  }
  ```

- **@MainActor Usage Precision**: Apply @MainActor surgically to methods needing UI access, not entire classes:

  ```swift
  // ❌ Over-broad application causes background queue conflicts
  @MainActor
  class DataExportService {
      func exportAsJSON() { /* Called from DispatchQueue.global */ }
  }
  
  // ✅ Surgical application only to UI methods
  class DataExportService {
      @MainActor func exportData() { /* Uses NSSavePanel */ }
      func exportAsJSON() { /* Can be called from any queue */ }
  }
  ```

- **Sendable Protocol for Models**: Use @unchecked Sendable for models with non-Sendable properties like NSImage:

  ```swift
  struct AppActivationEvent: Identifiable, Codable, @unchecked Sendable {
      var appIcon: NSImage? // NSImage is not Sendable
  }
  ```

### Design Principles

- **Prioritize Clear > Clever**: Always favor simple, predictable solutions over complex "smart" features
- Use established UI patterns (e.g., Save buttons) rather than auto-save complexity
- User control and explicit actions are preferred over implicit behaviors
- Follow macOS Human Interface Guidelines for familiar user experiences

### User Experience Patterns

- **File Export Feedback**: Always show file paths and provide "Show in Finder" options for exported files
- **Progress Indication**: Use reactive progress tracking for long-running operations (`@Published` properties)
- **Scrollable Content**: Wrap complex settings in ScrollView for accessibility
- **Professional Organization**: Use subtabs for multi-section interfaces (Export | Reports | Files pattern)
- **Complete Workflows**: Ensure features have end-to-end user flows, not just technical functionality

### Service-to-UI Integration Pattern

When connecting services to UI components:
1. **Service generates data** → Create structured data models
2. **UI triggers export** → Call service export methods with user-chosen location
3. **Success feedback** → Show file path and provide direct access (Show in Finder)
4. **Error handling** → Display specific error messages with recovery guidance

This pattern ensures complete user workflows rather than data generation without file access.

## Technical Roadmap

### High Priority: SQLite Migration (Q1 2025)

**Current State**: The application uses JSON file-based persistence through `DataStorage.swift`, which presents several challenges as the app scales and data complexity increases.

**Migration Goals**:
- **Address startup performance issues**: JSON file loading becomes slower with larger datasets, affecting app launch times
- **Enable advanced AI insights**: SQLite's querying capabilities will support complex analytics and pattern recognition for AI-powered productivity insights
- **Improve data integrity**: Replace file-based storage with ACID-compliant database transactions
- **Support complex queries**: Enable efficient data filtering, aggregation, and reporting for analytics features

**Implementation Plan**:

1. **Phase 1**: Create SQLite schema matching existing JSON data structures
   - Preserve backward compatibility with existing user data
   - Implement migration utilities to convert JSON files to SQLite database
   - Maintain `DataStorage.swift` interface while changing underlying implementation

2. **Phase 2**: Optimize data access patterns
   - Replace synchronous file I/O with asynchronous SQLite operations
   - Implement connection pooling and prepared statements for performance
   - Add database indexing for frequently queried fields (timestamps, app names)

3. **Phase 3**: Enable advanced features
   - Implement complex analytics queries for AI insights
   - Add data aggregation capabilities for improved reporting
   - Support for user-defined data retention policies

**Target Timeline**: Q1 2025
**Dependencies**: Swift SQLite library evaluation and integration
**Risk Mitigation**: Maintain JSON export functionality for data portability

**Architecture Lessons from 2025-08-03 SQLite Migration Attempt**:

**CRITICAL INSIGHT**: The SQLite migration revealed that this codebase has significant Swift 6.0 concurrency architecture debt that predates any SQLite work. Attempting to upgrade Swift versions while adding major features simultaneously creates cascading complexity.

**What Worked Well**:
- ✅ **StorageServiceProtocol abstraction** - Clean interface for backend switching
- ✅ **Migration UI infrastructure** - MigrationView and DatabaseMigrationService patterns
- ✅ **SQLiteStorageService structure** - Async/await patterns and prepared statements approach
- ✅ **Storage Coordinator pattern** - Backend switching logic is architecturally sound

**Root Problems Discovered**:
- **Mixed threading patterns**: UI classes calling storage methods from background queues
- **Unclear actor boundaries**: Singleton services without proper concurrency isolation  
- **Swift 6.0 strict concurrency**: Exposed existing architectural debt throughout the codebase
- **@MainActor over-application**: Applying class-level @MainActor instead of method-level precision

**Fresh Approach Strategies for Future Attempts**:

1. **Option A - Incremental SQLite on Swift 5.0**:
   - Keep Swift 5.0, add SQLite migration cleanly without concurrency chaos
   - Prove storage upgrade works in isolation
   - Tackle Swift 6.0 as separate, focused migration later

2. **Option B - Minimal Viable SQLite**:
   - Extract proven components: StorageServiceProtocol, basic SQLiteStorageService
   - Build incrementally without full reactive patterns initially
   - Test each layer before adding complexity

3. **Option C - Database Layer Only**:
   - Implement SQLite as pure data layer (no SwiftUI integration)
   - Keep existing JSON system as primary interface
   - SQLite runs in background for analytics/performance enhancement only

**Key Implementation Rules**:
- **Never upgrade Swift version and add major features simultaneously**
- **Start with data layer, then add reactive UI patterns incrementally**
- **Test storage operations in isolation before SwiftUI integration**
- **Apply @MainActor surgically to methods needing UI access, not entire classes**
- **Consider SQLite as enhancement rather than replacement initially**

**Technical Debt Priority**: Address Swift 6.0 concurrency architecture as separate initiative before attempting major storage migrations.

### Additional Roadmap Items

**Performance Enhancements**:
- Leverage existing `PerformanceOptimizations.swift` infrastructure
- Optimize SwiftUI view updates with database-backed reactive patterns
- Implement lazy loading for large datasets in analytics views

**AI Integration Expansion**:
- Utilize SQLite's analytical capabilities to enhance OpenAI integration
- Support for more sophisticated productivity pattern detection
- Historical trend analysis with database-powered insights

## Future Development Infrastructure

### Phase 2: Changelog Maintainer Sub-agent (Trigger: 25+ patterns in memory)
**Purpose**: Automated development knowledge maintenance and documentation
**Implementation Timeline**: When manual CLAUDE.md updates become frequent (2+ per week)

**Capabilities**:
- Automated CHANGELOG.md maintenance on significant commits
- Pattern recognition for memory system updates
- Proactive documentation suggestions when new patterns emerge
- Cross-referencing multiple memory categories for comprehensive updates
- Integration with git hooks for commit-triggered documentation updates

**Triggers for Implementation**:
- Memory system reaches 25-30 documented patterns (critical mass for automation value)
- Multiple similar fixes across different files requiring pattern documentation
- Development velocity indicates need for automated knowledge capture

### Phase 3: Pattern Recognition System (Trigger: Architectural maturity)
**Purpose**: Self-updating knowledge base with intelligent pattern detection
**Implementation Timeline**: After SQLite migration completion and performance optimization phase

**Capabilities**:
- Auto-detection of emerging patterns requiring documentation
- Integration with memory system for autonomous knowledge base updates
- Development velocity optimization through pattern analysis
- Predictive suggestions for architectural improvements based on usage patterns
- Automated code review assistance using established pattern knowledge

**Triggers for Implementation**:
- Codebase reaches architectural maturity milestones
- Established development velocity patterns provide sufficient data for analysis
- Team scaling requires more sophisticated onboarding and consistency tools

**Success Metrics**:
- Reduced time to resolve similar issues (measured against memory system)
- Decreased frequency of architectural discussions for solved problems
- Improved code consistency across development sessions

## Codebase Architecture Assessment

### Infrastructure Systems (DO NOT REMOVE)
**WARNING**: This codebase contains comprehensive infrastructure systems that may appear to be "legacy" or "unused" but are actually essential. A detailed analysis in January 2025 revealed:

#### Core Infrastructure Files
- **`SessionManager.swift`** - Complete session management system with UUID tracking, actively used by ActivityMonitor
- **`PerformanceOptimizations.swift`** - Comprehensive performance framework with caching, memoization, monitoring, and optimized views
- **`AccessibilityEnhancements.swift`** - Massive accessibility framework with VoiceOver, keyboard navigation, reduced motion, high contrast support
- **`ErrorHandling.swift`** - Complete error handling system with custom error types, alert views, loading states, and async content management
- **`SmartSwitchDetection.swift`** - Advanced switch detection algorithms with productivity metrics and intelligent context switch creation
- **`AppleScriptRunner.swift`** - Chrome integration system with AppleScript execution and error handling
- **`WindowAccessor.swift`** - Functional window access utilities

#### Architecture Quality
- **Enterprise-grade systems** with proper separation of concerns
- **Comprehensive accessibility compliance** (VoiceOver, keyboard nav, etc.)
- **Performance optimization infrastructure** (caching, memoization, lazy loading)
- **Robust error handling** throughout the application
- **Advanced analytics** with smart productivity detection
- **System integration** via AppleScript and window management

#### Refactoring Guidelines
- **Never assume files are empty** based on names or initial impressions
- **Always read complete file contents** before making removal decisions
- **Search comprehensively for usage patterns** before any deletion
- **Be extremely conservative** with established codebases
- **Recognize quality architecture** when you see it

This codebase represents exemplary application architecture and should be preserved as-is.

### File Structure

```text
ConsciousMonitor/
├── Models/           # Data structures (AppActivationEvent, ContextSwitchMetrics, etc.)
├── Views/            # SwiftUI views organized by feature
├── Services/         # External integrations and utilities
└── Assets.xcassets/  # App icons and visual resources
```

### Integration Points
- **Chrome tracking**: Requires AppleScript permission from user
- **AI features**: OpenAI API integration (user provides API key)
- **System monitoring**: Uses NSWorkspace for app activation tracking

