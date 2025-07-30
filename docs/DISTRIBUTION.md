# FocusMonitor Distribution Guide

This guide walks you through the process of distributing FocusMonitor to other users.

## Prerequisites

1. **Apple Developer Account** (for notarization)
   - You need at least a free Apple Developer account
   - For Mac App Store distribution, you need a paid account ($99/year)
   - Sign up at: https://developer.apple.com

2. **Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```

3. **Your Apple ID credentials ready**

## Step 1: Configure Your App for Distribution

### 1.1 Update Bundle Identifier

1. Open your project in Xcode
2. Select the FocusMonitor target
3. Go to "Signing & Capabilities"
4. Change Bundle Identifier to something unique (e.g., `com.yourname.focusmonitor`)

### 1.2 Set Up Code Signing

1. In "Signing & Capabilities":
   - Check "Automatically manage signing"
   - Select your Team (your Apple Developer account)
   - Xcode will create provisioning profiles automatically

### 1.3 Add Required Entitlements

Since FocusMonitor accesses Chrome and monitors system events, ensure these entitlements are set:

1. Click "+" in Signing & Capabilities
2. Add these capabilities if not already present:
   - **App Sandbox** (if distributing via App Store)
   - For direct distribution, you might want to disable App Sandbox for full functionality

## Step 2: Archive Your App

1. In Xcode, ensure you have "Any Mac" or "My Mac" selected as the build destination
2. Clean the build folder: `Product → Clean Build Folder` (⇧⌘K)
3. Build the archive: `Product → Archive`
4. Wait for the build to complete - the Organizer window will open

## Step 3: Export for Direct Distribution

### 3.1 Export from Organizer

1. In the Organizer window, select your archive
2. Click "Distribute App"
3. Choose "Direct Distribution"
4. Options to select:
   - ✅ App Sandbox (if you added it)
   - ✅ Hardened Runtime (required for notarization)
   - ✅ Notarize app (important!)
5. Click "Next" and sign in with your Apple ID when prompted
6. Choose "Upload" to send to Apple for notarization
7. Click "Export" and choose a location to save

### 3.2 Wait for Notarization

- Apple will email you when notarization is complete (usually 5-30 minutes)
- You can check status in Xcode's Organizer window

## Step 4: Create a DMG Installer

### 4.1 Install create-dmg

```bash
brew install create-dmg
```

### 4.2 Create the DMG

Save this script as `create-installer.sh` in your project root:

```bash
#!/bin/bash

# Configuration
APP_NAME="FocusMonitor"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
VOLUME_NAME="${APP_NAME} ${VERSION}"
SOURCE_APP="dist/${APP_NAME}.app"  # Path to your exported .app

# Create a dist directory if it doesn't exist
mkdir -p dist

# Remove old DMG if it exists
rm -f "dist/${DMG_NAME}"

# Create DMG
create-dmg \
  --volname "${VOLUME_NAME}" \
  --volicon "${SOURCE_APP}/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "${APP_NAME}.app" 150 150 \
  --hide-extension "${APP_NAME}.app" \
  --app-drop-link 450 150 \
  --no-internet-enable \
  "dist/${DMG_NAME}" \
  "${SOURCE_APP}"

echo "DMG created at: dist/${DMG_NAME}"
```

Make it executable:
```bash
chmod +x create-installer.sh
```

### 4.3 Run the Script

```bash
./create-installer.sh
```

## Step 5: Distribute Your App

### Option A: GitHub Releases (Recommended)

1. Create a new release on GitHub:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

2. Go to your repo on GitHub → Releases → "Draft a new release"
3. Select your tag
4. Upload your DMG file
5. Add release notes
6. Publish release

### Option B: Direct Download

Host your DMG file on:
- Your website
- Dropbox/Google Drive (with direct download link)
- S3 bucket

## Step 6: Create Installation Instructions

Create a simple README for users:

```markdown
# Installing FocusMonitor

1. Download FocusMonitor.dmg
2. Double-click the DMG file
3. Drag FocusMonitor to your Applications folder
4. Eject the DMG
5. First time running:
   - Right-click FocusMonitor in Applications
   - Select "Open"
   - Click "Open" in the security dialog
6. Grant necessary permissions when prompted:
   - Accessibility access (for monitoring active apps)
   - Screen Recording (if needed for Chrome tab titles)
```

## Step 7: Auto-Updates (Optional but Recommended)

### Using Sparkle Framework

1. Add Sparkle to your project:
   - File → Add Package Dependencies
   - Enter: `https://github.com/sparkle-project/Sparkle`
   - Add to your target

2. Set up an appcast XML file on your server
3. Configure your app to check for updates

## Troubleshooting

### Notarization Issues

If notarization fails:
1. Check the error log in Xcode Organizer
2. Common issues:
   - Missing hardened runtime
   - Unsigned frameworks
   - Invalid entitlements

### "App is Damaged" Error

If users see this:
1. Ensure the app is properly notarized
2. Have users run: `xattr -cr /Applications/FocusMonitor.app`

### Permissions Issues

Create a help document explaining how to grant:
- Accessibility permissions: System Preferences → Security & Privacy → Privacy → Accessibility
- Screen Recording (if needed): System Preferences → Security & Privacy → Privacy → Screen Recording

## Next Steps

1. **Version Management**: Use semantic versioning (1.0.0, 1.0.1, etc.)
2. **Release Notes**: Keep a CHANGELOG.md file
3. **User Feedback**: Set up a way to collect feedback (GitHub Issues, email, etc.)
4. **Analytics**: Consider adding basic analytics to understand usage (with user consent)
5. **Crash Reporting**: Integrate a crash reporter like Sentry

## Distribution Checklist

- [ ] Bundle identifier is unique
- [ ] Version and build numbers are set
- [ ] App icon is included
- [ ] Code signing is configured
- [ ] App is archived
- [ ] App is notarized
- [ ] DMG is created
- [ ] Installation instructions are written
- [ ] Download link is live
- [ ] Tested on a clean Mac
