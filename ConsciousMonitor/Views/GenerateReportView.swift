import SwiftUI

struct GenerateReportView: View {
    @ObservedObject private var reportService = ReportGenerationService.shared
    @State private var selectedDataTypes: Set<ReportDataType> = [.appUsage, .contextSwitches]
    @State private var selectedDateRange: DateRange = .lastWeek
    @State private var selectedFormat: ReportFormat = .json
    @State private var isGenerating = false
    @State private var showingResult = false
    @State private var resultMessage = ""
    @State private var resultIsSuccess = false
    @State private var savedFileURL: URL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Data Selection
            dataSelectionSection
            
            // Date Range Selection
            dateRangeSection
            
            // Format Selection
            formatSection
            
            // Generate Button
            generateSection
            
            // Results
            if showingResult {
                resultSection
            }
        }
        .padding(DesignSystem.Spacing.md)
    }
    
    private var dataSelectionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Data Types")
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.medium)
            
            ForEach(ReportDataType.allCases, id: \.self) { dataType in
                Toggle(dataType.displayName, isOn: Binding(
                    get: { selectedDataTypes.contains(dataType) },
                    set: { isSelected in
                        if isSelected {
                            selectedDataTypes.insert(dataType)
                        } else {
                            selectedDataTypes.remove(dataType)
                        }
                    }
                ))
                .font(DesignSystem.Typography.body)
            }
        }
    }
    
    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Date Range")
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.medium)
            
            Picker("Date Range", selection: $selectedDateRange) {
                Text("Today").tag(DateRange.today)
                Text("Yesterday").tag(DateRange.yesterday)
                Text("Last Week").tag(DateRange.lastWeek)
                Text("Last Month").tag(DateRange.lastMonth)
            }
            .pickerStyle(.menu)
        }
    }
    
    private var formatSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Export Format")
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.medium)
            
            Picker("Format", selection: $selectedFormat) {
                Text("JSON").tag(ReportFormat.json)
                Text("CSV").tag(ReportFormat.csv)
                Text("PDF").tag(ReportFormat.pdf)
                Text("HTML").tag(ReportFormat.html)
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var generateSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Button(action: generateReport) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "doc.badge.plus")
                    }
                    Text(isGenerating ? "Generating..." : "Generate Report")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedDataTypes.isEmpty || isGenerating)
            
            if selectedDataTypes.isEmpty {
                Text("Please select at least one data type")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.error)
            }
        }
    }
    
    private var resultSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: resultIsSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(resultIsSuccess ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                
                Text(resultMessage)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(resultIsSuccess ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                
                Spacer()
                
                Button("Dismiss") {
                    withAnimation {
                        showingResult = false
                    }
                }
                .buttonStyle(.borderless)
            }
            
            // Show in Finder button for successful exports
            if resultIsSuccess && savedFileURL != nil {
                HStack {
                    Button(action: showInFinder) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "folder")
                                .font(.system(size: 12))
                            Text("Show in Finder")
                                .font(DesignSystem.Typography.caption)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Spacer()
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .fill(DesignSystem.Colors.contentBackground)
                .stroke(
                    resultIsSuccess ? DesignSystem.Colors.success.opacity(0.3) : DesignSystem.Colors.error.opacity(0.3),
                    lineWidth: 1
                )
        )
        .transition(.opacity)
    }
    
    private func generateReport() {
        guard !selectedDataTypes.isEmpty else { return }
        
        isGenerating = true
        showingResult = false
        
        let config = ReportConfiguration(
            name: "Manual Report",
            dataTypes: selectedDataTypes,
            format: selectedFormat,
            dateRange: selectedDateRange
        )
        
        reportService.generateReport(config: config) { result in
            DispatchQueue.main.async {
                self.isGenerating = false
                
                switch result {
                case .success(let report):
                    // After generating, automatically export the report
                    let exportFormat = self.convertToExportFormat(self.selectedFormat)
                    self.reportService.exportReport(report, format: exportFormat) { exportResult in
                        DispatchQueue.main.async {
                            switch exportResult {
                            case .success(let fileURL):
                                self.savedFileURL = fileURL
                                self.resultMessage = "Report saved to: \(fileURL.path)"
                                self.resultIsSuccess = true
                            case .failure(let error):
                                self.resultMessage = "Failed to save report: \(error.localizedDescription)"
                                self.resultIsSuccess = false
                            }
                        }
                    }
                case .failure(let error):
                    self.resultMessage = "Failed to generate report: \(error.localizedDescription)"
                    self.resultIsSuccess = false
                }
                
                withAnimation {
                    self.showingResult = true
                }
                
                // Auto-hide success messages
                if self.resultIsSuccess {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation {
                            self.showingResult = false
                        }
                    }
                }
            }
        }
    }
    
    private func convertToExportFormat(_ format: ReportFormat) -> ReportExportFormat {
        switch format {
        case .json: return .json
        case .csv: return .csv
        case .pdf: return .pdf
        case .html: return .markdown // HTML maps to markdown for now
        case .markdown: return .markdown
        case .xlsx: return .csv // Excel maps to CSV for now
        }
    }
    
    private func showInFinder() {
        guard let url = savedFileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

#Preview {
    GenerateReportView()
        .frame(width: 400, height: 500)
}