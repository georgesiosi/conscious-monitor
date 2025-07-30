import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Report Format Enum

/// Enum for different export formats supported by the report generation system
enum ReportFormat: String, CaseIterable, Codable, Hashable {
    case pdf = "pdf"
    case csv = "csv"
    case json = "json"
    case html = "html"
    case markdown = "markdown"
    case xlsx = "xlsx"
    
    // MARK: - Display Properties
    
    var displayName: String {
        switch self {
        case .pdf:
            return "PDF"
        case .csv:
            return "CSV"
        case .json:
            return "JSON"
        case .html:
            return "HTML"
        case .markdown:
            return "Markdown"
        case .xlsx:
            return "Excel"
        }
    }
    
    var description: String {
        switch self {
        case .pdf:
            return "Portable document format with charts, formatting, and professional layout"
        case .csv:
            return "Comma-separated values for data analysis in spreadsheet applications"
        case .json:
            return "JavaScript Object Notation for programmatic access and API integration"
        case .html:
            return "Web format with interactive elements and responsive design"
        case .markdown:
            return "Plain text format with lightweight markup for documentation"
        case .xlsx:
            return "Microsoft Excel format with multiple worksheets and advanced formatting"
        }
    }
    
    var fileExtension: String {
        return rawValue
    }
    
    var mimeType: String {
        switch self {
        case .pdf:
            return "application/pdf"
        case .csv:
            return "text/csv"
        case .json:
            return "application/json"
        case .html:
            return "text/html"
        case .markdown:
            return "text/markdown"
        case .xlsx:
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        }
    }
    
    var uniformTypeIdentifier: UTType {
        switch self {
        case .pdf:
            return .pdf
        case .csv:
            return .commaSeparatedText
        case .json:
            return .json
        case .html:
            return .html
        case .markdown:
            return UTType(filenameExtension: "md") ?? .plainText
        case .xlsx:
            return UTType(mimeType: mimeType) ?? .data
        }
    }
    
    var icon: String {
        switch self {
        case .pdf:
            return "doc.richtext"
        case .csv:
            return "tablecells"
        case .json:
            return "curlybraces"
        case .html:
            return "globe"
        case .markdown:
            return "doc.text"
        case .xlsx:
            return "doc.spreadsheet"
        }
    }
    
    var color: Color {
        switch self {
        case .pdf:
            return .red
        case .csv:
            return .green
        case .json:
            return .blue
        case .html:
            return .orange
        case .markdown:
            return .gray
        case .xlsx:
            return Color(red: 0.2, green: 0.6, blue: 0.2) // Excel green
        }
    }
    
    // MARK: - Format Capabilities
    
    /// Indicates if this format supports rich formatting (fonts, colors, etc.)
    var supportsRichFormatting: Bool {
        switch self {
        case .pdf, .html, .xlsx:
            return true
        case .csv, .json, .markdown:
            return false
        }
    }
    
    /// Indicates if this format supports embedded charts and images
    var supportsCharts: Bool {
        switch self {
        case .pdf, .html, .xlsx:
            return true
        case .csv, .json, .markdown:
            return false
        }
    }
    
    /// Indicates if this format is suitable for data analysis
    var supportsDataAnalysis: Bool {
        switch self {
        case .csv, .json, .xlsx:
            return true
        case .pdf, .html, .markdown:
            return false
        }
    }
    
    /// Indicates if this format supports interactive elements
    var supportsInteractivity: Bool {
        switch self {
        case .html:
            return true
        case .pdf, .csv, .json, .markdown, .xlsx:
            return false
        }
    }
    
    /// Indicates if this format is suitable for sharing and presentation
    var supportsSharing: Bool {
        switch self {
        case .pdf, .html:
            return true
        case .csv, .json, .markdown, .xlsx:
            return false
        }
    }
    
    /// Indicates if this format preserves data structure accurately
    var preservesDataStructure: Bool {
        switch self {
        case .json, .xlsx:
            return true
        case .pdf, .csv, .html, .markdown:
            return false
        }
    }
    
    /// Estimated file size multiplier compared to JSON baseline
    var fileSizeMultiplier: Double {
        switch self {
        case .json:
            return 1.0 // Baseline
        case .csv:
            return 0.7 // More compact for tabular data
        case .markdown:
            return 0.8 // Plain text, relatively compact
        case .html:
            return 1.5 // HTML markup adds overhead
        case .pdf:
            return 2.0 // Rich formatting and embedded elements
        case .xlsx:
            return 1.8 // Compressed binary format with formatting
        }
    }
    
    // MARK: - Data Type Compatibility
    
    /// Data types that work well with this format
    func compatibleDataTypes() -> Set<ReportDataType> {
        switch self {
        case .pdf:
            // PDF supports all data types with rich presentation
            return Set(ReportDataType.allCases)
            
        case .csv:
            // CSV only supports tabular data types
            return [.appUsage, .contextSwitches, .categoryMetrics, .sessionData, .chromeData, .timeDistribution, .complianceHistory]
            
        case .json:
            // JSON supports all data types with full structure preservation
            return Set(ReportDataType.allCases)
            
        case .html:
            // HTML supports all data types with web presentation
            return Set(ReportDataType.allCases)
            
        case .markdown:
            // Markdown works well with text-based insights and structured data
            return [.csdInsights, .aiAnalysis, .stackHealth, .categoryMetrics, .appUsage]
            
        case .xlsx:
            // Excel supports most data types with spreadsheet analysis capabilities
            return Set(ReportDataType.allCases.filter { $0.supportsCSVExport || $0 == .csdInsights || $0 == .stackHealth })
        }
    }
    
