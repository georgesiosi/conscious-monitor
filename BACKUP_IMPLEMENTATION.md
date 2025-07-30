# Analysis Storage Backup System Implementation

## Overview
This document outlines the comprehensive backup system implemented for the AnalysisStorageService in FocusMonitor. The system provides automatic backup creation, corruption recovery, and cleanup management for individual analysis files.

## Key Features Implemented

### 1. Automatic Backup Creation
- **Backup on Save**: Creates backup files before overwriting existing analysis files
- **Timestamped Backups**: Each backup includes timestamp for chronological ordering
- **Backup File Naming**: Format: `original_name.backup.YYYY-MM-DD_HH-mm-ss.json`
- **Backup Directory**: Separate `analyses_backup/` directory for organization

### 2. Corruption Detection and Recovery
- **Validation**: Comprehensive validation of analysis data before save/load
- **Automatic Recovery**: Attempts to recover from backup when main file is corrupted
- **Multiple Backup Support**: Tries newest backup first, falls back to older ones
- **Data Integrity**: Verifies written data matches expected data

### 3. Backup Management
- **Configurable Retention**: Keeps 3 most recent backups per file (configurable)
- **Automatic Cleanup**: Daily cleanup of backups older than 30 days
- **Manual Cleanup**: `forceBackupCleanup()` method for maintenance
- **Orphan Management**: Removes backup files when analysis is deleted

### 4. Performance Optimizations
- **Async Operations**: All backup operations on background queue
- **Lazy Backup Creation**: Only creates backups when files actually exist
- **Efficient Cleanup**: Batch operations for better performance
- **Memory Efficiency**: Streams data instead of loading entire files

## Directory Structure

```
~/Library/Application Support/com.focusmonitor.FocusMonitor/
├── analyses/                    # Main analysis files
│   ├── 2024-01-15_workstyle_abc12345.json
│   ├── 2024-01-16_productivity_def67890.json
│   └── ...
└── analyses_backup/            # Backup files
    ├── 2024-01-15_workstyle_abc12345.backup.2024-01-15_10-30-45.json
    ├── 2024-01-15_workstyle_abc12345.backup.2024-01-15_14-20-15.json
    └── ...
```

## API Methods

### New Public Methods
- `addAnalysis(_ analysis: AnalysisEntry) async throws` - Async version with backup support
- `removeAnalysis(withId id: UUID) async throws` - Async version with backup cleanup
- `getBackupInfo() -> [String: Any]` - Diagnostics information
- `forceBackupCleanup()` - Manual cleanup trigger

### Enhanced Error Handling
- `AnalysisStorageError.backupFailed` - Backup operation failures
- `AnalysisStorageError.recoveryFailed` - Recovery operation failures
- Notification system for error reporting

## Configuration Options

### Backup Settings
- `maxBackupsPerFile: Int = 3` - Maximum backups per analysis file
- `backupRetentionDays: Int = 30` - Days to retain backup files
- Backup directory: `analyses_backup/` (automatically created)

### Performance Settings
- Background queue for all file operations
- Atomic write operations for data integrity
- Lazy loading and cleanup operations

## Error Recovery Process

1. **Load Attempt**: Try to load analysis from main file
2. **Validation**: Validate loaded data structure and content
3. **Backup Recovery**: If main file fails, attempt backup recovery
4. **Backup Validation**: Validate recovered backup data
5. **Restoration**: Restore main file from valid backup
6. **Fallback**: Try next newest backup if current one fails

## Validation Rules

### Analysis Entry Validation
- Non-empty insights and analysis type
- Non-negative data points and event counts
- Valid date ranges (start ≤ end)
- Reasonable timestamp (not too far in future)

### Data Integrity Validation
- Written data matches expected data
- JSON structure is valid and decodable
- All required fields are present

## Usage Examples

### Basic Usage (Unchanged)
```swift
// Existing synchronous API still works
AnalysisStorageService.shared.addAnalysis(analysis)
AnalysisStorageService.shared.removeAnalysis(withId: analysisId)
```

### New Async API
```swift
// Use async versions for better error handling
try await AnalysisStorageService.shared.addAnalysis(analysis)
try await AnalysisStorageService.shared.removeAnalysis(withId: analysisId)
```

### Backup Management
```swift
// Get backup information
let backupInfo = AnalysisStorageService.shared.getBackupInfo()
print("Total backups: \(backupInfo["totalBackupFiles"] ?? 0)")

// Force cleanup (for maintenance)
AnalysisStorageService.shared.forceBackupCleanup()
```

## Benefits

### Data Protection
- **Prevents Data Loss**: Automatic backups protect against file corruption
- **Multiple Recovery Points**: Multiple backups provide recovery options
- **Automatic Recovery**: Seamless recovery without user intervention

### Performance
- **Background Operations**: No impact on UI responsiveness
- **Efficient Storage**: Configurable retention prevents disk bloat
- **Lazy Operations**: Only creates backups when needed

### Maintainability
- **Clear Architecture**: Modular design following existing patterns
- **Comprehensive Logging**: Detailed logs for debugging
- **Error Notification**: Integration with existing error handling

## Testing Recommendations

1. **Corruption Testing**: Manually corrupt analysis files to test recovery
2. **Backup Cleanup**: Verify old backups are cleaned up correctly
3. **Performance Testing**: Ensure backup operations don't impact UI
4. **Edge Cases**: Test with empty files, invalid JSON, etc.

## Future Enhancements

1. **Backup Compression**: Compress older backups to save space
2. **Remote Backup**: Optional iCloud or external backup support
3. **Backup Verification**: Periodic integrity checks of backup files
4. **User Configuration**: Allow users to configure backup settings

## Implementation Notes

- Maintains backward compatibility with existing code
- Follows SwiftUI/Combine reactive patterns
- Uses same error handling patterns as DataStorage.swift
- Thread-safe operations with serial queue
- Comprehensive logging for debugging and monitoring

The backup system provides robust data protection while maintaining excellent performance and user experience. The implementation is production-ready and follows enterprise-grade backup practices.