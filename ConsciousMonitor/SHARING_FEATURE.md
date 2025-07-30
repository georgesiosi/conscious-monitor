# FocusMonitor Social Sharing Feature

## Overview
The social sharing feature allows users to create beautiful, shareable summaries of their productivity achievements to share on social media platforms.

## Components

### Services
- **ShareableStackService**: Generates shareable data from existing analytics
- **ShareImageService**: Handles image rendering and sharing workflow

### Views
- **ShareableStackView**: SwiftUI component that renders the visual design
- **ShareConfigurationView**: User interface for customizing sharing options
- **SharePreviewView**: Live preview before sharing
- **ShareImageButton**: Quick share button component

### Data Models
- **ShareableStackTimeRange**: .today, .thisWeek, .thisMonth, .custom
- **ShareableStackFormat**: .square, .landscape, .story
- **ShareableStackPrivacyLevel**: .detailed, .categoryOnly, .minimal
- **ShareableStackData**: Contains all data needed for sharing

## Features

### Time Period Selection
- Today's achievements
- Weekly progress
- Monthly summaries
- Custom date ranges

### Format Options
- **Square (1080×1080)**: Perfect for Instagram posts
- **Landscape (1200×675)**: Great for Twitter and LinkedIn
- **Story (1080×1920)**: Ideal for Instagram Stories

### Privacy Controls
- **Detailed**: Show app names and specific metrics
- **Category Only**: Show categories but hide specific app names
- **Minimal**: Show only high-level metrics and achievements

### Key Metrics Displayed
- Focus Score (0-100%)
- Context switches count
- Deep focus sessions
- Longest focus session duration
- Productivity cost savings
- Category breakdown with percentages
- Achievement highlights

## Usage

### Quick Sharing
Simple one-tap sharing from Analytics or Stack Health tabs:
```swift
ShareImageButton(
    events: activityMonitor.activationEvents,
    contextSwitches: activityMonitor.contextSwitches,
    timeRange: .today,
    format: .square,
    privacyLevel: .detailed,
    customStartDate: nil,
    customEndDate: nil
)
```

### Advanced Configuration
Full configuration interface for customizing all options:
```swift
ShareConfigurationView(
    events: activityMonitor.activationEvents,
    contextSwitches: activityMonitor.contextSwitches
)
```

### Preview Before Sharing
Live preview with ability to adjust settings:
```swift
SharePreviewView(
    events: events,
    contextSwitches: contextSwitches,
    timeRange: .today,
    format: .square,
    privacyLevel: .detailed,
    customStartDate: nil,
    customEndDate: nil
)
```

## Integration Points

### Analytics Tab
- Share button in header next to quick stats
- Defaults to today's data with square format

### Stack Health Tab
- Share button in header
- Uses filtered data based on selected time range
- Converts SharedTimeRange to ShareableStackTimeRange

### Data Flow
1. User clicks share button
2. ShareImageService generates ShareableStackData
3. ShareableStackView renders the visual design
4. ImageRenderer converts SwiftUI view to PNG
5. Native macOS sharing options presented

## Privacy & Security
- All data processing happens locally
- Only aggregate metrics shared, no raw activity logs
- No personal identifiers or sensitive URLs
- User controls privacy level for each share
- Smart defaults err on the side of privacy

## Technical Implementation

### Requirements
- macOS 13.0+ (for ImageRenderer)
- SwiftUI with ImageRenderer support
- Existing FocusMonitor analytics data

### Dependencies
- Existing AnalyticsService
- Existing data models (AppActivationEvent, ContextSwitchMetrics)
- SwiftUI ImageRenderer
- macOS NSSharingService

### File Organization
```
Services/
├── ShareableStackService.swift    # Data generation logic
└── ShareImageService.swift        # Image rendering and sharing

Views/
├── ShareableStackView.swift       # Visual design component
├── ShareConfigurationView.swift   # Configuration interface
├── SharePreviewView.swift         # Preview interface
└── ShareImageButton.swift         # Quick share button
```

## Future Enhancements
- Additional social media format sizes
- Animated GIF export for engagement
- Scheduled sharing reminders
- Team/organization sharing features
- Achievement milestones and celebrations
- Integration with calendar events for context