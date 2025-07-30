# FocusMonitor Architecture

This document outlines the architecture and design patterns used in the FocusMonitor application.

## Overview

FocusMonitor is built using SwiftUI and follows a modern, declarative UI approach. The application uses a combination of design patterns to maintain a clean, maintainable codebase.

## Design Patterns

### MVVM (Model-View-ViewModel)

The application follows the MVVM pattern:

- **Models**: Data structures like `AppActivationEvent`, `AppUsageStat`, and `ContextSwitchMetrics` in `DataModels.swift`
- **Views**: SwiftUI views like `ContentView`, `AnalyticsView`, etc.
- **ViewModels**: `ActivityMonitor` serves as the primary view model, managing state and business logic

### Observer Pattern

The app uses SwiftUI's `@ObservedObject` and `@StateObject` to implement the observer pattern, allowing views to react to changes in the data model.

### Dependency Injection

Dependencies are injected into views and services rather than created internally, making the code more testable and flexible.

## Core Components

### Data Flow

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│                 │      │                 │      │                 │
│  System Events  │─────▶│ ActivityMonitor │─────▶│     Views       │
│                 │      │                 │      │                 │
└─────────────────┘      └─────────────────┘      └─────────────────┘
```

1. System events (app activations) are captured
2. `ActivityMonitor` processes and stores these events
3. Views observe the `ActivityMonitor` and update accordingly

### File Organization

- **Core Data Models**: `DataModels.swift`
- **Main View Model**: `ActivityMonitor.swift`
- **View Files**: One file per main view (e.g., `ContentView.swift`, `AnalyticsView.swift`)
- **Utility Services**: `OpenAIService.swift`, `FaviconFetcher.swift`, etc.
- **Helper Components**: `AppCategorizer.swift`, `UserSettings.swift`, etc.

## Navigation

The app uses SwiftUI's `TabView` for primary navigation between main sections:

1. Activity (Main View)
2. Analytics
3. Usage Stack
4. AI Insights
5. Settings

## State Management

- **User Preferences**: Managed by `UserSettings` class using `@AppStorage`
- **App State**: Managed by `ActivityMonitor` using `@Published` properties
- **View State**: Managed within views using `@State` and `@Binding`

## Data Persistence

The application uses a combination of:

- **UserDefaults**: For user settings via `@AppStorage`
- **In-memory Storage**: For current session data
- **File Storage**: For longer-term data persistence (app usage history)

## External Services Integration

- **OpenAI API**: Used for AI-powered insights via `OpenAIService`

## UI Architecture

The UI follows a hierarchical structure:

- **Tab Container**: `ContentView` with `TabView`
- **Main Views**: One per tab
- **Subcomponents**: Reusable views like `PieChartView`, `EventRow`, etc.

## Performance Considerations

- **Lazy Loading**: Lists use `LazyVStack` and `List` for efficient rendering
- **Background Processing**: Heavy computations are performed in background tasks
- **Efficient Rendering**: Views are structured to minimize redraws

## Future Architecture Considerations

- **Core Data Integration**: For more robust data persistence
- **Modularization**: Breaking the app into feature modules
- **Testing Infrastructure**: Expanding unit and UI testing capabilities
