# Browser Tab Tracking Research for macOS - 2025

## Executive Summary

This research document examines various approaches for tracking active tabs across multiple browsers on macOS. The findings reveal a fragmented landscape where different browsers provide varying levels of automation support, from robust AppleScript integration to modern WebDriver protocols.

## Current FocusMonitor Implementation

The current FocusMonitor app uses AppleScript to track Chrome tabs via `AppleScriptRunner.swift` and `ChromeIntegration.swift`. This implementation:

- Uses AppleScript to query Chrome's active tab title and URL
- Runs asynchronously to avoid blocking the UI
- Includes error handling for Chrome-specific issues
- Fetches favicons for enhanced UI display

## Browser-Specific Approaches

### 1. Google Chrome ✅ Excellent Support

**AppleScript Support**: Comprehensive and reliable
- **Current Implementation**: Working in FocusMonitor
- **Capabilities**: Get tab title, URL, switch tabs, create new tabs
- **Reliability**: High - Chrome has maintained AppleScript support consistently
- **Code Example**: Already implemented in `AppleScriptRunner.swift`

**Alternative Methods**:
- Chrome DevTools Protocol (CDP) for advanced automation
- WebDriver/Selenium for cross-platform testing
- Chrome Extensions for deeper integration

### 2. Safari ✅ Excellent Support

**AppleScript Support**: Best-in-class native integration
- **Capabilities**: Full tab control, URL/title retrieval, tab switching
- **Reliability**: Highest - Native macOS integration
- **Performance**: Excellent - No external dependencies
- **Security**: Native macOS permissions model

**Implementation Example**:
```applescript
tell application "Safari"
    if (count of windows) > 0 then
        set currentTab to current tab of front window
        set tabTitle to name of currentTab
        set tabURL to URL of currentTab
        return tabTitle & "\n" & tabURL
    end if
end tell
```

**Alternative Methods**:
- WebDriver support via Safari Technology Preview
- Safari Extensions for custom functionality
- NSAccessibility API integration

### 3. Firefox ❌ Limited Support

**AppleScript Support**: Removed since version 3.6
- **Status**: No native AppleScript support
- **Workarounds**: System Events UI scripting (unreliable)
- **Recommendation**: Use WebDriver/Selenium for automation

**Alternative Methods**:
- **Selenium WebDriver**: Full automation capability
- **Playwright**: Modern cross-browser automation
- **Firefox Extensions**: Custom solutions for specific needs
- **UI Automation**: System Events (fragile)

**WebDriver Implementation**: Recommended approach for Firefox
```python
from selenium import webdriver
from selenium.webdriver.firefox.service import Service

service = Service('/path/to/geckodriver')
driver = webdriver.Firefox(service=service)
```

### 4. Arc Browser ✅ Good Support

**AppleScript Support**: Solid implementation with unique features
- **Capabilities**: Space management, tab control, URL/title retrieval
- **Unique Features**: Workspace/Space integration
- **Community**: Active development of automation tools
- **Reliability**: Good - The Browser Company maintains AppleScript API

**Implementation Resources**:
- Official Raycast extension with AppleScript examples
- Node.js library: `arc-applescript-api`
- Community tools and automation scripts

**Example Usage**:
```applescript
tell application "Arc"
    tell front window
        set currentTab to active tab
        set tabTitle to title of currentTab
        set tabURL to URL of currentTab
    end tell
end tell
```

### 5. Brave Browser ⚠️ Limited Support

**AppleScript Support**: Removed/minimal
- **Status**: No comprehensive AppleScript support
- **WebDriver**: Full support via ChromeDriver (Chromium-based)
- **Recommendation**: Use WebDriver for automation

**WebDriver Implementation**:
```python
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

options = Options()
options.binary_location = "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
driver = webdriver.Chrome(options=options)
```

### 6. Opera Browser ❌ No Support

**AppleScript Support**: Removed
- **Status**: No AppleScript support in modern versions
- **WebDriver**: Use OperaChromiumDriver
- **Recommendation**: WebDriver only

### 7. Microsoft Edge ⚠️ Limited Support

**AppleScript Support**: Basic functionality
- **Capabilities**: Open URLs, basic tab operations
- **Reliability**: Limited compared to Safari/Chrome
- **WebDriver**: Full support via EdgeDriver

**Basic AppleScript**:
```applescript
tell application "Microsoft Edge"
    open location "https://example.com"
end tell
```

### 8. Dia Browser 🔄 Beta/Emerging

**Status**: Beta release from The Browser Company
- **AppleScript Support**: Unknown - too new for comprehensive testing
- **AI Integration**: Focus on AI-powered tab management
- **Automation**: Likely similar to Arc given same company
- **Recommendation**: Monitor development, test when stable

## Universal/Cross-Browser Approaches

### 1. Chrome DevTools Protocol (CDP)

**Support**: Chromium-based browsers (Chrome, Brave, Edge, Opera)
- **Capabilities**: Real-time tab tracking, network monitoring, performance metrics
- **Implementation**: WebSocket-based protocol
- **Use Case**: Advanced automation and debugging

**Benefits**:
- Real-time tab events
- Rich metadata (network, performance)
- Standardized across Chromium browsers

**Limitations**:
- Chromium-only
- Complex implementation
- Not designed for stable automation

### 2. WebDriver/Selenium

**Support**: All major browsers
- **Standardization**: W3C WebDriver standard
- **Cross-platform**: Works on Windows, macOS, Linux
- **Ecosystem**: Extensive tooling and libraries

