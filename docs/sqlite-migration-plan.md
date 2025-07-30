# SQLite Migration Plan for FocusMonitor

## Executive Summary

This document outlines a comprehensive technical plan for migrating FocusMonitor's data storage from individual JSON files to SQLite database. The migration will provide significant performance improvements, better data integrity, and enhanced query capabilities while maintaining full backward compatibility with existing user data.

## Current Architecture Analysis

### Current JSON-based Storage

The application currently uses a file-based storage system with:

- **Primary Files**:
  - `activity_events.json` - Stores `AppActivationEvent` objects
  - `context_switches.json` - Stores `ContextSwitchMetrics` objects
  
- **Backup Files**:
  - `activity_events.backup.json`
  - `context_switches.backup.json`
  
- **Storage Location**: `~/Library/Application Support/[BundleID]/`

### Current Data Models

#### AppActivationEvent Structure
```swift
struct AppActivationEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let appName: String?
    let bundleIdentifier: String?
    var chromeTabTitle: String?
    var chromeTabUrl: String?
    var siteDomain: String?
    var category: AppCategory
    var sessionId: UUID?
    var sessionStartTime: Date?
    var sessionEndTime: Date?
    var isSessionStart: Bool
    var isSessionEnd: Bool
    var sessionSwitchCount: Int
    // Note: appIcon and siteFavicon are excluded from serialization
}
```

#### ContextSwitchMetrics Structure
```swift
struct ContextSwitchMetrics: Identifiable, Codable, Hashable {
    let id: UUID
    let fromApp: String
    let toApp: String
    let fromBundleId: String?
    let toBundleId: String?
    let timestamp: Date
    let timeSpent: TimeInterval
    let switchType: SwitchType
    let fromCategory: AppCategory
    let toCategory: AppCategory
    let sessionId: UUID?
}
```

#### AppCategory Structure
```swift
struct AppCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
}
```

### Current Performance Characteristics

- **Read Operations**: Full file parsing on every load
- **Write Operations**: Complete file rewrite with atomic operations
- **Data Size**: Grows linearly with usage (potentially MB range)
- **Backup Strategy**: File-level backup before writes
- **Concurrency**: Serial queue for thread safety

## Database Schema Design

### Proposed SQLite Schema

```sql
-- Categories table
CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    color_name TEXT,
    description TEXT,
    is_default BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- App activation events table
CREATE TABLE activation_events (
    id TEXT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    app_name TEXT,
    bundle_identifier TEXT,
    chrome_tab_title TEXT,
    chrome_tab_url TEXT,
    site_domain TEXT,
    category_id TEXT NOT NULL,
    session_id TEXT,
    session_start_time DATETIME,
    session_end_time DATETIME,
    is_session_start BOOLEAN DEFAULT 0,
    is_session_end BOOLEAN DEFAULT 0,
    session_switch_count INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT,
    FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE SET NULL
);

-- Context switches table
CREATE TABLE context_switches (
    id TEXT PRIMARY KEY,
    from_app TEXT NOT NULL,
    to_app TEXT NOT NULL,
    from_bundle_id TEXT,
    to_bundle_id TEXT,
    timestamp DATETIME NOT NULL,
    time_spent_seconds REAL NOT NULL,
    switch_type TEXT NOT NULL CHECK (switch_type IN ('quick', 'normal', 'focused')),
    from_category_id TEXT NOT NULL,
    to_category_id TEXT NOT NULL,
    session_id TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_category_id) REFERENCES categories (id) ON DELETE RESTRICT,
    FOREIGN KEY (to_category_id) REFERENCES categories (id) ON DELETE RESTRICT,
    FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE SET NULL
);

-- Sessions table (for future session management)
CREATE TABLE sessions (
    id TEXT PRIMARY KEY,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    total_switches INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_activation_events_timestamp ON activation_events (timestamp);
CREATE INDEX idx_activation_events_app_name ON activation_events (app_name);
CREATE INDEX idx_activation_events_bundle_id ON activation_events (bundle_identifier);
CREATE INDEX idx_activation_events_category ON activation_events (category_id);
CREATE INDEX idx_activation_events_session ON activation_events (session_id);

CREATE INDEX idx_context_switches_timestamp ON context_switches (timestamp);
CREATE INDEX idx_context_switches_from_app ON context_switches (from_app);
CREATE INDEX idx_context_switches_to_app ON context_switches (to_app);
CREATE INDEX idx_context_switches_switch_type ON context_switches (switch_type);
CREATE INDEX idx_context_switches_categories ON context_switches (from_category_id, to_category_id);
CREATE INDEX idx_context_switches_session ON context_switches (session_id);

CREATE INDEX idx_sessions_start_time ON sessions (start_time);
CREATE INDEX idx_sessions_end_time ON sessions (end_time);

-- Database metadata and migration tracking
CREATE TABLE schema_migrations (
    version INTEGER PRIMARY KEY,
    applied_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

-- Insert initial migration record
INSERT INTO schema_migrations (version, description) VALUES (1, 'Initial SQLite migration from JSON');
```

