import SwiftUI

struct DataManagementView: View {
    @State private var selectedDateRange: DateRange = .lastMonth
    @State private var exportFormat: DataExportService.ExportFormat = .combinedJSON
    @State private var isExporting = false
    @State private var exportError: DataExportService.ExportError?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var dataFileInfo: [DataFileInfo] = []
    @State private var exportResult: DataExportResult?
    @State private var showingExportResult = false
    @State private var selectedTab: DataManagementTab = .export
    @State private var showingMigrationSheet = false
    
    enum DataExportResult {
        case success
        case failure(String)
    }
    
    enum DataManagementTab: String, CaseIterable {
        case export = "Export"
        case reports = "Reports" 
        case files = "Files"
        
        var systemImage: String {
            switch self {
            case .export: return "square.and.arrow.up"
            case .reports: return "doc.text.magnifyingglass"
            case .files: return "folder"
            }
        }
    }
    
    var body: some View {
        return VStack(spacing: 0) {
            // Tab Navigation
            tabNavigationView
            
            // Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .export:
                        exportSection
                    case .reports:
                        reportsSection
                    case .files:
                        filesSection
                    }
                }
                .padding(20)
            }
        }
        .onAppear {
            refreshFileInfo()
        }
        .alert("Export Result", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingMigrationSheet) {
            MigrationView()
                .frame(minWidth: 500, minHeight: 400)
        }
    }
    
    // MARK: - Tab Navigation
    
    private var tabNavigationView: some View {
        HStack(spacing: 0) {
            ForEach(DataManagementTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 14))
                        Text(tab.rawValue)
                            .font(DesignSystem.Typography.callout)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(
                        selectedTab == tab ? 
                        DesignSystem.Colors.accent.opacity(0.1) : 
                        Color.clear
                    )
                    .foregroundColor(
                        selectedTab == tab ? 
                        DesignSystem.Colors.accent : 
                        DesignSystem.Colors.secondaryText
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(DesignSystem.Colors.contentBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(DesignSystem.Colors.accent.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Data")
                .font(.headline)
                
                HStack {
                    Text("Date Range:")
                        .frame(width: 80, alignment: .leading)
                    
                    Picker("Date Range", selection: $selectedDateRange) {
                        Text("Today").tag(DateRange.today)
                        Text("Last Week").tag(DateRange.lastWeek)
                        Text("Last Month").tag(DateRange.lastMonth)
                        Text("All Time").tag(DateRange.custom(start: Date.distantPast, end: Date.distantFuture))
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Format:")
                        .frame(width: 80, alignment: .leading)
                    
                    Picker("Export Format", selection: $exportFormat) {
                        Text("Combined JSON").tag(DataExportService.ExportFormat.combinedJSON)
                        Text("Events Only").tag(DataExportService.ExportFormat.json)
                        Text("CSV Format").tag(DataExportService.ExportFormat.csv)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                    
                    Spacer()
                }
                
                Button(action: exportData) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                        }
                        Text(isExporting ? "Exporting..." : "Export Data")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExporting)
                .animation(.easeInOut(duration: 0.2), value: isExporting)
                
                Text("Export your activity data to JSON or CSV format with optional date range filtering.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Export result feedback
                if showingExportResult, let result = exportResult {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        switch result {
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.success)
                            Text("Export completed successfully!")
                                .foregroundColor(DesignSystem.Colors.success)
                        case .failure(let message):
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DesignSystem.Colors.error)
                            Text("Export failed: \(message)")
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                        
                        Spacer()
                        
                        Button("Dismiss") {
                            withAnimation {
                                showingExportResult = false
                            }
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(DesignSystem.Colors.accent)
                    }
                    .font(.caption)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                            .fill(DesignSystem.Colors.contentBackground)
                            .stroke(
                                strokeColorForResult(result),
                                lineWidth: 1
                            )
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
    }
    
    // MARK: - Reports Section
    
    private var reportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generate Report")
                .font(.headline)
            
            GenerateReportView()
            
            Text("Create comprehensive activity reports with analytics, insights, and export options.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Files Section
    
    private var filesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
                Text("Data Files")
                    .font(.headline)
                
                Button(action: revealDataDirectory) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "folder")
                            .font(.system(size: 14))
                        Text("Show Data Folder")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Text("Open the folder containing your FocusMonitor data files.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // File Information
                if !dataFileInfo.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("File Information")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(dataFileInfo, id: \.path) { fileInfo in
                            DataFileRow(fileInfo: fileInfo)
                        }
                    }
                    .padding(.top, 8)
                }
                
                // SQLite Migration Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Database Migration (Development)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Button(action: testMigrationUI) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "arrow.up.circle")
                                .font(.system(size: 14))
                            Text("Test Migration UI")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Text("Test the SQLite migration user interface (development feature).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 16)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
    }
    
    private func exportData() {
        isExporting = true
        showingExportResult = false // Hide any previous result
        
        let dateRange = (selectedDateRange.displayName == "All Time") ? nil : selectedDateRange
        
        DataExportService.shared.exportData(format: exportFormat, dateRange: dateRange) { result in
            DispatchQueue.main.async {
                self.isExporting = false
                
                switch result {
                case .success:
                    self.exportResult = .success
                    withAnimation(.spring()) {
                        self.showingExportResult = true
                    }
                    // Auto-hide success message after 4 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation {
                            self.showingExportResult = false
                        }
                    }
                case .failure(let error):
                    self.exportResult = .failure(error.localizedDescription)
                    withAnimation(.spring()) {
                        self.showingExportResult = true
                    }
                }
            }
        }
    }
    
    private func revealDataDirectory() {
        DataExportService.shared.revealDataDirectory()
    }
    
    private func refreshFileInfo() {
        dataFileInfo = DataExportService.shared.getDataFileInfo()
    }
    
    private func testMigrationUI() {
        showingMigrationSheet = true
    }
    
    private func strokeColorForResult(_ result: DataExportResult) -> Color {
        switch result {
        case .success:
            return DesignSystem.Colors.success.opacity(0.3)
        case .failure:
            return DesignSystem.Colors.error.opacity(0.3)
        }
    }
}

struct DataFileRow: View {
    let fileInfo: DataFileInfo
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(fileInfo.name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(fileInfo.path)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if fileInfo.exists {
                    Text(fileInfo.formattedSize)
                        .font(.caption2)
                        .foregroundColor(.primary)
                    
                    Text(fileInfo.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not found")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.textBackgroundColor))
        .cornerRadius(4)
    }
}

// MARK: - DateRange Extension

extension DateRange {
    static let allTime = DateRange.custom(start: Date.distantPast, end: Date.distantFuture)
}

#Preview {
    DataManagementView()
        .frame(width: 500, height: 600)
}