**Implementation Example**:
```python
from selenium import webdriver
from selenium.webdriver.common.by import By

# Works with Chrome, Firefox, Safari, Edge
driver = webdriver.Chrome()  # or Firefox(), Safari(), Edge()
driver.get("https://example.com")
title = driver.title
url = driver.current_url
```

### 3. Playwright

**Support**: Chrome, Firefox, Safari, Edge
- **Modern**: Built for modern web applications
- **Performance**: Faster than Selenium
- **Features**: Auto-wait, network interception, mobile emulation

### 4. macOS Accessibility APIs

**Support**: All browsers (with limitations)
- **API**: NSAccessibility protocol
- **Capabilities**: UI element inspection and interaction
- **Limitations**: Browser-specific implementation differences

**Current Status**:
- Safari/Chrome: Good NSAccessibility support
- Firefox: Limited accessibility exposure
- Others: Varies by implementation

**Challenges**:
- Inconsistent role mappings across browsers
- Limited tab-specific information
- Requires accessibility permissions

## Technical Constraints & Limitations

### 1. Security & Permissions

**AppleScript Requirements**:
- Accessibility permissions for System Events
- App-specific permissions for browser automation
- User consent for automation features

**WebDriver Requirements**:
- Browser-specific drivers (chromedriver, geckodriver, etc.)
- Network access for WebDriver communication
- Browser developer mode enablement

### 2. Reliability Issues

**AppleScript Challenges**:
- Browser updates can break scripts
- Version compatibility issues
- Asynchronous execution complexity

**WebDriver Challenges**:
- Driver version compatibility
- Browser update cycles
- Network dependency

### 3. Performance Considerations

**AppleScript**: 
- Lightweight for simple operations
- Can be slow for complex automation
- Blocking nature requires careful threading

**WebDriver**:
- Higher overhead due to browser automation
- Network latency for remote operations
- Memory usage for browser instances

## Recommendations for FocusMonitor

### Immediate Implementation (High Priority)

1. **Extend Current AppleScript Approach**:
   - Add Safari support using existing AppleScript infrastructure
   - Implement Arc browser support
   - Create fallback mechanisms for failed AppleScript calls

2. **Browser Detection System**:
   - Detect installed browsers automatically
   - Prioritize browsers based on automation capabilities
   - Graceful degradation for unsupported browsers

### Medium-Term Implementation

1. **WebDriver Integration**:
   - Add Selenium WebDriver support for Firefox
   - Implement Chrome DevTools Protocol for advanced Chrome features
   - Create unified interface for multiple automation methods

2. **Browser Extension Strategy**:
   - Develop lightweight browser extensions for unsupported browsers
   - Use extensions for enhanced tab metadata
   - Implement opt-in system for users

### Long-Term Strategy

1. **Accessibility API Integration**:
   - Implement NSAccessibility fallback for unsupported browsers
   - Create robust error handling and recovery
   - Optimize for performance and reliability

2. **Universal Protocol Support**:
   - Monitor WebDriver BiDi development
   - Implement future browser automation standards
   - Maintain backward compatibility

## Implementation Priority Matrix

| Browser | Current Priority | Complexity | User Impact |
|---------|------------------|------------|-------------|
| Chrome | ✅ Complete | Low | High |
| Safari | 🔥 High | Low | High |
| Arc | 🔥 High | Medium | Medium |
| Firefox | 📋 Medium | High | Medium |
| Edge | 📋 Medium | Medium | Low |
| Brave | 📋 Medium | Medium | Low |
| Opera | ❌ Low | High | Low |
| Dia | ⏳ Monitor | Unknown | Unknown |

## Code Architecture Recommendations

### 1. Protocol Abstraction Layer

```swift
protocol BrowserTabTracker {
    func getActiveTab() async -> Result<TabInfo, BrowserError>
    func getAllTabs() async -> Result<[TabInfo], BrowserError>
    func isSupported() -> Bool
}

class AppleScriptTracker: BrowserTabTracker { }
class WebDriverTracker: BrowserTabTracker { }
class AccessibilityTracker: BrowserTabTracker { }
```

### 2. Browser Manager

```swift
class BrowserManager {
    private let trackers: [BrowserType: BrowserTabTracker]
    
    func getActiveTab(for browser: BrowserType) async -> Result<TabInfo, BrowserError> {
        guard let tracker = trackers[browser] else {
            return .failure(.unsupportedBrowser)
        }
        return await tracker.getActiveTab()
    }
}
```

### 3. Fallback Chain

```swift
class FallbackTabTracker: BrowserTabTracker {
    private let primaryTracker: BrowserTabTracker
    private let fallbackTracker: BrowserTabTracker
    
    func getActiveTab() async -> Result<TabInfo, BrowserError> {
        let result = await primaryTracker.getActiveTab()
        switch result {
        case .success:
            return result
        case .failure:
            return await fallbackTracker.getActiveTab()
        }
    }
}
```

## Conclusion

The browser automation landscape on macOS in 2025 offers multiple approaches with varying levels of support and complexity. The current AppleScript-based approach in FocusMonitor provides an excellent foundation that can be extended to support Safari and Arc browsers with minimal complexity. For broader browser support, a hybrid approach combining AppleScript, WebDriver, and accessibility APIs would provide the most comprehensive solution while maintaining reliability and performance.

The key to success lies in implementing a robust abstraction layer that can gracefully handle different automation methods and provide fallback mechanisms for unsupported browsers. Priority should be given to Safari and Arc support using AppleScript, followed by WebDriver integration for Firefox and other browsers.