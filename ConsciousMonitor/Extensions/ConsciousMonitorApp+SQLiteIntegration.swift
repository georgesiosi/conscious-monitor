//
//  ConsciousMonitorApp+SQLiteIntegration.swift
//  ConsciousMonitor
//
//  Created by Claude on 2025-08-01.
//  Copyright © 2025 Conscious Monitor. All rights reserved.
//

import SwiftUI
import Combine

/// Extension to main app for SQLite integration and migration support
extension ConsciousMonitorApp {
    
    /// Initialize SQLite integration during app startup
    func initializeSQLiteIntegration() {
        // Setup storage coordinator in ActivityMonitor
        activityMonitor.setupStorageCoordinator()
        
        // Check for pending migrations
        checkForPendingMigration()
        
        // Setup migration monitoring
        setupMigrationMonitoring()
    }
    
    private func checkForPendingMigration() {
        if StorageCoordinator.needsMigration() {
            // Show migration notification or prompt
            showMigrationNotification()
        }
    }
    
    private func showMigrationNotification() {
        // Create a notification about available database upgrade
        let notification = NSUserNotification()
        notification.title = "Database Upgrade Available"
        notification.informativeText = "ConsciousMonitor can upgrade your data storage for better performance. Would you like to upgrade now?"
        notification.hasActionButton = true
        notification.actionButtonTitle = "Upgrade"
        notification.otherButtonTitle = "Later"
        
        // Deliver notification
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private func setupMigrationMonitoring() {
        // Monitor migration completion and show success notification
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SQLiteMigrationCompleted"),
            object: nil,
            queue: .main
        ) { _ in
            self.showMigrationSuccessNotification()
        }
    }
    
    private func showMigrationSuccessNotification() {
        let notification = NSUserNotification()
        notification.title = "Database Upgrade Complete"
        notification.informativeText = "Your data has been successfully upgraded to the new high-performance database system."
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}

/// View modifier for migration UI integration
struct MigrationPromptModifier: ViewModifier {
    @ObservedObject var activityMonitor: ActivityMonitor
    @State private var showMigrationSheet = false
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showMigrationSheet) {
                MigrationView()
                    .frame(minWidth: 500, minHeight: 400)
            }
            .onReceive(activityMonitor.$showMigrationPrompt) { showPrompt in
                if showPrompt {
                    showMigrationSheet = true
                }
            }
            .onChange(of: showMigrationSheet) { isShowing in
                if !isShowing {
                    activityMonitor.showMigrationPrompt = false
                }
            }
    }
}

/// Extension to View for easy migration prompt integration
extension View {
    func migrationPrompt(activityMonitor: ActivityMonitor) -> some View {
        self.modifier(MigrationPromptModifier(activityMonitor: activityMonitor))
    }
}

/// Migration status bar item for menu bar integration
class MigrationStatusBarItem: ObservableObject {
    private var statusItem: NSStatusItem?
    private var activityMonitor: ActivityMonitor?
    private var cancellables = Set<AnyCancellable>()
    
    func setup(with activityMonitor: ActivityMonitor) {
        self.activityMonitor = activityMonitor
        
        // Only show status bar item during migration
        activityMonitor.$isMigrating
            .sink { [weak self] isMigrating in
                if isMigrating {
                    self?.showStatusBarItem()
                } else {
                    self?.hideStatusBarItem()
                }
            }
            .store(in: &cancellables)
    }
    
    private func showStatusBarItem() {
        guard statusItem == nil else { return }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "Migrating..."
        
        let menu = NSMenu()
        
        // Migration progress item
        let progressItem = NSMenuItem()
        progressItem.view = createProgressView()
        menu.addItem(progressItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Cancel migration item (if implemented)
        let cancelItem = NSMenuItem(title: "Cancel Migration", action: #selector(cancelMigration), keyEquivalent: "")
        cancelItem.target = self
        menu.addItem(cancelItem)
        
        statusItem?.menu = menu
    }
    
    private func hideStatusBarItem() {
        statusItem = nil
    }
    
    private func createProgressView() -> NSView {
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 30))
        
        let progressIndicator = NSProgressIndicator(frame: NSRect(x: 10, y: 10, width: 180, height: 10))
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        
        // Bind to migration progress
        activityMonitor?.$migrationProgress
            .receive(on: DispatchQueue.main)
            .sink { progress in
                progressIndicator.doubleValue = progress * 100
            }
            .store(in: &cancellables)
        
        containerView.addSubview(progressIndicator)
        
        return containerView
    }
    
