import Foundation
import AppKit
import UniformTypeIdentifiers

class DataExportService {
    nonisolated(unsafe) static let shared = DataExportService()
    
    private init() {}
    
    enum ExportFormat {
        case json
        case csv
        case combinedJSON
        case analysisJSON
        case analysisText
        case analysisMarkdown
        case analysisPDF
    }
    
    enum ExportError: Error {
        case fileReadError(String)
        case exportError(String)
        case noDataToExport
        
        var localizedDescription: String {
            switch self {
            case .fileReadError(let message):
                return "Failed to read data: \(message)"
            case .exportError(let message):
                return "Export failed: \(message)"
            case .noDataToExport:
                return "No data available to export"
            }
        }
    }
    
    // MARK: - Export Data
    
    @MainActor
    func exportData(format: ExportFormat, dateRange: DateRange? = nil, completion: @escaping (Result<Void, ExportError>) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [contentType(for: format)]
        savePanel.nameFieldStringValue = generateFileName(format: format)
        savePanel.title = "Export ConsciousMonitor Data"
        
        savePanel.begin { result in
            guard result == .OK, let url = savePanel.url else {
                return // User cancelled
            }
            
            self.performExport(to: url, format: format, dateRange: dateRange, completion: completion)
        }
    }
    
    // MARK: - Export Analysis Data
    
    @MainActor
    func exportAnalyses(format: ExportFormat, analyses: [AnalysisEntry]? = nil, dateRange: DateRange? = nil, completion: @escaping (Result<Void, ExportError>) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [contentType(for: format)]
        savePanel.nameFieldStringValue = generateAnalysisFileName(format: format)
        savePanel.title = "Export AI Insights"
        
        savePanel.begin { result in
            guard result == .OK, let url = savePanel.url else {
                return // User cancelled
            }
            
            self.performAnalysisExport(to: url, format: format, analyses: analyses, dateRange: dateRange, completion: completion)
        }
    }
    
    @MainActor
    func exportSingleAnalysis(analysis: AnalysisEntry, format: ExportFormat, completion: @escaping (Result<Void, ExportError>) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [contentType(for: format)]
        savePanel.nameFieldStringValue = generateSingleAnalysisFileName(analysis: analysis, format: format)
        savePanel.title = "Export Analysis"
        
        savePanel.begin { result in
            guard result == .OK, let url = savePanel.url else {
                return // User cancelled
            }
            
            self.performSingleAnalysisExport(to: url, analysis: analysis, format: format, completion: completion)
        }
    }
    