    /// Check if this format is compatible with a specific data type
    func isCompatible(with dataType: ReportDataType) -> Bool {
        return compatibleDataTypes().contains(dataType)
    }
    
    // MARK: - Use Case Recommendations
    
    /// Primary use cases for this format
    var primaryUseCases: [String] {
        switch self {
        case .pdf:
            return ["Professional reports", "Executive summaries", "Client presentations", "Archive storage"]
            
        case .csv:
            return ["Data analysis", "Spreadsheet import", "Database loading", "Automation scripts"]
            
        case .json:
            return ["API integration", "Data backup", "System interoperability", "Custom analysis"]
            
        case .html:
            return ["Web sharing", "Interactive dashboards", "Online reports", "Email attachments"]
            
        case .markdown:
            return ["Documentation", "Wiki entries", "Version control", "Plain text archival"]
            
        case .xlsx:
            return ["Excel analysis", "Financial modeling", "Business intelligence", "Corporate reporting"]
        }
    }
    
    /// Target audience for this format
    var targetAudience: [String] {
        switch self {
        case .pdf:
            return ["Executives", "Clients", "Stakeholders", "General audience"]
            
        case .csv:
            return ["Data analysts", "Researchers", "Database administrators", "Automation engineers"]
            
        case .json:
            return ["Developers", "System integrators", "Data engineers", "API consumers"]
            
        case .html:
            return ["Web users", "Online collaborators", "Remote teams", "Dashboard viewers"]
            
        case .markdown:
            return ["Technical writers", "Developers", "Documentation teams", "Open source contributors"]
            
        case .xlsx:
            return ["Business analysts", "Finance teams", "Operations managers", "Excel power users"]
        }
    }
    
    // MARK: - Generation Requirements
    
    /// Indicates if this format requires special libraries or dependencies
    var requiresSpecialLibraries: Bool {
        switch self {
        case .xlsx:
            return true // Would need Excel export library
        case .pdf, .csv, .json, .html, .markdown:
            return false // Can be generated with standard frameworks
        }
    }
    
    /// Estimated generation complexity (1-5, higher is more complex)
    var generationComplexity: Int {
        switch self {
        case .json, .csv:
            return 1 // Direct data serialization
        case .markdown:
            return 2 // Simple text formatting
        case .html:
            return 3 // Template rendering with styling
        case .pdf:
            return 4 // Layout engine and rich formatting
        case .xlsx:
            return 5 // Complex spreadsheet structure and formatting
        }
    }
    
    // MARK: - Static Helper Methods
    
    /// Get recommended formats for specific use cases
    static func recommendedFormats(forUseCase useCase: ReportUseCase) -> [ReportFormat] {
        switch useCase {
        case .executiveSummary:
            return [.pdf, .html]
        case .dataAnalysis:
            return [.csv, .xlsx, .json]
        case .webSharing:
            return [.html, .pdf]
        case .systemIntegration:
            return [.json, .csv]
        case .documentation:
            return [.markdown, .html, .pdf]
        case .archival:
            return [.pdf, .json]
        }
    }
    
    /// Get formats sorted by generation complexity
    static var byComplexity: [ReportFormat] {
        return allCases.sorted { $0.generationComplexity < $1.generationComplexity }
    }
    
    /// Get formats that support rich presentation
    static var richFormats: [ReportFormat] {
        return allCases.filter { $0.supportsRichFormatting }
    }
    
    /// Get formats suitable for data export
    static var dataFormats: [ReportFormat] {
        return allCases.filter { $0.supportsDataAnalysis }
    }
}

// MARK: - Supporting Types

/// Common use cases for report generation
enum ReportUseCase: String, CaseIterable {
    case executiveSummary = "executive_summary"
    case dataAnalysis = "data_analysis"
    case webSharing = "web_sharing"
    case systemIntegration = "system_integration"
    case documentation = "documentation"
    case archival = "archival"
    
    var displayName: String {
        switch self {
        case .executiveSummary: return "Executive Summary"
        case .dataAnalysis: return "Data Analysis"
        case .webSharing: return "Web Sharing"
        case .systemIntegration: return "System Integration"
        case .documentation: return "Documentation"
        case .archival: return "Archival"
        }
    }
    
    var description: String {
        switch self {
        case .executiveSummary:
            return "High-level reports for decision makers and stakeholders"
        case .dataAnalysis:
            return "Raw data export for statistical analysis and processing"
        case .webSharing:
            return "Online reports for team collaboration and remote access"
        case .systemIntegration:
            return "Machine-readable formats for automated processing"
        case .documentation:
            return "Human-readable documentation and knowledge sharing"
        case .archival:
            return "Long-term storage and historical record keeping"
        }
    }
}