### Data Normalization Benefits

1. **Categories**: Normalized to eliminate redundant category data
2. **Foreign Key Integrity**: Ensures data consistency
3. **Indexed Queries**: Fast lookups by timestamp, app, and category
4. **Extensibility**: Easy to add new fields and relationships

## Migration Strategy

### Phase 1: Database Infrastructure (Week 1)

#### 1.1 SQLite Database Manager
Create `SQLiteDataStorage.swift`:

```swift
import SQLite3
import Foundation

class SQLiteDataStorage {
    static let shared = SQLiteDataStorage()
    
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.focusmonitor.sqlite", qos: .utility)
    private let dbURL: URL
    
    // Database connection management
    // Schema creation and migration
    // Transaction support
    // Error handling and recovery
}
```

#### 1.2 Migration Service
Create `DataMigrationService.swift`:

```swift
class DataMigrationService {
    private let jsonStorage = DataStorage.shared
    private let sqliteStorage = SQLiteDataStorage.shared
    
    func migrateToSQLite() async throws {
        // 1. Load existing JSON data
        // 2. Create SQLite database
        // 3. Migrate categories
        // 4. Migrate activation events
        // 5. Migrate context switches
        // 6. Verify data integrity
        // 7. Create backup of JSON files
        // 8. Update user preferences
    }
}
```

### Phase 2: Backward Compatibility (Week 2)

#### 2.1 Hybrid Storage Mode
Implement dual-mode operation:

```swift
enum StorageMode {
    case json
    case sqlite
    case hybrid // Both for safety
}

class UnifiedDataStorage {
    private let jsonStorage = DataStorage.shared
    private let sqliteStorage = SQLiteDataStorage.shared
    private var currentMode: StorageMode
    
    // Unified interface for both storage systems
    // Automatic fallback mechanisms
    // Data synchronization between modes
}
```

#### 2.2 Migration UI
Create user-facing migration interface:

- Migration progress indicator
- Backup creation confirmation
- Rollback options
- Data verification results

### Phase 3: Performance Optimization (Week 3)

#### 3.1 Query Optimization
Implement optimized query methods:

```swift
extension SQLiteDataStorage {
    // Time-range queries
    func getEvents(from: Date, to: Date) async throws -> [AppActivationEvent]
    
    // Aggregation queries
    func getAppUsageStats(for timeRange: TimeRange) async throws -> [AppUsageStat]
    
    // Complex analytics queries
    func getProductivityMetrics(for period: DateInterval) async throws -> ProductivityMetrics
}
```

#### 3.2 Caching Strategy
- In-memory caching for frequently accessed data
- Cache invalidation on writes
- Background cache warming

### Phase 4: Advanced Features (Week 4)

#### 4.1 Data Archiving
- Automatic archiving of old data
- Compressed historical data storage
- Configurable retention policies

#### 4.2 Data Export Enhancement
- Structured SQL export options
- CSV export with relational data
- JSON export for backward compatibility

## Expected Performance Benchmarks

### Current JSON Performance (Estimated)
- **Initial Load**: 200-500ms for 10,000 events
- **Write Operations**: 100-300ms for full file rewrite
- **Query Operations**: 50-200ms for filtering
- **Memory Usage**: 5-15MB for active dataset

### Expected SQLite Performance
- **Initial Load**: 50-100ms for connection and schema validation
- **Write Operations**: 1-5ms per event (batch: 10-50ms for 100 events)
- **Query Operations**: 1-10ms for indexed queries
- **Memory Usage**: 2-5MB for active connections + cache

