import SwiftUI
import AppKit

@MainActor
class FloatingWindowManager: NSObject, ObservableObject {
    private var floatingWindow: NSWindow?
    private var hostingView: NSHostingView<FloatingFocusBarView>?
    private weak var activityMonitor: ActivityMonitor?
    
    @Published var isFloatingWindowVisible: Bool = false
    @Published var windowPosition: CGPoint = CGPoint(x: 100, y: 100)
    @Published var windowSize: CGSize = CGSize(width: 300, height: 120)
    
    // Window behavior settings - following Sunsama-style implementation
    private let windowLevel: NSWindow.Level = .statusBar // Less intrusive than .floating
    private let minWindowSize = CGSize(width: 250, height: 80)
    private let maxWindowSize = CGSize(width: 500, height: 200)
    private let defaultWindowSize = CGSize(width: 300, height: 120)
    
    // Track user-initiated visibility changes
    private var userExplicitlyShowing = false
    
    private var isInitialized = false
    
    // Debouncing for preference saves
    private var saveTimer: Timer?
    private let saveDebounceInterval: TimeInterval = 0.5
    
    override init() {
        super.init()
        
        // Clean up any corrupted data first
        cleanupCorruptedPreferences()
        
        // Load saved window position and size
        loadWindowPreferences()
        
        // Note: Don't set up observers here - wait until app is ready
    }
    
    private func ensureInitialized() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Listen for main window focus changes
        setupMainWindowObserver()
        
