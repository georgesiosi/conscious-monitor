//
//  MigrationView.swift
//  ConsciousMonitor
//
//  Created by Claude on 2025-08-01.
//  Copyright © 2025 Conscious Monitor. All rights reserved.
//

import SwiftUI

/// Simple migration view for SQLite database upgrade
struct MigrationView: View {
    @StateObject private var migrationService = DatabaseMigrationService()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                
                // Header
                VStack(spacing: 16) {
                    Image(systemName: migrationStateIcon)
                        .font(.system(size: 48))
                        .foregroundColor(migrationStateColor)
                    
                    Text("SQLite Migration")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Upgrading your data storage for better performance")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Status
                VStack(spacing: 20) {
                    switch migrationService.migrationState {
                    case .notStarted:
                        readyToMigrateContent
                    case .inProgress:
                        migrationInProgressContent
                    case .completed:
                        migrationCompletedContent
                    case .failed:
                        migrationFailedContent
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                Spacer()
                
                // Actions
                HStack(spacing: 16) {
                    switch migrationService.migrationState {
                    case .notStarted:
                        Button("Start Migration") {
                            Task {
                                await migrationService.performMigration()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                    case .inProgress:
                        Button("Cancel") {
                            // Cancellation logic would go here
                        }
                        .disabled(true)
                        
                    case .completed, .failed:
                        Button("Continue") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .padding(32)
            .navigationTitle("Database Migration")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .disabled(migrationService.migrationState == .inProgress)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    // MARK: - Content Views
    
    private var readyToMigrateContent: some View {
        VStack(spacing: 16) {
            Text("Ready to Migrate")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This will upgrade your data storage to SQLite for better performance and advanced analytics.")
                .font(.body)
                .multilineTextAlignment(.center)
        }
    }
    
    private var migrationInProgressContent: some View {
        VStack(spacing: 16) {
            Text("Migration in Progress")
                .font(.title2)
                .fontWeight(.semibold)
            
            ProgressView(value: migrationService.progress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 8)
            
            Text(migrationService.currentStep)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("\(Int(migrationService.progress * 100))% Complete")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private var migrationCompletedContent: some View {
        VStack(spacing: 16) {
            Text("Migration Completed!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.green)
            
            Text("Your app is now using the new SQLite database for improved performance.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var migrationFailedContent: some View {
        VStack(spacing: 16) {
            Text("Migration Failed")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.red)
            
            if let error = migrationService.error {
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Text("Your original data is safe and preserved.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Computed Properties
    
    private var migrationStateIcon: String {
        switch migrationService.migrationState {
        case .notStarted:
            return "arrow.up.circle"
        case .inProgress:
            return "arrow.2.clockwise"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    private var migrationStateColor: Color {
        switch migrationService.migrationState {
        case .notStarted:
            return .blue
        case .inProgress:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}

// MARK: - Preview
#Preview {
    MigrationView()
}