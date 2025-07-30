import Foundation
import SwiftUI

// MARK: - Report Generation Result Types

/// Result of a report generation operation
struct ReportResult: Identifiable, Codable {
    let id: UUID
    let configuration: ReportConfiguration
    let status: ReportStatus
    let fileURL: URL?
    let fileName: String?
    let fileSize: Int64? // Size in bytes
    let generatedAt: Date
    let generationDuration: TimeInterval // Time taken to generate in seconds
    let metadata: ReportMetadata
    let error: ReportError?
    
    init(
        id: UUID = UUID(),
        configuration: ReportConfiguration,
        status: ReportStatus,
        fileURL: URL? = nil,
        fileName: String? = nil,
        fileSize: Int64? = nil,
        generatedAt: Date = Date(),
        generationDuration: TimeInterval = 0,
        metadata: ReportMetadata = ReportMetadata(),
        error: ReportError? = nil
    ) {
        self.id = id
        self.configuration = configuration
        self.status = status
        self.fileURL = fileURL
        self.fileName = fileName
        self.fileSize = fileSize
        self.generatedAt = generatedAt
        self.generationDuration = generationDuration
        self.metadata = metadata
        self.error = error
    }
    
    // MARK: - Convenience Properties
    
    /// Human-readable file size
    var formattedFileSize: String {
        guard let fileSize = fileSize else { return "Unknown" }
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    /// Human-readable generation duration
    var formattedDuration: String {
        if generationDuration < 1 {
            return "< 1 second"
        } else if generationDuration < 60 {
            return "\(Int(generationDuration)) seconds"
        } else {
            let minutes = Int(generationDuration / 60)
            let seconds = Int(generationDuration.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(seconds)s"
        }
    }
    
    /// Check if the report file exists at the specified URL
    var fileExists: Bool {
        guard let fileURL = fileURL else { return false }
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    /// Check if the report generation was successful
    var isSuccess: Bool {
        return status == .completed && error == nil
    }
    
    /// Get a shareable file URL if available
    var shareableURL: URL? {
        guard isSuccess, let fileURL = fileURL, fileExists else { return nil }
        return fileURL
    }
    
    // MARK: - Static Factory Methods
    
    /// Create a successful report result
    static func success(
        configuration: ReportConfiguration,
        fileURL: URL,
        fileName: String,
        fileSize: Int64,
        generationDuration: TimeInterval,
        metadata: ReportMetadata
    ) -> ReportResult {
        return ReportResult(
            configuration: configuration,
            status: .completed,
            fileURL: fileURL,
            fileName: fileName,
            fileSize: fileSize,
            generationDuration: generationDuration,
            metadata: metadata
        )
    }
    
    /// Create a failed report result
    static func failure(
        configuration: ReportConfiguration,
        error: ReportError,
        generationDuration: TimeInterval = 0
    ) -> ReportResult {
        return ReportResult(
            configuration: configuration,
            status: .failed,
            generationDuration: generationDuration,
            error: error
        )
    }
    
    /// Create an in-progress report result
    static func inProgress(
        configuration: ReportConfiguration,
        metadata: ReportMetadata = ReportMetadata()
    ) -> ReportResult {
        return ReportResult(
            configuration: configuration,
            status: .generating,
            metadata: metadata
        )
    }
}

// MARK: - Report Status

/// Status of report generation
enum ReportStatus: String, CaseIterable, Codable {
    case queued = "queued"
    case generating = "generating"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .queued: return "Queued"
        case .generating: return "Generating"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var description: String {
        switch self {
        case .queued:
            return "Report is queued for generation"
        case .generating:
            return "Report is currently being generated"
        case .completed:
            return "Report generation completed successfully"
        case .failed:
            return "Report generation failed"
        case .cancelled:
            return "Report generation was cancelled"
        }
    }
    
    var icon: String {
        switch self {
        case .queued: return "clock"
        case .generating: return "gear"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "minus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .queued: return .orange
        case .generating: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
    
    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .queued, .generating:
            return false
        }
    }
    
    var canRetry: Bool {
        switch self {
        case .failed, .cancelled:
            return true
        case .queued, .generating, .completed:
            return false
        }
    }
}

// MARK: - Report Error

/// Comprehensive error types for report generation
enum ReportError: Error, Codable, Equatable, Hashable {
    case invalidConfiguration(String)
    case dataUnavailable(String)
    case insufficientData(String)
    case processingError(String)
    case fileSystemError(String)
    case aiServiceError(String)
    case networkError(String)
    case memoryError(String)
    case timeoutError(String)
    case formatNotSupported(String)
    case permissionDenied(String)
    case diskSpaceError(String)
    case unknownError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidConfiguration(let message):
            return "Invalid Configuration: \(message)"
        case .dataUnavailable(let message):
            return "Data Unavailable: \(message)"
        case .insufficientData(let message):
            return "Insufficient Data: \(message)"
        case .processingError(let message):
            return "Processing Error: \(message)"
        case .fileSystemError(let message):
            return "File System Error: \(message)"
        case .aiServiceError(let message):
            return "AI Service Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .memoryError(let message):
            return "Memory Error: \(message)"
        case .timeoutError(let message):
            return "Timeout Error: \(message)"
        case .formatNotSupported(let message):
            return "Format Not Supported: \(message)"
        case .permissionDenied(let message):
            return "Permission Denied: \(message)"
        case .diskSpaceError(let message):
            return "Disk Space Error: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
    
    var category: ErrorCategory {
        switch self {
        case .invalidConfiguration, .formatNotSupported:
            return .configuration
        case .dataUnavailable, .insufficientData:
            return .data
        case .processingError, .memoryError, .timeoutError:
            return .processing
        case .fileSystemError, .permissionDenied, .diskSpaceError:
            return .fileSystem
        case .aiServiceError, .networkError:
            return .external
        case .unknownError:
            return .unknown
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .networkError, .aiServiceError, .timeoutError, .memoryError, .diskSpaceError:
            return true
        case .invalidConfiguration, .dataUnavailable, .insufficientData, .processingError, .fileSystemError, .formatNotSupported, .permissionDenied, .unknownError:
            return false
        }
    }
    
    var userGuidance: String {
        switch self {
        case .invalidConfiguration:
            return "Please check your report configuration settings and try again."
        case .dataUnavailable:
            return "The requested data is not available. Try adjusting your date range or data filters."
        case .insufficientData:
            return "Not enough data for the selected time period. Try expanding your date range."
        case .processingError:
            return "An error occurred while processing your data. Please try again."
        case .fileSystemError:
            return "Unable to save the report file. Check available disk space and permissions."
        case .aiServiceError:
            return "AI analysis is currently unavailable. Try generating the report without AI insights."
        case .networkError:
            return "Network connection issue. Check your internet connection and try again."
        case .memoryError:
            return "Insufficient memory to generate the report. Try reducing the data scope or closing other applications."
        case .timeoutError:
            return "Report generation timed out. Try reducing the amount of data or simplifying the report."
        case .formatNotSupported:
            return "The selected export format is not supported for this data type. Try a different format."
        case .permissionDenied:
            return "Permission denied to save the file. Check folder permissions or choose a different location."
        case .diskSpaceError:
            return "Insufficient disk space to save the report. Free up some space and try again."
        case .unknownError:
            return "An unexpected error occurred. Please try again or contact support."
        }
    }
    
    var icon: String {
        switch category {
        case .configuration: return "gear.badge.xmark"
        case .data: return "doc.badge.exclamationmark"
        case .processing: return "cpu.badge.xmark"
        case .fileSystem: return "folder.badge.minus"
        case .external: return "network.badge.shield.half.filled"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Error Category

enum ErrorCategory: String, CaseIterable {
    case configuration = "configuration"
    case data = "data"
    case processing = "processing"
    case fileSystem = "file_system"
    case external = "external"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .configuration: return "Configuration"
        case .data: return "Data"
        case .processing: return "Processing"
        case .fileSystem: return "File System"
        case .external: return "External Service"
        case .unknown: return "Unknown"
        }
    }
}

// MARK: - Report Metadata

/// Metadata about the generated report
struct ReportMetadata: Codable {
    let generatorVersion: String
    let dataSourceVersion: String
    let totalDataPoints: Int
    let dateRangeActual: DateInterval?
    let includedDataTypes: Set<ReportDataType>
    let processingSteps: [ProcessingStep]
    let warnings: [String]
    let performanceMetrics: PerformanceMetrics?
    
    init(
        generatorVersion: String = "1.0.0",
        dataSourceVersion: String = "1.0.0",
        totalDataPoints: Int = 0,
        dateRangeActual: DateInterval? = nil,
        includedDataTypes: Set<ReportDataType> = [],
        processingSteps: [ProcessingStep] = [],
        warnings: [String] = [],
        performanceMetrics: PerformanceMetrics? = nil
    ) {
        self.generatorVersion = generatorVersion
        self.dataSourceVersion = dataSourceVersion
        self.totalDataPoints = totalDataPoints
        self.dateRangeActual = dateRangeActual
        self.includedDataTypes = includedDataTypes
        self.processingSteps = processingSteps
        self.warnings = warnings
        self.performanceMetrics = performanceMetrics
    }
}

// MARK: - Processing Step

/// Represents a step in the report generation process
struct ProcessingStep: Codable {
    let name: String
    let description: String
    let startTime: Date
    let endTime: Date?
    let status: StepStatus
    let itemsProcessed: Int
    let warnings: [String]
    
    var duration: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }
    
    enum StepStatus: String, Codable {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"
        case failed = "failed"
        case skipped = "skipped"
    }
}

// MARK: - Performance Metrics

/// Performance metrics for report generation
struct PerformanceMetrics: Codable {
    let dataLoadTime: TimeInterval
    let processingTime: TimeInterval
    let renderingTime: TimeInterval
    let totalMemoryUsed: Int64? // Peak memory usage in bytes
    let cacheHitRate: Double? // Cache hit rate (0.0 - 1.0)
    let optimizationsApplied: [String]
    
    var totalTime: TimeInterval {
        return dataLoadTime + processingTime + renderingTime
    }
    
    var formattedMemoryUsage: String? {
        guard let memory = totalMemoryUsed else { return nil }
        return ByteCountFormatter.string(fromByteCount: memory, countStyle: .memory)
    }
}

// MARK: - Report Queue Item

/// Represents a report in the generation queue
struct ReportQueueItem: Identifiable, Codable {
    let id: UUID
    let configuration: ReportConfiguration
    let priority: QueuePriority
    let queuedAt: Date
    let estimatedDuration: TimeInterval?
    let dependencies: [UUID] // Other reports this depends on
    
    init(
        id: UUID = UUID(),
        configuration: ReportConfiguration,
        priority: QueuePriority = .normal,
        queuedAt: Date = Date(),
        estimatedDuration: TimeInterval? = nil,
        dependencies: [UUID] = []
    ) {
        self.id = id
        self.configuration = configuration
        self.priority = priority
        self.queuedAt = queuedAt
        self.estimatedDuration = estimatedDuration
        self.dependencies = dependencies
    }
    
    var waitTime: TimeInterval {
        return Date().timeIntervalSince(queuedAt)
    }
    
    var formattedWaitTime: String {
        let minutes = Int(waitTime / 60)
        let seconds = Int(waitTime.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Queue Priority

enum QueuePriority: Int, CaseIterable, Codable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .normal: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .normal: return "circle"
        case .high: return "arrow.up.circle"
        case .urgent: return "exclamationmark.circle.fill"
        }
    }
}
