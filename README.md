# FocusMonitor

FocusMonitor is a macOS application designed to track and analyze your app usage patterns, helping you understand your work habits and improve productivity by reducing context switching.

## Overview

By tracking active applications and Chrome tab switches, FocusMonitor provides insights into your focus and potential distractions, storing this activity for historical review. The app helps you understand how you spend your time across different applications and browser tabs through detailed analytics.

## Features

- **Application Activity Tracking**: Monitors which application is currently active in real-time
- **Chrome Tab Tracking**: When Google Chrome is active, tracks the title and URL of the currently active tab
- **Persistent Storage**: Saves all activity events to a local JSON file, preserving your history across app launches
- **Switch Frequency**: Displays a count of application switches within the last 5 minutes
- **Activity History**: Shows a list of recent application and tab activations with timestamps
- **Analytics Dashboard**: Visualizes your app usage patterns with charts and statistics
- **Context Switch Analysis**: Identifies rapid context switches that may impact productivity
- **Usage Stack**: Shows a breakdown of your most frequently used applications
- **AI Insights**: Provides AI-powered analysis of your work habits (requires OpenAI API key)
- **Customizable Settings**: Configure hourly rates for financial impact calculations

## Screenshots

![FocusMonitor Main Screen](screenshots/main_screen.png)
*Main activity tracking screen showing recent app activations*

![Analytics View](screenshots/analytics.png)
*Analytics dashboard with context switching metrics*

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15 or later (for building)
- Google Chrome (for tab tracking functionality)

## Installation

### Download (Recommended)

Download the latest version directly from [GitHub Releases](https://github.com/georgesiosi/cs-monorepo/releases):

1. **Download**: Get the latest `FocusMonitor-vX.X.X.dmg` file
2. **Install**: Open the DMG and drag FocusMonitor to your Applications folder
3. **First Launch**: Right-click the app → "Open" to bypass security warnings
4. **Permissions**: Allow Chrome integration when prompted for full functionality

### Building from Source

1. **Clone the Repository**:
   ```bash
   git clone [URL_OF_YOUR_GIT_REPOSITORY]
   cd FocusMonitor
   ```

2. **Open in Xcode**:
   Open the `FocusMonitor.xcodeproj` file in Xcode.

3. **Select Target and Run**:
   - Choose the `FocusMonitor` scheme and "My Mac" (or your Mac's name) as the destination
   - Click the "Run" button (play icon) in the Xcode toolbar

## Usage

Upon launching, FocusMonitor will immediately begin tracking application activations.

### Main Window
The main window displays:
- The total number of application switches in the last 5 minutes
- A list of recent application and tab activations, including timestamps, app names, and Chrome tab details (if applicable)

### Chrome Tab Tracking
To enable Chrome tab tracking:
- The first time Chrome becomes active while FocusMonitor is running, you may be prompted by macOS to allow FocusMonitor to control Google Chrome
- You must **Allow** this for tab tracking to work
- This permission can be managed later in `System Settings` > `Privacy & Security` > `Automation`

### Data Storage
Activity data is automatically saved to a JSON file located in your Mac's Application Support directory (typically `~/Library/Application Support/[YourBundleID]/activity_events.json`).

## Documentation

- [Setup Guide](docs/SETUP.md) - Detailed installation and configuration instructions
- [Architecture](docs/ARCHITECTURE.md) - Technical architecture and design patterns
- [Components](docs/COMPONENTS.md) - Key components and their responsibilities
- [Development Guide](DEVELOPMENT.md) - Swift/macOS compatibility and development best practices
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Solutions to common issues

## Framework Integration

FocusMonitor is built on the **Conscious Stack Design (CSD)** framework, which helps users develop awareness of their digital behavior patterns. The app implements the CSD 5:3:1 rule for optimal tool stack management:

- **5**: Maximum tools per category
- **3**: Active tools at any time  
- **1**: Primary tool (60%+ usage)

Learn more about CSD at [consciousstack.com](https://consciousstack.com). The future enterprise-ready CSTACK platform will be available at [cstack.ai](https://cstack.ai).

## Future Enhancements

- Enhanced LLM integration for querying activity patterns
- More detailed analytics and visualizations
- Improved UI for managing API keys and settings

## License

This project is licensed under the MIT License - see the LICENSE file for details.
