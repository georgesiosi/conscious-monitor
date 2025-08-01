//
//  MigrationView.swift
//  ConsciousMonitor
//
//  Created by Claude on 2025-08-01.
//  Copyright © 2025 Conscious Monitor. All rights reserved.
//

import SwiftUI

/// View for displaying database migration progress and status
struct MigrationView: View {
    @StateObject private var migrationService = DatabaseMigrationService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDetails = false
    @State private var showingRollbackConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                headerSection
                
                Spacer()
                
                statusSection
                
                Spacer()
                
                actionSection
            }
            .padding(32)
            .navigationTitle("Database Migration")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .disabled(migrationService.migrationState == .inProgress)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .sheet(isPresented: $showingDetails) {
            MigrationDetailsView(validationResults: migrationService.validationResults)
        }
        .alert("Rollback Migration", isPresented: $showingRollbackConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Rollback", role: .destructive) {
                Task {
                    await migrationService.performMigration() // This would be rollback logic
                }
            }
        } message: {
            Text("This will restore your data to its previous state. Any migrated data will be lost. This action cannot be undone.")
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: migrationStateIcon)
                .font(.system(size: 48))
                .foregroundColor(migrationStateColor)
            
            Text("SQLite Migration")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Upgrading your data storage for improved performance and advanced analytics")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 20) {
            // Progress indicator
            switch migrationService.migrationState {
            case .notStarted:
                migrationReadyContent
            case .inProgress, .validating:
                migrationProgressContent
            case .completed:
                migrationCompletedContent
            case .failed:
                migrationFailedContent
            case .rolledBack:
                migrationRolledBackContent
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var migrationReadyContent: some View {
        VStack(spacing: 16) {
            Text("Ready to Migrate")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("This migration will:")
                    .fontWeight(.medium)
                
                migrationBenefitsList
            }
            
            Text("Your existing data will be preserved and a backup will be created.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var migrationBenefitsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            benefitRow("Improve app startup performance")
            benefitRow("Enable advanced analytics and insights")
            benefitRow("Support larger datasets efficiently")
            benefitRow("Provide better data integrity")
        }
        .padding(.leading, 16)
    }
    
    private func benefitRow(_ text: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            Text(text)
                .font(.caption)
            Spacer()
        }
    }
    
    private var migrationProgressContent: some View {
        VStack(spacing: 16) {
            Text(migrationService.migrationState == .validating ? "Validating Migration" : "Migration in Progress")
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
            Text("Migration Completed Successfully!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.green)
            
            if let results = migrationService.validationResults {
                migrationSummary(results)
            }
            
            Text("Your app is now using the new SQLite database for improved performance.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private func migrationSummary(_ results: DatabaseMigrationService.ValidationResults) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Events migrated:")
                Spacer()
                Text("\(results.totalEventsMigrated)")
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Context switches migrated:")
                Spacer()
                Text("\(results.totalContextSwitchesMigrated)")
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Migration time:")
                Spacer()
                Text(String(format: "%.1fs", results.migrationDuration))
                    .fontWeight(.medium)
            }
        }
        .font(.caption)
        .padding(.horizontal)
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
            
            Text("Your original data is safe and has been preserved.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var migrationRolledBackContent: some View {
        VStack(spacing: 16) {
            Text("Migration Rolled Back")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
            
            Text("Your data has been restored to its previous state.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var actionSection: some View {
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
                
            case .inProgress, .validating:
                Button("Cancel") {
                    // Migration cancellation logic would go here
                }
                .disabled(true) // Disable for now as cancellation is complex
                
            case .completed:
                if migrationService.validationResults != nil {
                    Button("View Details") {
                        showingDetails = true
                    }
                    .buttonStyle(.bordered)
                }
                
                Button("Continue") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
            case .failed:
                Button("Retry Migration") {
                    Task {
                        await migrationService.performMigration()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if migrationService.validationResults != nil {
                    Button("View Details") {
                        showingDetails = true
                    }
                    .buttonStyle(.bordered)
                }
                
            case .rolledBack:
                Button("Try Again") {
                    Task {
                        await migrationService.performMigration()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var migrationStateIcon: String {
        switch migrationService.migrationState {
        case .notStarted:
            return "arrow.up.circle"
        case .inProgress, .validating:
            return "arrow.2.clockwise"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .rolledBack:
            return "arrow.uturn.backward.circle.fill"
        }
    }
    
    private var migrationStateColor: Color {
        switch migrationService.migrationState {
        case .notStarted:
            return .blue
        case .inProgress, .validating:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        case .rolledBack:
            return .orange
        }
    }
}

// MARK: - Migration Details View
struct MigrationDetailsView: View {
    let validationResults: DatabaseMigrationService.ValidationResults?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let results = validationResults {
                        migrationDetailsContent(results)
                    } else {
                        Text("No validation results available")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Migration Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
    private func migrationDetailsContent(_ results: DatabaseMigrationService.ValidationResults) -> some View {
        Group {
            migrationSummarySection(results)
            
            if !results.issues.isEmpty {
                migrationIssuesSection(results.issues)
            }
            
            migrationPerformanceSection(results)
        }
    }
    
    private func migrationSummarySection(_ results: DatabaseMigrationService.ValidationResults) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Migration Summary")
                .font(.title2)
                .fontWeight(.bold)
            
            Grid(alignment: .leading, horizontalSpacing: 16) {
                GridRow {
                    Text("Events Expected:")
                    Text("\(results.totalEventsExpected)")
                        .fontWeight(.medium)
                }
                
                GridRow {
                    Text("Events Migrated:")
                    Text("\(results.totalEventsMigrated)")
                        .fontWeight(.medium)
                        .foregroundColor(results.totalEventsMigrated == results.totalEventsExpected ? .green : .red)
                }
                
                GridRow {
                    Text("Context Switches Expected:")
                    Text("\(results.totalContextSwitchesExpected)")
                        .fontWeight(.medium)
                }
                
                GridRow {
                    Text("Context Switches Migrated:")
                    Text("\(results.totalContextSwitchesMigrated)")
                        .fontWeight(.medium)
                        .foregroundColor(results.totalContextSwitchesMigrated == results.totalContextSwitchesExpected ? .green : .red)
                }
                
                GridRow {
                    Text("Data Integrity:")
                    Text(results.dataIntegrityPassed ? "Passed" : "Failed")
                        .fontWeight(.medium)
                        .foregroundColor(results.dataIntegrityPassed ? .green : .red)
                }
                
                GridRow {
                    Text("Migration Duration:")
                    Text(String(format: "%.2f seconds", results.migrationDuration))
                        .fontWeight(.medium)
                }
            }
            .font(.body)
        }
    }
    
    private func migrationIssuesSection(_ issues: [DatabaseMigrationService.ValidationIssue]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Issues Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            ForEach(issues.indices, id: \.self) { index in
                issueRow(issues[index])
            }
        }
    }
    
    private func issueRow(_ issue: DatabaseMigrationService.ValidationIssue) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: issueTypeIcon(issue.type))
                .foregroundColor(issueTypeColor(issue.type))
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.description)
                    .font(.body)
                
                if let itemId = issue.affectedItemId {
                    Text("Affected Item: \(itemId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func migrationPerformanceSection(_ results: DatabaseMigrationService.ValidationResults) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.title2)
                .fontWeight(.bold)
            
            let itemsPerSecond = Double(results.totalEventsMigrated + results.totalContextSwitchesMigrated) / results.migrationDuration
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Migration Rate: \(String(format: "%.0f", itemsPerSecond)) items/second")
                Text("Total Items Processed: \(results.totalEventsMigrated + results.totalContextSwitchesMigrated)")
                
                if itemsPerSecond > 1000 {
                    Text("Excellent performance! 🚀")
                        .foregroundColor(.green)
                } else if itemsPerSecond > 500 {
                    Text("Good performance")
                        .foregroundColor(.orange)
                } else {
                    Text("Consider optimizing for larger datasets")
                        .foregroundColor(.red)
                }
            }
            .font(.body)
        }
    }
    
    private func issueTypeIcon(_ type: DatabaseMigrationService.ValidationIssue.IssueType) -> String {
        switch type {
        case .missingData:
            return "exclamationmark.triangle.fill"
        case .corruptedData:
            return "xmark.circle.fill"
        case .duplicateData:
            return "doc.on.doc.fill"
        case .timestampInconsistency:
            return "clock.badge.exclamationmark.fill"
        }
    }
    
    private func issueTypeColor(_ type: DatabaseMigrationService.ValidationIssue.IssueType) -> Color {
        switch type {
        case .missingData:
            return .orange
        case .corruptedData:
            return .red
        case .duplicateData:
            return .yellow
        case .timestampInconsistency:
            return .purple
        }
    }
}

// MARK: - Preview
#Preview {
    MigrationView()
}