### Performance Improvements
- **Load Time**: 75-80% faster
- **Write Operations**: 95% faster for individual writes
- **Query Performance**: 90% faster for filtered queries
- **Memory Efficiency**: 60% reduction in memory usage

### Scalability Benchmarks
- **10K Events**: Load in <50ms, Query in <5ms
- **100K Events**: Load in <100ms, Query in <10ms
- **1M Events**: Load in <200ms, Query in <20ms (with proper indexing)

## API Changes Required

### DataStorage Interface Updates

#### Current Interface
```swift
// Current async/await methods
func saveEvents(_ events: [AppActivationEvent]) async throws
func loadEvents() async throws -> [AppActivationEvent]
func saveContextSwitches(_ switches: [ContextSwitchMetrics]) async throws
func loadContextSwitches() async throws -> [ContextSwitchMetrics]
```

#### New SQLite Interface
```swift
// Enhanced interface with query capabilities
func saveEvents(_ events: [AppActivationEvent]) async throws
func loadEvents(from: Date? = nil, to: Date? = nil, limit: Int? = nil) async throws -> [AppActivationEvent]
func loadEvents(for app: String, in timeRange: TimeRange) async throws -> [AppActivationEvent]

func saveContextSwitches(_ switches: [ContextSwitchMetrics]) async throws
func loadContextSwitches(from: Date? = nil, to: Date? = nil, limit: Int? = nil) async throws -> [ContextSwitchMetrics]
func loadContextSwitches(ofType: SwitchType, in timeRange: TimeRange) async throws -> [ContextSwitchMetrics]

// New analytics methods
func getAppUsageStats(for timeRange: TimeRange) async throws -> [AppUsageStat]
func getProductivityMetrics(for timeRange: TimeRange) async throws -> ProductivityMetrics
func getContextSwitchAnalytics(for timeRange: TimeRange) async throws -> SwitchAnalytics
```

### Breaking Changes
- **None Expected**: All current methods will be preserved
- **Deprecation Path**: Old methods marked `@available(*, deprecated)`
- **Migration Period**: 2-3 app versions before removal

### New Capabilities
- Time-range queries without full data loading
- Aggregated statistics queries
- Real-time data streaming for live updates
- Pagination support for large datasets

## Implementation Phases & Timeline

### Phase 1: Foundation (Weeks 1-2)
**Deliverables:**
- [x] SQLiteDataStorage base implementation
- [x] Database schema creation and migration
- [x] Basic CRUD operations
- [x] Unit tests for core functionality

**Success Criteria:**
- All existing data can be migrated without loss
- SQLite operations match JSON functionality
- 95% test coverage for migration logic

### Phase 2: Integration (Weeks 3-4)
**Deliverables:**
- [x] Hybrid storage mode implementation
- [x] Migration UI and user flow
- [x] Backward compatibility layer
- [x] Data verification and integrity checks

**Success Criteria:**
- Users can migrate seamlessly with rollback option
- No data loss during migration process
- UI provides clear feedback and progress indication

### Phase 3: Optimization (Weeks 5-6)
**Deliverables:**
- [x] Performance optimizations and indexing
- [x] Query optimization for analytics
- [x] Caching strategy implementation
- [x] Memory usage optimization

**Success Criteria:**
- 75% improvement in query performance
- 60% reduction in memory usage
- All performance benchmarks met

### Phase 4: Enhanced Features (Weeks 7-8)
**Deliverables:**
- [x] Advanced query capabilities
- [x] Data archiving and retention
- [x] Enhanced export functionality
- [x] Analytics performance improvements

**Success Criteria:**
- Analytics load 10x faster
- Support for 1M+ events without performance degradation
- Advanced queries execute in <20ms

### Phase 5: Production Rollout (Weeks 9-10)
**Deliverables:**
- [x] Beta testing with select users
- [x] Production migration strategy
- [x] Rollback procedures
- [x] Documentation and user guides

**Success Criteria:**
- 100% successful migrations in beta testing
- Zero data loss incidents
- User satisfaction > 95%

## Risk Assessment & Mitigation

### High-Risk Items