    private func performExport(to url: URL, format: ExportFormat, dateRange: DateRange?, completion: @escaping (Result<Void, ExportError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data: Data
                
                switch format {
                case .json:
                    data = try self.exportAsJSON(dateRange: dateRange)
                case .csv:
                    data = try self.exportAsCSV(dateRange: dateRange)
                case .combinedJSON:
                    data = try self.exportAsCombinedJSON(dateRange: dateRange)
                case .analysisJSON, .analysisText, .analysisMarkdown, .analysisPDF:
                    throw ExportError.exportError("Analysis export not supported via this method")
                }
                
                try data.write(to: url)
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch let error as ExportError {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.exportError(error.localizedDescription)))
                }
            }
        }
    }
    
    // MARK: - Export Formats
    
    private func exportAsJSON(dateRange: DateRange?) throws -> Data {
        let events = try loadEvents(dateRange: dateRange)
        return try JSONEncoder().encode(events)
    }
    
    private func exportAsCSV(dateRange: DateRange?) throws -> Data {
        let events = try loadEvents(dateRange: dateRange)
        var csvContent = "Timestamp,App Name,Bundle ID,Chrome Tab Title,Chrome Tab URL,Category,Session ID\n"
        
        for event in events {
            let fields = [
                event.timestamp.ISO8601Format(),
                event.appName ?? "",
                event.bundleIdentifier ?? "",
                event.chromeTabTitle ?? "",
                event.chromeTabUrl ?? "",
                event.category.name,
                event.sessionId?.uuidString ?? ""
            ]
            let quotedFields = fields.map { "\"\($0)\"" }
            let row = quotedFields.joined(separator: ",")
            
            csvContent += row + "\n"
        }
        
        guard let data = csvContent.data(using: .utf8) else {
            throw ExportError.exportError("Failed to convert CSV to data")
        }
        
        return data
    }
    
    private func exportAsCombinedJSON(dateRange: DateRange?) throws -> Data {
        let events = try loadEvents(dateRange: dateRange)
        let contextSwitches = try loadContextSwitches(dateRange: dateRange)
        
        let combinedData: [String: Any] = [
            "exportDate": Date().ISO8601Format(),
            "dateRange": dateRange?.displayName ?? "All Time",
            "activationEvents": events.map { try? JSONSerialization.jsonObject(with: JSONEncoder().encode($0)) },
            "contextSwitches": contextSwitches.map { try? JSONSerialization.jsonObject(with: JSONEncoder().encode($0)) }
        ]
        
        return try JSONSerialization.data(withJSONObject: combinedData, options: .prettyPrinted)
    }
    
    // MARK: - Analysis Export Implementation
    
    private func performAnalysisExport(to url: URL, format: ExportFormat, analyses: [AnalysisEntry]?, dateRange: DateRange?, completion: @escaping (Result<Void, ExportError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let analysesToExport = analyses ?? self.loadAnalyses(dateRange: dateRange)
                
                guard !analysesToExport.isEmpty else {
                    DispatchQueue.main.async {
                        completion(.failure(.noDataToExport))
                    }
                    return
                }
                
                let data = try self.exportAnalysesAsFormat(analysesToExport, format: format)
                
                try data.write(to: url)
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch let error as ExportError {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.exportError(error.localizedDescription)))
                }
            }
        }
    }
    
    private func performSingleAnalysisExport(to url: URL, analysis: AnalysisEntry, format: ExportFormat, completion: @escaping (Result<Void, ExportError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try self.exportAnalysesAsFormat([analysis], format: format)
                
                try data.write(to: url)
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch let error as ExportError {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.exportError(error.localizedDescription)))
                }
            }
        }
    }
    
    private func exportAnalysesAsFormat(_ analyses: [AnalysisEntry], format: ExportFormat) throws -> Data {
        switch format {
        case .analysisJSON:
            return try exportAnalysesAsJSON(analyses)
        case .analysisText:
            return try exportAnalysesAsText(analyses)
        case .analysisMarkdown:
            return try exportAnalysesAsMarkdown(analyses)
        case .analysisPDF:
            return try exportAnalysesAsPDF(analyses)
        default:
            throw ExportError.exportError("Unsupported analysis format")
        }
    }
    
    private func exportAnalysesAsJSON(_ analyses: [AnalysisEntry]) throws -> Data {
        let exportData = AnalysisExportData(
            exportDate: Date(),
            exportFormat: "JSON",
            totalAnalyses: analyses.count,
            analyses: analyses
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(exportData)
    }
    
    private func exportAnalysesAsText(_ analyses: [AnalysisEntry]) throws -> Data {
        var content = "AI Insights Export\n"
        content += "==================\n\n"
        content += "Generated: \(Date().formatted(date: .complete, time: .shortened))\n"
        content += "Total Analyses: \(analyses.count)\n\n"
        
        for (index, analysis) in analyses.enumerated() {
            content += "Analysis #\(index + 1)\n"
            content += "----------\n"
            content += "Date: \(analysis.timestamp.formatted(date: .complete, time: .shortened))\n"
            content += "Type: \(analysis.analysisType.capitalized)\n"
            content += "Time Range: \(analysis.timeRangeAnalyzed)\n"
            content += "Data Points: \(analysis.dataPoints)\n"
            content += "Scope: \(analysis.scopeSummary)\n\n"
            content += "Insights:\n"
            content += analysis.insights
            content += "\n\n"
            content += "---\n\n"
        }
        
        guard let data = content.data(using: .utf8) else {
            throw ExportError.exportError("Failed to convert text to data")
        }
        
        return data
    }
    
    private func exportAnalysesAsMarkdown(_ analyses: [AnalysisEntry]) throws -> Data {
        var content = "# AI Insights Export\n\n"
        content += "**Generated:** \(Date().formatted(date: .complete, time: .shortened))  \n"
        content += "**Total Analyses:** \(analyses.count)\n\n"
        
        for (index, analysis) in analyses.enumerated() {
            content += "## Analysis #\(index + 1)\n\n"
            content += "- **Date:** \(analysis.timestamp.formatted(date: .complete, time: .shortened))\n"
            content += "- **Type:** \(analysis.analysisType.capitalized)\n"
            content += "- **Time Range:** \(analysis.timeRangeAnalyzed)\n"
            content += "- **Data Points:** \(analysis.dataPoints)\n"
            content += "- **Scope:** \(analysis.scopeSummary)\n\n"
            content += "### Insights\n\n"
            content += analysis.insights
            content += "\n\n---\n\n"
        }
        
        guard let data = content.data(using: .utf8) else {
            throw ExportError.exportError("Failed to convert markdown to data")
        }
        
        return data
    }
    
    private func exportAnalysesAsPDF(_ analyses: [AnalysisEntry]) throws -> Data {
        // For now, return a simple PDF placeholder
        // In a real implementation, this would use NSPrintOperation or similar
        let content = "PDF export for AI Insights is not yet implemented. Use Text or Markdown formats instead."
        
        guard let data = content.data(using: .utf8) else {
            throw ExportError.exportError("Failed to generate PDF placeholder")
        }
        
        return data
    }
    
    // MARK: - Data Loading
    
    private func loadEvents(dateRange: DateRange?) throws -> [AppActivationEvent] {
        guard let eventsData = try? Data(contentsOf: DataStorage.shared.activationEventsURL) else {
            throw ExportError.fileReadError("Could not read events file")
        }
        
        guard let events = try? JSONDecoder().decode([AppActivationEvent].self, from: eventsData) else {
            throw ExportError.fileReadError("Could not decode events data")
        }
        
        return filterEvents(events, dateRange: dateRange)
    }
    
    private func loadContextSwitches(dateRange: DateRange?) throws -> [ContextSwitchMetrics] {
        guard let switchesData = try? Data(contentsOf: DataStorage.shared.contextSwitchesURL) else {
            throw ExportError.fileReadError("Could not read context switches file")
        }
        
        guard let switches = try? JSONDecoder().decode([ContextSwitchMetrics].self, from: switchesData) else {
            throw ExportError.fileReadError("Could not decode context switches data")
        }
        
        return filterContextSwitches(switches, dateRange: dateRange)
    }
    
    private func loadAnalyses(dateRange: DateRange?) -> [AnalysisEntry] {
        let analyses = AnalysisStorageService.shared.analyses
        return filterAnalyses(analyses, dateRange: dateRange)
    }
    
    private func filterAnalyses(_ analyses: [AnalysisEntry], dateRange: DateRange?) -> [AnalysisEntry] {
        guard let dateRange = dateRange else { return analyses }
        
        let calendar = Calendar.current
        let now = Date()
        
        return analyses.filter { analysis in
            switch dateRange {
            case .today:
                return calendar.isDate(analysis.timestamp, inSameDayAs: now)
            case .lastWeek:
                return calendar.component(.weekOfYear, from: analysis.timestamp) == calendar.component(.weekOfYear, from: now) &&
                       calendar.component(.year, from: analysis.timestamp) == calendar.component(.year, from: now)
            case .lastMonth:
                return calendar.component(.month, from: analysis.timestamp) == calendar.component(.month, from: now) &&
                       calendar.component(.year, from: analysis.timestamp) == calendar.component(.year, from: now)
            case .yesterday:
                return calendar.isDate(analysis.timestamp, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now)
            case .lastQuarter:
                return analysis.timestamp >= calendar.date(byAdding: .month, value: -3, to: now) ?? now
            case .lastYear:
                return analysis.timestamp >= calendar.date(byAdding: .year, value: -1, to: now) ?? now
            case .custom(let start, let end):
                return analysis.timestamp >= start && analysis.timestamp <= end
            }
        }
    }
    
    // MARK: - Filtering
    
    private func filterEvents(_ events: [AppActivationEvent], dateRange: DateRange?) -> [AppActivationEvent] {
        guard let dateRange = dateRange else { return events }
        
        let calendar = Calendar.current
        let now = Date()
        
        return events.filter { event in
            switch dateRange {
            case .today:
                return calendar.isDate(event.timestamp, inSameDayAs: now)
            case .lastWeek:
                return calendar.component(.weekOfYear, from: event.timestamp) == calendar.component(.weekOfYear, from: now) &&
                       calendar.component(.year, from: event.timestamp) == calendar.component(.year, from: now)
            case .lastMonth:
                return calendar.component(.month, from: event.timestamp) == calendar.component(.month, from: now) &&
                       calendar.component(.year, from: event.timestamp) == calendar.component(.year, from: now)
            case .yesterday:
                return calendar.isDate(event.timestamp, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now)
            case .lastQuarter:
                return event.timestamp >= calendar.date(byAdding: .month, value: -3, to: now) ?? now
            case .lastYear:
                return event.timestamp >= calendar.date(byAdding: .year, value: -1, to: now) ?? now
            case .custom(let start, let end):
                return event.timestamp >= start && event.timestamp <= end
            }
        }
    }
    
    private func filterContextSwitches(_ switches: [ContextSwitchMetrics], dateRange: DateRange?) -> [ContextSwitchMetrics] {
        guard let dateRange = dateRange else { return switches }
        
        let calendar = Calendar.current
        let now = Date()
        
        return switches.filter { switchEvent in
            switch dateRange {
            case .today:
                return calendar.isDate(switchEvent.timestamp, inSameDayAs: now)
            case .lastWeek:
                return calendar.component(.weekOfYear, from: switchEvent.timestamp) == calendar.component(.weekOfYear, from: now) &&
                       calendar.component(.year, from: switchEvent.timestamp) == calendar.component(.year, from: now)
            case .lastMonth:
                return calendar.component(.month, from: switchEvent.timestamp) == calendar.component(.month, from: now) &&
                       calendar.component(.year, from: switchEvent.timestamp) == calendar.component(.year, from: now)
            case .yesterday:
                return calendar.isDate(switchEvent.timestamp, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now)
            case .lastQuarter:
                return switchEvent.timestamp >= calendar.date(byAdding: .month, value: -3, to: now) ?? now
            case .lastYear:
                return switchEvent.timestamp >= calendar.date(byAdding: .year, value: -1, to: now) ?? now
            case .custom(let start, let end):
                return switchEvent.timestamp >= start && switchEvent.timestamp <= end
            }
        }
    }
    
    // MARK: - Content Type Utilities
    
    private func contentType(for format: ExportFormat) -> UTType {
        switch format {
        case .json, .combinedJSON, .analysisJSON:
            return .json
        case .csv:
            return .commaSeparatedText
        case .analysisText:
            return .plainText
        case .analysisMarkdown:
            return .data // Markdown doesn't have a specific UTType in older macOS versions
        case .analysisPDF:
            return .pdf
        }
    }
    
    // MARK: - Utilities
    
    private func generateFileName(format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        switch format {
        case .json:
            return "ConsciousMonitor_Events_\(timestamp).json"
        case .csv:
            return "ConsciousMonitor_Events_\(timestamp).csv"
        case .combinedJSON:
            return "ConsciousMonitor_Complete_\(timestamp).json"
        case .analysisJSON, .analysisText, .analysisMarkdown, .analysisPDF:
            return "ConsciousMonitor_Analysis_\(timestamp).\(fileExtension(for: format))"
        }
    }
    
    private func generateAnalysisFileName(format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        return "ConsciousMonitor_Analyses_\(timestamp).\(fileExtension(for: format))"
    }
    
    private func generateSingleAnalysisFileName(analysis: AnalysisEntry, format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: analysis.timestamp)
        
        return "ConsciousMonitor_Analysis_\(timestamp).\(fileExtension(for: format))"
    }
    
    private func fileExtension(for format: ExportFormat) -> String {
        switch format {
        case .json, .combinedJSON, .analysisJSON:
            return "json"
        case .csv:
            return "csv"
        case .analysisText:
            return "txt"
        case .analysisMarkdown:
            return "md"
        case .analysisPDF:
            return "pdf"
        }
    }
    
    // MARK: - File System Access
    
    @MainActor
    func revealDataDirectory() {
        NSWorkspace.shared.open(DataStorage.shared.dataDirectoryURL)
    }
    
    func getDataFileInfo() -> [DataFileInfo] {
        let fileManager = FileManager.default
        var fileInfos: [DataFileInfo] = []
        
        let files = [
            ("Activity Events", DataStorage.shared.activationEventsURL),
            ("Context Switches", DataStorage.shared.contextSwitchesURL),
            ("Events Backup", DataStorage.shared.activationEventsBackupURL),
            ("Context Switches Backup", DataStorage.shared.contextSwitchesBackupFileURL)
        ]
        
        for (name, url) in files {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: url.path)
                let size = attributes[.size] as? Int64 ?? 0
                let modificationDate = attributes[.modificationDate] as? Date ?? Date()
                let exists = fileManager.fileExists(atPath: url.path)
                
                fileInfos.append(DataFileInfo(
                    name: name,
                    path: url.path,
                    size: size,
                    lastModified: modificationDate,
                    exists: exists
                ))
            } catch {
                fileInfos.append(DataFileInfo(
                    name: name,
                    path: url.path,
                    size: 0,
                    lastModified: Date(),
                    exists: false
                ))
            }
        }
        
        return fileInfos
    }
}

// MARK: - Supporting Types

struct DataFileInfo {
    let name: String
    let path: String
    let size: Int64
    let lastModified: Date
    let exists: Bool
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: lastModified)
    }
}

// MARK: - Analysis Export Data Structure

struct AnalysisExportData: Codable {
    let exportDate: Date
    let exportFormat: String
    let totalAnalyses: Int
    let analyses: [AnalysisEntry]
    
    init(exportDate: Date, exportFormat: String, totalAnalyses: Int, analyses: [AnalysisEntry]) {
        self.exportDate = exportDate
        self.exportFormat = exportFormat
        self.totalAnalyses = totalAnalyses
        self.analyses = analyses
    }
}

