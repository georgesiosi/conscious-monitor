# Free Distribution Guide - Test with Family & Friends

This guide shows you how to distribute FocusMonitor without a paid Apple Developer account.

## Step 1: Build Your App for Release

### In Xcode:
1. Open `FocusMonitor.xcodeproj`
2. Select "FocusMonitor" scheme at the top
3. Select "My Mac" as the destination (not "Any Mac")
4. Go to `Product → Scheme → Edit Scheme`
5. Select "Run" on the left, then "Info" tab
6. Change "Build Configuration" to "Release"
7. Click "Close"

### Build the App:
1. Clean: `Product → Clean Build Folder` (⇧⌘K)
2. Build: `Product → Build` (⌘B)

## Step 2: Locate Your Built App

After building, find your app:

1. In Xcode, go to `Product → Show Build Folder in Finder`
2. Navigate to `Products/Release/FocusMonitor.app`
3. Alternatively, right-click on "FocusMonitor.app" in Xcode's Products folder and select "Show in Finder"

## Step 3: Create a ZIP for Distribution

1. Right-click on `FocusMonitor.app`
2. Select "Compress FocusMonitor"
3. This creates `FocusMonitor.zip`

## Step 4: Share with Your Wife

You can share the ZIP file via:
- AirDrop (easiest for Mac to Mac)
- iCloud Drive
- Email
- USB drive
- Shared folder

## Step 5: Installation Instructions for Your Wife

Send these instructions along with the app:

---

### Installing FocusMonitor

1. **Download and unzip** the FocusMonitor.zip file
2. **Move FocusMonitor** to your Applications folder
3. **First time opening** (IMPORTANT):
   - Don't double-click the app!
   - Instead, right-click on FocusMonitor
   - Select "Open" from the menu
   - You'll see a security warning
   - Click "Open" to confirm

4. **Grant Permissions**:
   - When prompted, allow Accessibility access
   - Go to System Settings → Privacy & Security → Accessibility
   - Make sure FocusMonitor is checked

5. **Optional**: For Chrome tab tracking:
   - Go to System Settings → Privacy & Security → Screen Recording
   - Add and check FocusMonitor

The app will now track your application usage and help you understand your focus patterns!

---

## Alternative: Command Line Build (Optional)

If you prefer building from command line:

```bash
# Navigate to your project
cd /Users/georgesiosi/Documents/GitHub/FocusMonitor

# Build for release
xcodebuild -project FocusMonitor.xcodeproj \
           -scheme FocusMonitor \
           -configuration Release \
           -derivedDataPath build \
           clean build

# Your app will be in:
# build/Build/Products/Release/FocusMonitor.app

# Create ZIP
cd build/Build/Products/Release/
zip -r ~/Desktop/FocusMonitor.zip FocusMonitor.app
```

## Troubleshooting

### "App is damaged and can't be opened"
If this appears, she can run in Terminal:
```bash
xattr -cr /Applications/FocusMonitor.app
```

### "Developer cannot be verified"
This is expected without notarization. Just right-click → Open → Open.

### Permissions not working
Make sure to fully quit and restart the app after granting permissions.

## Next Steps

Once you've tested with family and friends:
- Gather feedback
- Fix any issues
- Consider the $99/year Apple Developer account for wider distribution
- Or continue with free distribution via GitHub

This method is perfect for testing with a small group before investing in the developer account!
