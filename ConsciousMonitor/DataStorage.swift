import Foundation

class DataStorage {
    static let shared = DataStorage() // Singleton for easy access

    private var eventsStorageURL: URL
    private var contextSwitchesStorageURL: URL
    private var eventsBackupURL: URL
    private var contextSwitchesBackupURL: URL
    private let appDir: URL
    
    // Serial queue for thread-safe file operations
    private let fileQueue = DispatchQueue(label: "com.focusmonitor.dataStorage", qos: .utility)
    
    // Data validation and error handling
    enum DataStorageError: Error {
        case fileCorrupted(String)
        case backupFailed(String)
        case validationFailed(String)
        case diskSpaceInsufficient
        
        var localizedDescription: String {
            switch self {
            case .fileCorrupted(let message):
                return "Data file corrupted: \(message)"
            case .backupFailed(let message):
                return "Backup failed: \(message)"
            case .validationFailed(let message):
                return "Data validation failed: \(message)"
            case .diskSpaceInsufficient:
                return "Insufficient disk space for data operation"
            }
        }
    }

    private init() {
        // Get the Application Support directory URL
        guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Unable to get Application Support directory.")
        }
        
        let bundleID = Bundle.main.bundleIdentifier ?? "com.example.FocusMonitor"
        let appDir = appSupportDir.appendingPathComponent(bundleID, isDirectory: true)
        
