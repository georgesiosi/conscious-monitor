# FocusMonitor Release Checklist

Use this checklist for each release to ensure a smooth distribution process.

## Pre-Release Preparation

### Code & Version
- [ ] All features for this release are complete and tested
- [ ] Version number updated in Xcode project settings
- [ ] Build number incremented
- [ ] CHANGELOG.md updated with release notes
- [ ] README.md is up to date

### Testing
- [ ] App tested on macOS 13.0 (minimum supported version)
- [ ] App tested on latest macOS version
- [ ] All main features working:
  - [ ] App tracking works
  - [ ] Chrome tab tracking works (with permissions)
  - [ ] Data persistence works
  - [ ] Settings save correctly
  - [ ] Analytics display correctly
- [ ] No crashes or major bugs

## Build & Distribution

### Xcode Build
- [ ] Clean build folder (⇧⌘K)
- [ ] Set scheme to Release (not Debug)
- [ ] Archive created successfully
- [ ] Exported with "Direct Distribution"
- [ ] Hardened Runtime enabled
- [ ] Notarization requested

### Notarization
- [ ] Received notarization success email from Apple
- [ ] Verified notarization: `spctl -a -v /path/to/FocusMonitor.app`
- [ ] App launches without security warnings

### DMG Creation
- [ ] Run `./create-installer.sh`
- [ ] DMG created successfully
- [ ] Test DMG installation on a different Mac or clean user account
- [ ] Verify drag-to-Applications works
- [ ] Verify app launches from DMG installation

## Release

### GitHub Release
- [ ] Create git tag: `git tag -a v1.0.0 -m "Release version 1.0.0"`
- [ ] Push tag: `git push origin v1.0.0`
- [ ] Create GitHub release
- [ ] Upload DMG file
- [ ] Add release notes from CHANGELOG.md
- [ ] Publish release

### Documentation
- [ ] INSTALL.md is included and up to date
- [ ] Any new features documented
- [ ] Screenshots updated if UI changed

## Post-Release

### Verification
- [ ] Download DMG from GitHub release
- [ ] Verify download works
- [ ] Test installation from downloaded DMG
- [ ] Verify app runs correctly

### Communication
- [ ] Announcement prepared (if applicable)
- [ ] Support email/system ready for user questions
- [ ] Monitor GitHub issues for problems

## Version-Specific Notes

### v1.0.0
- Initial release
- Note any known issues:
  - 
- Special instructions:
  - 

---

## Quick Commands Reference

```bash
# Create tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Create DMG
./create-installer.sh

# Verify notarization
spctl -a -v /path/to/FocusMonitor.app

# Check code signature
codesign -dv --verbose=4 /path/to/FocusMonitor.app
```
