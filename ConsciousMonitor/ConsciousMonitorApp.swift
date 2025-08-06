import SwiftUI

@main
struct ConsciousMonitorApp: App {
    // Create an instance of ActivityMonitor that persists for the app's lifetime
    @StateObject private var activityMonitor = ActivityMonitor()
    
    // Create floating window manager - with safer lazy initialization
    @StateObject private var floatingWindowManager = FloatingWindowManager()

    var body: some Scene {
        // Main application window
        Window("Conscious Monitor App", id: "main-window") {
            ContentView(activityMonitor: activityMonitor)
                .frame(minWidth: 450, idealWidth: 500, maxWidth: .infinity, minHeight: 350, idealHeight: 400, maxHeight: .infinity, alignment: .leading)
                .preferredColorScheme(.dark) // Prefer dark mode
                .onAppear {
                    print("ConsciousMonitor app appeared")
                    
                    // Set up floating window manager with delay to ensure main window is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        print("Setting up FloatingWindowManager")
                        floatingWindowManager.setActivityMonitor(activityMonitor)
                    }
                    
                    // Start favicon backfilling for existing Chrome events
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        print("Starting favicon backfill for existing Chrome events")
                        EventStorageService.shared.backfillMissingFavicons()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    // Force save all data before app terminates
                    print("App terminating - force saving all data...")
                    activityMonitor.forceSaveAllData()
                    
                    // Clean up floating window
                    floatingWindowManager.closeFloatingWindow()
                }
        }
        .defaultPosition(.center)
        .defaultSize(width: 500, height: 400)
        .commands {
            // Add command to manually save data (useful for debugging)
            CommandGroup(replacing: .saveItem) {
                Button("Save Data Now") {
                    activityMonitor.forceSaveAllData()
                }
                .keyboardShortcut("s", modifiers: .command)
            }
            
            // Custom CommandGroup with keyboard shortcut (Cmd+Shift+F) - menu integration
            CommandGroup(after: .windowArrangement) {
                Button("Toggle Floating Focus Bar") {
                    // Direct integration with UserSettings.shared.showFloatingFocusPanel
                    UserSettings.shared.showFloatingFocusPanel.toggle()
                    print("Floating focus bar toggled: \(UserSettings.shared.showFloatingFocusPanel)")
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }
        }
    }
}
