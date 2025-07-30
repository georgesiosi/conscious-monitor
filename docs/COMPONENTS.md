# FocusMonitor Components

This document outlines the key components of the FocusMonitor application and their responsibilities.

## Core Components

### ActivityMonitor

`ActivityMonitor.swift` is the central component that:
- Tracks app activations and switches
- Calculates usage statistics
- Manages the app's core data model
- Provides data to all views

Key responsibilities:
- Monitoring active application changes
- Calculating context switch metrics
- Generating app usage statistics
- Providing data for analytics and visualizations

**Refactored Architecture:**
- **ActivityMonitor.swift** - Core functionality for app activation observation
- **ActivityAnalytics.swift** - Extension with all analytics calculations
- **ChromeIntegration.swift** - Extension for Chrome tab tracking
- **SessionManager.swift** - Extension for session management
- **Models/** - Folder containing data model definitions:
  - `AppActivationEvent.swift`
  - `ContextSwitchMetrics.swift`
  - `AppUsageStat.swift`

### DataModels

`DataModels.swift` contains the core data structures:
- `AppActivationEvent`: Represents a single app activation
- `AppUsageStat`: Aggregated statistics for an app
- `ContextSwitchMetrics`: Metrics for app switches
- `SwitchType`: Categorization of switch types (rapid, normal, extended)

### UserSettings

`UserSettings.swift` manages user preferences:
- Hourly rate for financial calculations
- OpenAI API key for AI insights
- Display preferences
- User profile information

## View Components

### ContentView

`ContentView.swift` is the main container view that:
- Manages the tab navigation
- Displays the activity log
- Handles view type switching (chronological vs. by app)

### AnalyticsView

`AnalyticsView.swift` provides analytics on app usage:
- Total switches and time lost
- Financial impact calculations
- App usage breakdown charts

### SwitchAnalyticsView

`SwitchAnalyticsView.swift` focuses on context switching:
- Switch timeline visualization
- Switch type distribution
- Most common switch patterns

### UsageStackView

`UsageStackView.swift` shows app usage patterns:
- List of apps by activation count
- Chrome site breakdown (if applicable)
- App categorization

### AIInsightsView

`AIInsightsView.swift` provides AI-powered insights:
- Workstyle DNA analysis
- Productivity patterns
- Improvement suggestions

### SettingsView

`SettingsView.swift` allows configuration of:
- Financial settings (hourly rate)
- OpenAI API key
- User profile information
- Display preferences

## Utility Components

### AppCategorizer

`AppCategorizer.swift` handles app categorization:
- Assigns categories to apps (Productivity, Communication, etc.)
- Manages user-defined category mappings
- Provides category colors for visualization

### FaviconFetcher

`FaviconFetcher.swift` retrieves website favicons:
- Fetches favicons for Chrome tabs
- Caches icons for performance
- Provides fallback icons when needed

### OpenAIService

`OpenAIService.swift` handles AI analysis:
- Communicates with OpenAI API
- Formats app usage data for analysis
- Processes and formats AI responses

### PieChartView

`PieChartView.swift` is a reusable chart component:
- Renders pie/donut charts
- Handles user interactions
- Provides customization options

## Helper Components

### WindowAccessor

`WindowAccessor.swift` provides system-level window access:
- Enables floating window functionality
- Manages window positioning and behavior

### FloatingFocusView

`FloatingFocusView.swift` implements a floating mini-view:
- Shows current app and switch count
- Provides always-on-top functionality
- Minimizes UI footprint

### DualAppIconView

`DualAppIconView.swift` renders composite app icons:
- Displays Chrome with website favicon overlay
- Handles icon scaling and positioning

## Interaction Between Components

```
┌─────────────────┐
│  ActivityMonitor │◄────────────────┐
└────────┬────────┘                  │
         │                           │
         ▼                           │
┌─────────────────┐          ┌───────┴───────┐
│     Views       │──────────▶│ AppCategorizer │
└────────┬────────┘          └───────┬───────┘
         │                           │
         ▼                           ▼
┌─────────────────┐          ┌───────────────┐
│  UserSettings   │          │ Utility Services│
└─────────────────┘          └───────────────┘
```

- `ActivityMonitor` provides data to all views
- Views use `AppCategorizer` to display categorized data
- `UserSettings` configures view behavior
- Utility services support specific functionality
