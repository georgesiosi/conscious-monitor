# Quick Start: Distributing FocusMonitor

## 🚀 Fastest Path to Distribution

### Prerequisites
1. Sign up for a free Apple Developer account at https://developer.apple.com
2. Have Xcode installed and updated

### Step 1: Prepare Your App (5 minutes)
1. Open `FocusMonitor.xcodeproj` in Xcode
2. Click on the project, then the FocusMonitor target
3. In "Signing & Capabilities":
   - Check "Automatically manage signing"
   - Select your Team (your Apple ID)
   - Change Bundle Identifier from `gsd.FocusMonitor-v0` to something unique like `com.yourname.focusmonitor`

### Step 2: Archive & Export (10-15 minutes)
1. Select "Any Mac" as the build destination
2. Clean: `Product → Clean Build Folder` (⇧⌘K)
3. Archive: `Product → Archive`
4. When Organizer opens:
   - Click "Distribute App"
   - Choose "Direct Distribution"
   - Check "Notarize app" ✅
   - Sign in with your Apple ID
   - Export to your Desktop

### Step 3: Wait for Notarization (5-30 minutes)
- Apple will email you when complete
- You can check status in Xcode's Organizer

### Step 4: Create Installer (2 minutes)
```bash
# Install create-dmg if needed
brew install create-dmg

# Copy your exported app to dist folder
mkdir -p dist
cp -r ~/Desktop/FocusMonitor.app dist/

# Create the DMG
./create-installer.sh
```

### Step 5: Distribute (5 minutes)
1. Test the DMG on your Mac first
2. Upload to GitHub Releases:
   ```bash
   # Create and push a tag
   git tag -a v1.0.0 -m "First release"
   git push origin v1.0.0
   ```
3. Go to GitHub → Releases → Create new release
4. Upload your DMG from `dist/FocusMonitor-1.0.0.dmg`

## 📋 Pre-Flight Checklist
- [ ] Bundle ID changed from `gsd.FocusMonitor-v0`
- [ ] Signing configured with your Apple ID
- [ ] App archived and exported
- [ ] Notarization complete
- [ ] DMG created and tested
- [ ] INSTALL.md is ready for users

## 🎯 Total Time: ~30-45 minutes

## 💡 Tips
- First time notarization might take longer
- Test the DMG on another user account or Mac if possible
- Keep your Apple ID credentials handy
- The free developer account is sufficient for notarization

## 🆘 Common Issues

### "Unable to notarize"
- Make sure you're signed into Xcode with your Apple ID
- Check that Hardened Runtime is enabled (it should be by default)

### "Create-dmg command not found"
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install create-dmg
```

### "App damaged" error for users
- This means notarization failed or wasn't completed
- Check your email for notarization status
- Re-export with notarization enabled

## 🎉 Success!
Once complete, users can download your app, drag it to Applications, and start tracking their focus!