        // Create the app-specific directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: appDir.path) {
            do {
                try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true, attributes: nil)
                print("Created Application Support directory at: \(appDir.path)")
            } catch {
                fatalError("Unable to create Application Support directory: \(error.localizedDescription)")
            }
        }
        
        self.appDir = appDir
        self.eventsStorageURL = appDir.appendingPathComponent("activity_events.json")
        self.contextSwitchesStorageURL = appDir.appendingPathComponent("context_switches.json")
        self.eventsBackupURL = appDir.appendingPathComponent("activity_events.backup.json")
        self.contextSwitchesBackupURL = appDir.appendingPathComponent("context_switches.backup.json")
        print("Data storage URLs: \n- Events: \(eventsStorageURL.path)\n- Context Switches: \(contextSwitchesStorageURL.path)")
    }

    // MARK: - Public Methods for App Activation Events

    func saveEvents(_ events: [AppActivationEvent], completion: @escaping (Result<Void, DataStorageError>) -> Void = { _ in }) {
        fileQueue.async {
            do {
                // Validate data before saving
                try self.validateEvents(events)
                
                // Create backup before writing
                try self.createEventsBackup()
                
                // Check disk space
                try self.checkDiskSpace()
                
                // Encode data
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(events)
                
                // Write atomically
                try data.write(to: self.eventsStorageURL, options: .atomic)
                
                print("Successfully saved \(events.count) events to \(self.eventsStorageURL.path)")
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch let error as DataStorageError {
                print("Data storage error saving events: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } catch {
                let storageError = DataStorageError.fileCorrupted("Failed to save events: \(error.localizedDescription)")
                print("Error saving events: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(storageError))
                }
            }
        }
    }

    func loadEvents(completion: @escaping (Result<[AppActivationEvent], DataStorageError>) -> Void) {
        fileQueue.async {
            do {
                // Try to load from main file first
                let events = try self.loadEventsFromFile(self.eventsStorageURL)
                
                // Validate loaded data
                try self.validateEvents(events)
                
                print("Successfully loaded \(events.count) events from \(self.eventsStorageURL.path)")
                
                DispatchQueue.main.async {
                    completion(.success(events))
                }
            } catch {
                print("Error loading events from main file: \(error.localizedDescription)")
                
                // Try to recover from backup
                do {
                    let backupEvents = try self.loadEventsFromFile(self.eventsBackupURL)
                    try self.validateEvents(backupEvents)
                    
                    print("Successfully recovered \(backupEvents.count) events from backup")
                    
                    // Restore main file from backup
                    try self.restoreEventsFromBackup()
                    
                    DispatchQueue.main.async {
                        completion(.success(backupEvents))
                    }
                } catch {
                    print("Failed to recover from backup: \(error.localizedDescription)")
                    let storageError = DataStorageError.fileCorrupted("Both main and backup files are corrupted or missing")
                    
                    DispatchQueue.main.async {
                        completion(.failure(storageError))
                    }
                }
            }
        }
    }
    
    // MARK: - Public Methods for Context Switches
    
    func saveContextSwitches(_ switches: [ContextSwitchMetrics], completion: @escaping (Result<Void, DataStorageError>) -> Void = { _ in }) {
        fileQueue.async {
            do {
                // Validate data before saving
                try self.validateContextSwitches(switches)
                
                // Create backup before writing
                try self.createContextSwitchesBackup()
                
                // Check disk space
                try self.checkDiskSpace()
                
                // Encode data
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(switches)
                
                // Write atomically
                try data.write(to: self.contextSwitchesStorageURL, options: .atomic)
                
                print("Successfully saved \(switches.count) context switches to \(self.contextSwitchesStorageURL.path)")
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch let error as DataStorageError {
                print("Data storage error saving context switches: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } catch {
                let storageError = DataStorageError.fileCorrupted("Failed to save context switches: \(error.localizedDescription)")
                print("Error saving context switches: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(storageError))
                }
            }
        }
    }

    func loadContextSwitches(completion: @escaping (Result<[ContextSwitchMetrics], DataStorageError>) -> Void) {
        fileQueue.async {
            do {
                // Try to load from main file first
                let switches = try self.loadContextSwitchesFromFile(self.contextSwitchesStorageURL)
                
                // Validate loaded data
                try self.validateContextSwitches(switches)
                
                print("Successfully loaded \(switches.count) context switches from \(self.contextSwitchesStorageURL.path)")
                
                DispatchQueue.main.async {
                    completion(.success(switches))
                }
            } catch {
                print("Error loading context switches from main file: \(error.localizedDescription)")
                
                // Try to recover from backup
                do {
                    let backupSwitches = try self.loadContextSwitchesFromFile(self.contextSwitchesBackupURL)
                    try self.validateContextSwitches(backupSwitches)
                    
                    print("Successfully recovered \(backupSwitches.count) context switches from backup")
                    
                    // Restore main file from backup
                    try self.restoreContextSwitchesFromBackup()
                    
                    DispatchQueue.main.async {
                        completion(.success(backupSwitches))
                    }
                } catch {
                    print("Failed to recover from backup: \(error.localizedDescription)")
                    let storageError = DataStorageError.fileCorrupted("Both main and backup files are corrupted or missing")
                    
                    DispatchQueue.main.async {
                        completion(.failure(storageError))
                    }
                }
            }
        }
    }
    
    // MARK: - Modern Async/Await Methods
    
    /// Save events using async/await pattern
    func saveEvents(_ events: [AppActivationEvent]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            saveEvents(events) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Load events using async/await pattern  
    func loadEvents() async throws -> [AppActivationEvent] {
        return try await withCheckedThrowingContinuation { continuation in
            loadEvents { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Save context switches using async/await pattern
    func saveContextSwitches(_ switches: [ContextSwitchMetrics]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            saveContextSwitches(switches) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Load context switches using async/await pattern
    func loadContextSwitches() async throws -> [ContextSwitchMetrics] {
        return try await withCheckedThrowingContinuation { continuation in
            loadContextSwitches { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Clear events using async/await pattern
    func clearEvents() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            clearEvents { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Clear context switches using async/await pattern
    func clearContextSwitches() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            clearContextSwitches { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - Data Management Methods
    
    // Method to clear all data (async)
    func clearAllData(completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        clearEvents { [weak self] eventsResult in
            switch eventsResult {
            case .success:
                self?.clearContextSwitches { switchesResult in
                    completion(switchesResult)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Method to clear all data using async/await pattern
    func clearAllData() async throws {
        try await clearEvents()
        try await clearContextSwitches()
    }
    
    // Method to clear events data (async)
    func clearEvents(completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        fileQueue.async {
            do {
                if FileManager.default.fileExists(atPath: self.eventsStorageURL.path) {
                    try FileManager.default.removeItem(at: self.eventsStorageURL)
                    print("Successfully cleared events data file at \(self.eventsStorageURL.path)")
                }
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                print("Error clearing events: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Method to clear context switches data (async)
    func clearContextSwitches(completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        fileQueue.async {
            do {
                if FileManager.default.fileExists(atPath: self.contextSwitchesStorageURL.path) {
                    try FileManager.default.removeItem(at: self.contextSwitchesStorageURL)
                    print("Successfully cleared context switches data file at \(self.contextSwitchesStorageURL.path)")
                }
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                print("Error clearing context switches: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Method to migrate data from UserDefaults to file storage
    func migrateFromUserDefaults() {
        // Migrate activation events
        if let data = UserDefaults.standard.data(forKey: "activationEvents"),
           let events = try? JSONDecoder().decode([AppActivationEvent].self, from: data) {
            saveEvents(events) { result in
                switch result {
                case .success:
                    print("Migrated \(events.count) activation events from UserDefaults to file storage")
                    // Clear UserDefaults after successful migration
                    UserDefaults.standard.removeObject(forKey: "activationEvents")
                case .failure(let error):
                    print("Failed to migrate events: \(error.localizedDescription)")
                }
            }
        }
        
        // Migrate context switches
        if let data = UserDefaults.standard.data(forKey: "contextSwitches"),
           let switches = try? JSONDecoder().decode([ContextSwitchMetrics].self, from: data) {
            saveContextSwitches(switches) { result in
                switch result {
                case .success:
                    print("Migrated \(switches.count) context switches from UserDefaults to file storage")
                    // Clear UserDefaults after successful migration
                    UserDefaults.standard.removeObject(forKey: "contextSwitches")
                case .failure(let error):
                    print("Failed to migrate context switches: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func loadEventsFromFile(_ url: URL) throws -> [AppActivationEvent] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return [] // Return empty array if file doesn't exist
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let events = try decoder.decode([AppActivationEvent].self, from: data)
        // Ensure loaded events are in chronological order
        return events.sorted { $0.timestamp < $1.timestamp }
    }
    
    private func loadContextSwitchesFromFile(_ url: URL) throws -> [ContextSwitchMetrics] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return [] // Return empty array if file doesn't exist
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([ContextSwitchMetrics].self, from: data)
    }
    
    private func createEventsBackup() throws {
        if FileManager.default.fileExists(atPath: eventsStorageURL.path) {
            // Remove existing backup first
            if FileManager.default.fileExists(atPath: eventsBackupURL.path) {
                try FileManager.default.removeItem(at: eventsBackupURL)
            }
            try FileManager.default.copyItem(at: eventsStorageURL, to: eventsBackupURL)
        }
    }
    
    private func createContextSwitchesBackup() throws {
        if FileManager.default.fileExists(atPath: contextSwitchesStorageURL.path) {
            // Remove existing backup first
            if FileManager.default.fileExists(atPath: contextSwitchesBackupURL.path) {
                try FileManager.default.removeItem(at: contextSwitchesBackupURL)
            }
            try FileManager.default.copyItem(at: contextSwitchesStorageURL, to: contextSwitchesBackupURL)
        }
    }
    
    private func restoreEventsFromBackup() throws {
        if FileManager.default.fileExists(atPath: eventsBackupURL.path) {
            // Remove corrupted main file first
            if FileManager.default.fileExists(atPath: eventsStorageURL.path) {
                try FileManager.default.removeItem(at: eventsStorageURL)
            }
            try FileManager.default.copyItem(at: eventsBackupURL, to: eventsStorageURL)
        }
    }
    
    private func restoreContextSwitchesFromBackup() throws {
        if FileManager.default.fileExists(atPath: contextSwitchesBackupURL.path) {
            // Remove corrupted main file first
            if FileManager.default.fileExists(atPath: contextSwitchesStorageURL.path) {
                try FileManager.default.removeItem(at: contextSwitchesStorageURL)
            }
            try FileManager.default.copyItem(at: contextSwitchesBackupURL, to: contextSwitchesStorageURL)
        }
    }
    
    private func validateEvents(_ events: [AppActivationEvent]) throws {
        // Check for duplicate IDs
        let uniqueIds = Set(events.map { $0.id })
        if uniqueIds.count != events.count {
            throw DataStorageError.validationFailed("Duplicate event IDs found")
        }
        
        // Check for reasonable timestamp ordering (events should be chronologically ordered)
        let sortedEvents = events.sorted { $0.timestamp < $1.timestamp }
        if events.count > 1 && events != sortedEvents {
            print("Warning: Events are not in chronological order")
        }
        
        // Validate that all events have required fields
        for event in events {
            if event.appName?.isEmpty == true {
                throw DataStorageError.validationFailed("Event with empty app name found")
            }
        }
    }
    
    private func validateContextSwitches(_ switches: [ContextSwitchMetrics]) throws {
        // Check for duplicate IDs
        let uniqueIds = Set(switches.map { $0.id })
        if uniqueIds.count != switches.count {
            throw DataStorageError.validationFailed("Duplicate context switch IDs found")
        }
        
        // Validate that all switches have positive time spent
        for contextSwitch in switches {
            if contextSwitch.timeSpent < 0 {
                throw DataStorageError.validationFailed("Negative time spent found in context switch")
            }
        }
    }
    
    private func checkDiskSpace() throws {
        let attributes = try FileManager.default.attributesOfFileSystem(forPath: appDir.path)
        if let freeSpace = attributes[.systemFreeSize] as? NSNumber {
            let freeSpaceInBytes = freeSpace.int64Value
            let minimumRequired: Int64 = 10 * 1024 * 1024 // 10 MB minimum
            
            if freeSpaceInBytes < minimumRequired {
                throw DataStorageError.diskSpaceInsufficient
            }
        }
    }
    
    // MARK: - Error Notification Methods
    
    func notifyDataError(_ error: DataStorageError) {
        DispatchQueue.main.async {
            // Post notification for UI to handle
            NotificationCenter.default.post(
                name: .dataStorageError,
                object: nil,
                userInfo: ["error": error]
            )
        }
    }
    
    // MARK: - Public Getters for Data Export
    
    var dataDirectoryURL: URL {
        return appDir
    }
    
    var activationEventsURL: URL {
        return eventsStorageURL
    }
    
    var contextSwitchesURL: URL {
        return contextSwitchesStorageURL
    }
    
    var activationEventsBackupURL: URL {
        return eventsBackupURL
    }
    
    var contextSwitchesBackupFileURL: URL {
        return contextSwitchesBackupURL
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let dataStorageError = Notification.Name("DataStorageError")
}
