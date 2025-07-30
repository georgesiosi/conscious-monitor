# FocusMonitor Setup Guide

This guide provides instructions for setting up and running the FocusMonitor application.

## System Requirements

- macOS 12.0 (Monterey) or later
- Xcode 14.0 or later (for development)
- Swift 5.7 or later
- Minimum 4GB RAM
- 100MB free disk space

## Installation

### Option 1: Download the Release

1. Go to the [Releases](https://github.com/yourusername/FocusMonitor/releases) page
2. Download the latest `.dmg` file
3. Open the `.dmg` file
4. Drag FocusMonitor to your Applications folder
5. Open FocusMonitor from your Applications folder

### Option 2: Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/FocusMonitor.git
   cd FocusMonitor
   ```

2. Open the project in Xcode:
   ```bash
   open FocusMonitor.xcodeproj
   ```

3. Select your development team in the Signing & Capabilities tab

4. Build and run the application (⌘+R)

## First-Time Setup

When you first launch FocusMonitor, you'll need to:

1. Grant necessary permissions:
   - Accessibility permissions (for tracking active applications)
   - Screen recording permissions (for Chrome tab tracking, if needed)

2. Configure your settings:
   - Set your hourly rate for financial impact calculations
   - Add your OpenAI API key if you want to use AI insights
   - Customize other preferences as needed

## Permissions

### Accessibility Permissions

FocusMonitor needs accessibility permissions to track which applications are active:

1. When prompted, click "Open System Preferences"
2. Go to Privacy & Security > Accessibility
3. Check the box next to FocusMonitor
4. Restart the application

### Screen Recording (Optional)

For enhanced Chrome tab tracking:

1. Go to System Preferences > Privacy & Security > Screen Recording
2. Check the box next to FocusMonitor
3. Restart the application

## Configuration

### OpenAI API Key (Optional)

To use the AI Insights feature:

1. Go to [OpenAI](https://platform.openai.com/account/api-keys) and create an API key
2. In FocusMonitor, go to the Settings tab
3. Enter your API key in the designated field

### Hourly Rate

To calculate the financial impact of context switching:

1. Go to the Settings tab
2. Enter your approximate hourly rate
3. FocusMonitor will use this to estimate the cost of time lost to context switching

## Running in Background

FocusMonitor can run in the background to continuously track your app usage:

1. Launch FocusMonitor
2. The app will continue tracking even when the main window is closed
3. Access the app from the menu bar icon

## Troubleshooting

If you encounter issues during setup, see the [Troubleshooting Guide](TROUBLESHOOTING.md).

## Uninstallation

To uninstall FocusMonitor:

1. Quit the application
2. Move FocusMonitor from Applications to Trash
3. Empty Trash

To remove all data:

1. Delete the application preferences:
   ```bash
   defaults delete com.yourdomain.FocusMonitor
   ```

2. Remove any saved data:
   ```bash
   rm -rf ~/Library/Application\ Support/FocusMonitor/