    @objc private func cancelMigration() {
        // TODO: Implement migration cancellation
        print("Migration cancellation requested")
    }
}

/// App lifecycle handler for SQLite integration
class SQLiteAppLifecycleHandler: ObservableObject {
    private let activityMonitor: ActivityMonitor
    private let migrationStatusBar = MigrationStatusBarItem()
    
    init(activityMonitor: ActivityMonitor) {
        self.activityMonitor = activityMonitor
        setup()
    }
    
    private func setup() {
        // Setup migration status bar
        migrationStatusBar.setup(with: activityMonitor)
        
        // Handle app termination
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppTermination()
        }
        
        // Handle app becoming active
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppBecameActive()
        }
    }
    
    private func handleAppTermination() {
        // Ensure all data is saved before termination
        if activityMonitor.isUsingSQLite {
            // SQLite automatically handles transactions
            print("App terminating with SQLite - data automatically saved")
        } else {
            // Force save for JSON storage
            activityMonitor.forceSaveAllData()
            print("App terminating with JSON - forced data save completed")
        }
    }
    
    private func handleAppBecameActive() {
        // Check for completed migrations when app becomes active
        if StorageCoordinator.needsMigration() && !activityMonitor.showMigrationPrompt {
            // Show migration prompt after a delay to avoid interrupting user workflow
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if StorageCoordinator.needsMigration() {
                    self.activityMonitor.showMigrationPrompt = true
                }
            }
        }
    }
}

/// Enhanced app startup with SQLite integration
struct SQLiteIntegratedApp: View {
    @StateObject private var activityMonitor = ActivityMonitor()
    @StateObject private var floatingWindowManager = FloatingWindowManager()
    @StateObject private var lifecycleHandler: SQLiteAppLifecycleHandler
    
    init() {
        let monitor = ActivityMonitor()
        _activityMonitor = StateObject(wrappedValue: monitor)
        _floatingWindowManager = StateObject(wrappedValue: FloatingWindowManager())
        _lifecycleHandler = StateObject(wrappedValue: SQLiteAppLifecycleHandler(activityMonitor: monitor))
    }
    
    var body: some View {
        ContentView(activityMonitor: activityMonitor)
            .frame(minWidth: 450, idealWidth: 500, maxWidth: .infinity, 
                   minHeight: 350, idealHeight: 400, maxHeight: .infinity, 
                   alignment: .leading)
            .preferredColorScheme(.dark)
            .migrationPrompt(activityMonitor: activityMonitor)
            .onAppear {
                setupApplication()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                handleAppTermination()
            }
    }
    
    private func setupApplication() {
        print("ConsciousMonitor app with SQLite support appeared")
        
        // Initialize SQLite integration
        activityMonitor.setupStorageCoordinator()
        
        // Setup floating window manager
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            floatingWindowManager.setActivityMonitor(activityMonitor)
        }
        
        // Check for available migrations
        if StorageCoordinator.needsMigration() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                activityMonitor.showMigrationPrompt = true
            }
        }
    }
    
    private func handleAppTermination() {
        print("App terminating - ensuring data integrity...")
        
        // Force save all data
        activityMonitor.forceSaveAllData()
        
        // Clean up floating window
        floatingWindowManager.closeFloatingWindow()
        
        // Additional cleanup for SQLite if needed
        if activityMonitor.isUsingSQLite {
            print("SQLite storage - transaction integrity maintained")
        }
    }
}