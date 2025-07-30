# Installing FocusMonitor

Thank you for downloading FocusMonitor! Follow these simple steps to get started.

## Installation Steps

### 1. Download FocusMonitor
Download the latest `FocusMonitor-X.X.X.dmg` file from the releases page.

### 2. Install the App
1. **Double-click** the downloaded DMG file
2. In the window that opens, **drag FocusMonitor** to the **Applications folder**
3. Wait for the copy to complete
4. **Eject** the DMG by clicking the eject button in Finder or dragging it to trash

### 3. First Launch
Since FocusMonitor is downloaded from the internet, macOS will require your approval:

1. Open your **Applications** folder
2. **Right-click** on FocusMonitor
3. Select **"Open"** from the context menu
4. Click **"Open"** in the security dialog that appears

### 4. Grant Permissions
FocusMonitor needs certain permissions to monitor your app usage:

#### Accessibility Access (Required)
1. When prompted, click **"Open System Preferences"**
2. Click the **lock icon** and enter your password
3. **Check the box** next to FocusMonitor
4. Close System Preferences

If you missed the prompt:
- Go to **System Preferences → Security & Privacy → Privacy → Accessibility**
- Add FocusMonitor by clicking the + button

#### Screen Recording (Optional - for Chrome tab titles)
If you want to track Chrome tab titles:
- Go to **System Preferences → Security & Privacy → Privacy → Screen Recording**
- Check the box next to FocusMonitor

## Troubleshooting

### "FocusMonitor is damaged and can't be opened"
This rare message can occur if the app wasn't properly downloaded. Fix:
1. Open Terminal
2. Run: `xattr -cr /Applications/FocusMonitor.app`
3. Try opening the app again

### App doesn't track anything
- Ensure you've granted Accessibility permissions
- Try quitting and restarting the app
- Check that the app is actually running (look for it in the menu bar or dock)

### Chrome tabs show as "Unknown"
- Grant Screen Recording permission as described above
- Make sure Chrome is the active window when switching to it

## Getting Started

Once installed, FocusMonitor will:
- ✅ Automatically start tracking your app usage
- ✅ Show you insights about your focus patterns
- ✅ Help you understand context switching costs
- ✅ Store all data locally on your Mac (your privacy is protected!)

## Need Help?

- Check out the [documentation](docs/README.md)
- Report issues on [GitHub](https://github.com/yourusername/FocusMonitor/issues)
- Email support: your-email@example.com

## Uninstalling

To remove FocusMonitor:
1. Quit the app
2. Drag FocusMonitor from Applications to Trash
3. Remove permissions if desired:
   - System Preferences → Security & Privacy → Privacy
   - Remove FocusMonitor from Accessibility and Screen Recording lists

Your data is stored in `~/Library/Application Support/FocusMonitor/` and can be deleted if you want to remove all traces.
