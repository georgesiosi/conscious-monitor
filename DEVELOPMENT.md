# FocusMonitor Development Guide

## Swift and macOS Version Compatibility

**Important**: This project has experienced compatibility issues with recent Swift and macOS updates. Please follow these guidelines to maintain stability:

### Current Compatibility Matrix

- **macOS**: 13.0+ (Ventura and later)
- **Swift**: 5.7+
- **Xcode**: 15.0+
- **SwiftUI**: iOS 16.0+ / macOS 13.0+

### Known Compatibility Issues

1. **SwiftUI State Management**: Recent macOS updates have caused crashes in the Stack Health tab due to SwiftUI state mutation warnings being promoted to errors.

2. **NSWorkspace Changes**: macOS 14+ introduced changes to NSWorkspace behavior that may affect app activation tracking.

3. **AppleScript Permissions**: Stricter security policies in recent macOS versions require more explicit handling of AppleScript permissions for Chrome integration.

### Development Best Practices

#### Design Principles

**Clear > Clever**: Always prioritize simple, predictable solutions over complex "smart" features.

- Use established UI patterns that users already understand
- Prefer explicit user actions (Save buttons) over implicit behaviors (auto-save)
- Choose familiar patterns over innovative but confusing ones
- If a solution requires extensive documentation to understand, consider a simpler approach
- User control and clear cause-and-effect relationships should guide design decisions

#### Before Making Changes

1. **Test on Multiple macOS Versions**: Always test on the minimum supported version (macOS 13.0) and the latest available version.

2. **Check SwiftUI State Mutations**: Use the SwiftUI runtime warnings to catch state mutation issues early:
   ```bash
   # Enable SwiftUI runtime warnings
   defaults write com.apple.dt.Xcode IDESwiftUIStateMutationWarningsEnabled -bool YES
   ```

3. **Monitor Deprecation Warnings**: Swift and SwiftUI APIs deprecate rapidly. Address deprecation warnings promptly.

#### When Updating Dependencies

1. **Swift Package Manager**: Update packages cautiously and test thoroughly:
   ```bash
   # Check for package updates
   swift package show-dependencies
   ```

2. **SwiftUI Framework Changes**: Major SwiftUI updates often require code adjustments. Test all UI components after updates.

#### Debugging State Issues

Common SwiftUI state mutation patterns that cause crashes:

```swift
// ❌ Dangerous: Modifying state during view updates
@Published var data: [Item] = []

func updateData() {
    // This can cause crashes if called during view updates
    data.append(newItem)
}

// ✅ Safe: Use proper state management
@Published var data: [Item] = []

func updateData() {
    DispatchQueue.main.async {
        self.data.append(newItem)
    }
}
```

### Version Update Checklist

When updating to newer Swift/macOS versions:

- [ ] Test all TabView navigation
- [ ] Verify NSWorkspace app tracking still works
- [ ] Check AppleScript Chrome integration
- [ ] Test data persistence and loading
- [ ] Verify all SwiftUI animations and state transitions
- [ ] Test on both Intel and Apple Silicon Macs
- [ ] Check memory usage and performance
- [ ] Validate all accessibility features still work

### Framework-Specific Notes

#### Conscious Stack Design (CSD) Integration

The app implements the CSD framework for app categorization and stack health analysis. When updating Swift versions:

1. Ensure the `CSDFramework.swift` calculations remain accurate
2. Test the 5:3:1 rule compliance detection
3. Verify category usage metrics are calculated correctly

#### OpenAI Integration

The AI insights feature uses the OpenAI API and may need updates when Swift networking patterns change:

1. Test API connectivity after Swift updates
2. Verify JSON encoding/decoding still works correctly
3. Check error handling paths

### Emergency Rollback Plan

If a Swift/macOS update breaks the app:

1. **Immediate**: Revert to last known working Xcode version
2. **Short-term**: Use Xcode version pinning in CI/CD
3. **Long-term**: Create compatibility branches for different Swift versions

### Testing Strategy

#### Automated Testing

```bash
# Run unit tests
xcodebuild test -scheme FocusMonitor -destination 'platform=macOS'

# Test on specific macOS version (if available)
xcodebuild test -scheme FocusMonitor -destination 'platform=macOS,OS=13.0'
```

#### Manual Testing Checklist

- [ ] App launches successfully
- [ ] Activity tracking works
- [ ] Chrome tab tracking functional
- [ ] All tabs load without crashes
- [ ] Settings persist correctly
- [ ] Data export/import works
- [ ] AI insights generate successfully

### Resources

- [SwiftUI Release Notes](https://developer.apple.com/documentation/swiftui/swiftui_release_notes)
- [macOS Release Notes](https://developer.apple.com/documentation/macos-release-notes)
- [Xcode Release Notes](https://developer.apple.com/documentation/xcode-release-notes)

### Getting Help

If you encounter compatibility issues:

1. Check the project's GitHub Issues for similar problems
2. Test with a clean Xcode project to isolate the issue
3. Document the specific error messages and system versions
4. Consider reaching out to the Swift community forums

---

**Remember**: Stability is more important than being on the cutting edge. Only update when necessary and always test thoroughly.