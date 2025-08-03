//
//  DatabaseMigrationService.swift
//  ConsciousMonitor
//
//  Created by Claude on 2025-08-01.
//  Copyright © 2025 Conscious Monitor. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

/// Minimal database migration service - starting simple and building up
class DatabaseMigrationService: ObservableObject {
    
    // MARK: - Basic Published Properties
    @Published var migrationState: MigrationState = .notStarted
    @Published var progress: Double = 0.0
    @Published var currentStep: String = ""
    @Published var error: Error?
    
    // MARK: - Simple Migration State
    enum MigrationState {
        case notStarted
        case inProgress
        case completed
        case failed
    }
    
    // MARK: - Actual SQLite Migration Method
    @MainActor
    func performMigration() async {
        await MainActor.run {
            migrationState = .inProgress
            progress = 0.0
            currentStep = "Initializing SQLite database..."
        }
        
        do {
            // Get the SQLite storage service
            let sqliteService = SQLiteStorageService.shared
            
            await MainActor.run {
                progress = 0.1
                currentStep = "Migrating data from JSON to SQLite..."
            }
            
            // Perform the actual migration
            try await sqliteService.migrateFromJSONStorage()
            
            await MainActor.run {
                progress = 1.0
                currentStep = "Migration completed successfully!"
                migrationState = .completed
            }
            
        } catch {
            await MainActor.run {
                self.error = error
                migrationState = .failed
                currentStep = "Migration failed: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Static Utility Methods
    static func isMigrationCompleted() -> Bool {
        return UserDefaults.standard.bool(forKey: "SQLiteMigrationCompleted")
    }
    
    static func getMigrationDate() -> Date? {
        return UserDefaults.standard.object(forKey: "SQLiteMigrationDate") as? Date
    }
}