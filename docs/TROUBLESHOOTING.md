# FocusMonitor Troubleshooting Guide

This guide addresses common issues you might encounter when using FocusMonitor and provides solutions.

## Startup Issues

### Application Won't Launch

**Symptoms:**
- Application icon bounces in dock but never opens
- Application immediately crashes on launch

**Solutions:**
1. Check macOS version (requires macOS 12.0+)
2. Restart your Mac
3. Reinstall the application
4. Check Console.app for crash logs related to FocusMonitor

### Missing Permissions

**Symptoms:**
- App launches but doesn't track application switches
- Error message about missing permissions

**Solutions:**
1. Go to System Preferences > Privacy & Security > Accessibility
2. Ensure FocusMonitor is checked
3. If it's already checked, uncheck and recheck it
4. Restart the application

## Tracking Issues

### Not Detecting App Switches

**Symptoms:**
- No new entries appear in the activity log
- Switch count doesn't increase

**Solutions:**
1. Verify permissions (see above)
2. Check if the app is running in the background (menu bar icon should be visible)
3. Restart the application
4. If using a virtual machine or remote desktop, note that tracking may be limited

### Chrome Tab Tracking Not Working

**Symptoms:**
- Chrome app is tracked but individual tabs are not
- No favicons or site information appears

**Solutions:**
1. Ensure Screen Recording permission is granted
2. Restart Chrome and FocusMonitor
3. Check if Chrome is running in incognito mode (not supported)
4. Verify you're using a supported Chrome version

## Performance Issues

### High CPU Usage

**Symptoms:**
- Fan running at high speed
- System slowdown
- Battery draining quickly

**Solutions:**
1. Check Activity Monitor to confirm FocusMonitor is using high CPU
2. Restart the application
3. Reduce the data collection period in Settings
4. Update to the latest version

### Memory Leaks

**Symptoms:**
- Increasing memory usage over time
- System slowdown after extended use

**Solutions:**
1. Restart the application periodically
2. Update to the latest version
3. Reduce the data retention period in Settings

## Data Issues

### Missing Historical Data

**Symptoms:**
- Analytics shows incomplete data
- Historical data is missing

**Solutions:**
1. Check if data retention settings have been changed
2. Verify the application has been running continuously
3. Check if data files are corrupted (reinstall may be required)

### Incorrect Statistics

**Symptoms:**
- Analytics show unrealistic numbers
- Financial calculations seem wrong

**Solutions:**
1. Verify your hourly rate is set correctly
2. Check if the time lost per switch setting is appropriate for your workflow
3. Reset statistics from Settings > Advanced (if available)

## AI Insights Issues

### AI Analysis Not Working

**Symptoms:**
- "Analyze My App Usage" button doesn't produce results
- Error messages when requesting analysis

**Solutions:**
1. Verify your OpenAI API key is entered correctly
2. Check your OpenAI account has sufficient credits
3. Ensure you have internet connectivity
4. Try again later (OpenAI API may have rate limits or be temporarily unavailable)

### Poor Quality Insights

**Symptoms:**
- Generic or irrelevant insights
- Analysis doesn't reflect your actual usage patterns

**Solutions:**
1. Use the app more to generate more data for analysis
2. Fill out the "About Me" and "My Goals" sections in Settings
3. Provide feedback on insights to help improve future analyses

## UI Issues

### Layout Problems

**Symptoms:**
- Text or elements appear cut off
- Content doesn't fit properly in windows
- Overlapping UI elements

**Solutions:**
1. Ensure you're using the minimum supported resolution
2. Try resizing the window
3. Update to the latest version

### Dark Mode Issues

**Symptoms:**
- Poor contrast in dark mode
- Elements difficult to see

**Solutions:**
1. Try switching to light mode in System Preferences
2. Update to the latest version which may have improved dark mode support

## Uninstallation Issues

### Can't Fully Remove

**Symptoms:**
- App data persists after uninstallation
- Preferences remain after reinstall

**Solutions:**
1. Follow the complete uninstallation steps in the [Setup Guide](SETUP.md#uninstallation)
2. Manually remove preference files:
   ```bash
   defaults delete com.yourdomain.FocusMonitor
   rm -rf ~/Library/Application\ Support/FocusMonitor/
   ```

## Still Having Issues?

If you're still experiencing problems after trying these solutions:

1. Check for updates - your issue may be fixed in a newer version
2. Search the [GitHub Issues](https://github.com/yourusername/FocusMonitor/issues) to see if others have reported the same problem
3. Submit a new issue with detailed information about your problem, including:
   - macOS version
   - FocusMonitor version
   - Steps to reproduce
   - Screenshots if applicable
   - Any error messages