        // Listen for user settings changes
        setupUserSettingsObserver()
    }
    
    deinit {
        saveTimer?.invalidate()
        // Clean up window directly without calling main actor methods
        floatingWindow?.close()
        floatingWindow = nil
        hostingView = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Window Management
    
    func createFloatingWindow(with activityMonitor: ActivityMonitor) throws {
        guard floatingWindow == nil else { return }
        
        self.activityMonitor = activityMonitor
        
        // Create the SwiftUI view
        let floatingView = FloatingFocusBarView(
            activityMonitor: activityMonitor,
            windowManager: self
        )
        
        // Create hosting view
        hostingView = NSHostingView(rootView: floatingView)
        
        // Create window with borderless, resizable style for clean Sunsama-style appearance
        floatingWindow = NSWindow(
            contentRect: NSRect(origin: windowPosition, size: windowSize),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        
        guard let window = floatingWindow else { 
            throw NSError(domain: "FloatingWindowManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create window"])
        }
        
        // Configure window properties for floating behavior
        window.contentView = hostingView
        window.level = windowLevel
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.ignoresMouseEvents = false
        
        // Set window constraints
        window.minSize = minWindowSize
        window.maxSize = maxWindowSize
        
        // Set initial position
        window.setFrameOrigin(windowPosition)
        
        // Setup window delegate
        window.delegate = self
        
        // Show window without making it key to avoid focus issues
        window.orderFront(nil)
        isFloatingWindowVisible = true
        
        print("FloatingWindowManager: Created floating window")
    }
    
    func closeFloatingWindow() {
        guard let window = floatingWindow else { return }
        
        // Save window position and size before closing
        saveWindowPreferences()
        
        window.close()
        floatingWindow = nil
        hostingView = nil
        isFloatingWindowVisible = false
        userExplicitlyShowing = false
        
        print("FloatingWindowManager: Closed floating window")
    }
    
    func toggleFloatingWindow() {
        guard let activityMonitor = activityMonitor else { return }
        
        userExplicitlyShowing = !isFloatingWindowVisible
        
        if isFloatingWindowVisible {
            closeFloatingWindow()
        } else {
            do {
                try createFloatingWindow(with: activityMonitor)
            } catch {
                print("FloatingWindowManager: Failed to create window - \(error)")
            }
        }
    }
    
    func updateWindowVisibility(shouldShow: Bool, userInitiated: Bool = false) {
        guard let window = floatingWindow else { 
            // If window doesn't exist and should show, create it
            if shouldShow, let activityMonitor = activityMonitor {
                do {
                    try createFloatingWindow(with: activityMonitor)
                } catch {
                    print("FloatingWindowManager: Failed to create window - \(error)")
                }
            }
            return 
        }
        
        if userInitiated {
            userExplicitlyShowing = shouldShow
        }
        
        // Determine if window should be shown
        let finalShouldShow: Bool
        if userInitiated {
            // User explicitly toggled, respect their choice
            finalShouldShow = shouldShow
        } else {
            // Respect user's explicit preference over auto-hide behavior
            finalShouldShow = userExplicitlyShowing || (!UserSettings.shared.floatingBarAutoHide && shouldShow)
        }
        
        if finalShouldShow && !window.isVisible {
            window.orderFront(nil)
            isFloatingWindowVisible = true
        } else if !finalShouldShow && window.isVisible {
            window.orderOut(nil)
            isFloatingWindowVisible = false
        }
    }
    
    // MARK: - Window Preferences with NSValue wrappers
    
    private func cleanupCorruptedPreferences() {
        // Remove any existing corrupted data that might cause NSPoint storage errors
        let keys = ["FloatingWindowPosition", "FloatingWindowSize"]
        
        for key in keys {
            if let existing = UserDefaults.standard.object(forKey: key),
               !(existing is NSValue) {
                UserDefaults.standard.removeObject(forKey: key)
                print("FloatingWindowManager: Cleaned up corrupted data for key: \(key)")
            }
        }
    }
    
    private func loadWindowPreferences() {
        // Load position using NSValue wrapper for proper NSKeyedArchiver support
        if let positionValue = UserDefaults.standard.object(forKey: "FloatingWindowPosition") as? NSValue {
            windowPosition = positionValue.pointValue
        }
        
        // Load size using NSValue wrapper
        if let sizeValue = UserDefaults.standard.object(forKey: "FloatingWindowSize") as? NSValue {
            windowSize = sizeValue.sizeValue
        }
    }
    
    private func saveWindowPreferences() {
        guard let window = floatingWindow else { return }
        
        let position = window.frame.origin
        let size = window.frame.size
        
        // Save using NSValue wrappers for proper persistence
        let positionValue = NSValue(point: position)
        let sizeValue = NSValue(size: size)
        
        // Verify these are valid NSValue objects before setting
        guard positionValue.pointValue == position,
              sizeValue.sizeValue == size else {
            print("FloatingWindowManager: Invalid NSValue conversion")
            return
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(positionValue, forKey: "FloatingWindowPosition")
        UserDefaults.standard.set(sizeValue, forKey: "FloatingWindowSize")
        
        // Update published properties on main thread to avoid recursion
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Only update if the values have actually changed to prevent recursive saves
            if self.windowPosition != position {
                self.windowPosition = position
            }
            if self.windowSize != size {
                self.windowSize = size
            }
        }
        
        print("FloatingWindowManager: Saved window preferences - position: \(position), size: \(size)")
    }
    
    // MARK: - Observers
    
    private func setupMainWindowObserver() {
        // Listen for main window becoming active/inactive
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeMainNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                if let window = notification.object as? NSWindow,
                   window.title == "Conscious Monitor App" {
                    // Main window became active - hide floating window if auto-hide is enabled
                    if UserSettings.shared.floatingBarAutoHide {
                        self?.updateWindowVisibility(shouldShow: false)
                    }
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignMainNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                if let window = notification.object as? NSWindow,
                   window.title == "Conscious Monitor App" {
                    // Main window lost focus - show floating window if enabled
                    let shouldShow = UserSettings.shared.showFloatingFocusPanel
                    self?.updateWindowVisibility(shouldShow: shouldShow)
                }
            }
        }
    }
    
    private func setupUserSettingsObserver() {
        // Listen for changes to the floating panel setting
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                let shouldShow = UserSettings.shared.showFloatingFocusPanel
                
                if shouldShow {
                    // User enabled floating bar - show window
                    self?.updateWindowVisibility(shouldShow: true, userInitiated: true)
                } else {
                    // User disabled floating bar - hide window
                    self?.updateWindowVisibility(shouldShow: false, userInitiated: true)
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    func setActivityMonitor(_ activityMonitor: ActivityMonitor) {
        // Ensure observers are set up before proceeding
        ensureInitialized()
        
        self.activityMonitor = activityMonitor
        
        // If floating window should be shown, create it
        if UserSettings.shared.showFloatingFocusPanel {
            do {
                try createFloatingWindow(with: activityMonitor)
            } catch {
                print("FloatingWindowManager: Failed to create window in setActivityMonitor - \(error)")
            }
        }
    }
    
    func getWindowFrame() -> CGRect? {
        return floatingWindow?.frame
    }
    
    func bringToFront() {
        floatingWindow?.orderFront(nil)
    }
    
    func resizeWindow(to size: CGSize) {
        guard let window = floatingWindow else { return }
        
        let currentFrame = window.frame
        let newFrame = NSRect(
            x: currentFrame.origin.x,
            y: currentFrame.origin.y,
            width: size.width,
            height: size.height
        )
        
        window.setFrame(newFrame, display: true, animate: true)
        windowSize = size
        saveWindowPreferences()
    }
    
    func activateMainWindow() {
        // Bring main window to front when floating bar is clicked
        if let mainWindow = NSApplication.shared.windows.first(where: { $0.title == "Conscious Monitor App" }) {
            mainWindow.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - NSWindowDelegate

extension FloatingWindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Save preferences when window closes
        saveWindowPreferences()
        isFloatingWindowVisible = false
    }
    
    func windowDidMove(_ notification: Notification) {
        // Debounce save operation to avoid excessive saves
        scheduleSave()
    }
    
    func windowDidResize(_ notification: Notification) {
        // Debounce save operation to avoid excessive saves
        scheduleSave()
    }
    
    private func scheduleSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: saveDebounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.saveWindowPreferences()
            }
        }
    }
    
    func windowShouldClose(_ window: NSWindow) -> Bool {
        // Instead of closing, just hide the window and update settings
        UserSettings.shared.showFloatingFocusPanel = false
        return true
    }
}