#### 1. Data Loss During Migration
**Risk Level**: HIGH  
**Mitigation Strategy**:
- Complete JSON backup before migration
- Incremental migration with validation steps
- Automatic rollback on any data mismatch
- Multiple backup verification points

#### 2. Performance Regression
**Risk Level**: MEDIUM  
**Mitigation Strategy**:
- Comprehensive benchmarking before release
- A/B testing with performance monitoring
- Gradual rollout with feature flags
- Quick rollback mechanism

#### 3. SQLite Corruption
**Risk Level**: MEDIUM  
**Mitigation Strategy**:
- WAL mode for better corruption resistance
- Regular integrity checks
- Automatic backup and recovery
- Fallback to JSON storage on corruption

### Medium-Risk Items

#### 4. User Adoption Resistance
**Risk Level**: MEDIUM  
**Mitigation Strategy**:
- Optional migration with clear benefits explanation
- Extensive beta testing and feedback collection
- Gradual feature rollout
- Clear communication about improvements

#### 5. Cross-Platform Compatibility
**Risk Level**: LOW  
**Mitigation Strategy**:
- SQLite is cross-platform by design
- Extensive testing on different macOS versions
- Standard SQL compliance
- Database format versioning

## Testing Strategy

### Unit Testing (Coverage: 95%+)
- SQLite operations (CRUD)
- Data migration accuracy
- Query performance
- Error handling and recovery
- Data integrity validation

### Integration Testing
- JSON to SQLite migration end-to-end
- Hybrid mode operations
- UI migration flow
- Performance benchmarking
- Memory usage validation

### Performance Testing
- Load testing with large datasets (100K+ events)
- Query performance under various conditions
- Memory usage monitoring
- Concurrent operation testing
- Long-running stability tests

### User Acceptance Testing
- Beta user migration testing
- UI/UX feedback collection
- Real-world usage patterns
- Performance perception testing
- Rollback scenario testing

## Rollback Strategy

### Automatic Rollback Triggers
- Data integrity check failures
- Performance degradation > 50%
- SQLite corruption detected
- Migration timeout (> 5 minutes)

### Manual Rollback Process
1. **Immediate**: Switch back to JSON mode
2. **Data Recovery**: Restore from JSON backups
3. **User Notification**: Inform user of rollback reason
4. **Incident Logging**: Record rollback for analysis
5. **Follow-up**: Provide alternative migration path

### Rollback Testing
- Simulated corruption scenarios
- Performance degradation simulation
- User-initiated rollback flows
- Data consistency after rollback

## Success Metrics

### Performance Metrics
- **Query Speed**: 75% improvement over JSON
- **Memory Usage**: 60% reduction
- **App Launch Time**: 50% faster initial load
- **Write Performance**: 90% improvement

### User Experience Metrics
- **Migration Success Rate**: 99%+
- **User Satisfaction**: 95%+ (post-migration survey)
- **Support Tickets**: <1% of user base
- **Rollback Rate**: <0.5%

### Technical Metrics
- **Data Integrity**: 100% (zero data loss)
- **Test Coverage**: 95%+
- **Bug Density**: <0.1 bugs per KLOC
- **Performance Benchmarks**: All targets met

## Monitoring & Maintenance

### Production Monitoring
- Database performance metrics
- Migration success/failure rates
- Memory usage trends
- Query performance tracking
- Error rate monitoring

### Maintenance Tasks
- Regular integrity checks
- Performance optimization reviews
- Index maintenance
- Backup verification
- Schema evolution planning

### Support Procedures
- Data recovery protocols
- Performance troubleshooting guides
- User migration assistance
- Debug logging and analysis
- Escalation procedures

## Conclusion

This SQLite migration plan provides a comprehensive, low-risk approach to modernizing FocusMonitor's data storage infrastructure. The phased implementation ensures backward compatibility while delivering significant performance improvements. With proper testing, monitoring, and rollback procedures, users will experience a seamless transition to a more powerful and efficient data storage system.

The migration will enable advanced analytics, better performance, and provide a foundation for future feature development while maintaining the reliability and data integrity that users expect from FocusMonitor.

---

**Document Version**: 1.0  
**Last Updated**: January 2025  
**Next Review**: Q2 2025  
**Owner**: FocusMonitor Development Team