//
//  HistoryService.swift
//  ServerMonitor
//

import Foundation

/// Manages historical metrics data persistence
class HistoryService {
    private let historyDirectory: URL
    private var cache: [UUID: [MetricSnapshot]] = [:]
    private let cacheQueue = DispatchQueue(label: "com.servermonitor.history", qos: .utility)

    var retentionHours: Int {
        didSet {
            if retentionHours != oldValue {
                performCleanup()
            }
        }
    }

    init(retentionHours: Int = 24) {
        self.retentionHours = retentionHours

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("ServerMonitor", isDirectory: true)
        self.historyDirectory = appFolder.appendingPathComponent("history", isDirectory: true)

        // Create history folder if needed
        try? FileManager.default.createDirectory(at: historyDirectory, withIntermediateDirectories: true)

        // Load existing data and perform initial cleanup
        loadAllHistory()
        performCleanup()

        // Schedule periodic cleanup
        schedulePeriodicCleanup()
    }

    // MARK: - Public Methods

    /// Record a new metric snapshot
    func recordSnapshot(_ snapshot: MetricSnapshot) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }

            if self.cache[snapshot.serverId] == nil {
                self.cache[snapshot.serverId] = []
            }
            self.cache[snapshot.serverId]?.append(snapshot)

            // Persist to disk
            self.saveHistory(for: snapshot.serverId)
        }
    }

    /// Get historical snapshots for a server within the specified time range
    func getHistory(for serverId: UUID, hours: Int? = nil) -> [MetricSnapshot] {
        var result: [MetricSnapshot] = []

        cacheQueue.sync {
            guard let snapshots = cache[serverId] else {
                return
            }

            if let hours = hours {
                let cutoffDate = Date().addingTimeInterval(-Double(hours) * 3600)
                result = snapshots.filter { $0.timestamp >= cutoffDate }
            } else {
                result = snapshots
            }
        }

        return result.sorted { $0.timestamp < $1.timestamp }
    }

    /// Delete all history for a server
    func deleteHistory(for serverId: UUID) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }

            self.cache.removeValue(forKey: serverId)
            let fileURL = self.fileURL(for: serverId)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    /// Get available time range for a server's history
    func getTimeRange(for serverId: UUID) -> (start: Date, end: Date)? {
        let snapshots = getHistory(for: serverId)
        guard let first = snapshots.first, let last = snapshots.last else {
            return nil
        }
        return (first.timestamp, last.timestamp)
    }

    // MARK: - Private Methods

    private func fileURL(for serverId: UUID) -> URL {
        historyDirectory.appendingPathComponent("\(serverId.uuidString).json")
    }

    private func loadAllHistory() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: historyDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return
        }

        for file in files where file.pathExtension == "json" {
            let serverIdString = file.deletingPathExtension().lastPathComponent
            guard let serverId = UUID(uuidString: serverIdString) else { continue }

            loadHistory(for: serverId)
        }
    }

    private func loadHistory(for serverId: UUID) {
        let fileURL = fileURL(for: serverId)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let snapshots = try JSONDecoder().decode([MetricSnapshot].self, from: data)
            cacheQueue.async { [weak self] in
                self?.cache[serverId] = snapshots
            }
        } catch {
            print("Failed to load history for \(serverId): \(error)")
        }
    }

    private func saveHistory(for serverId: UUID) {
        // Already on cacheQueue
        guard let snapshots = cache[serverId] else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshots)
            try data.write(to: fileURL(for: serverId))
        } catch {
            print("Failed to save history for \(serverId): \(error)")
        }
    }

    private func performCleanup() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }

            let cutoffDate = Date().addingTimeInterval(-Double(self.retentionHours) * 3600)

            for serverId in self.cache.keys {
                self.cache[serverId] = self.cache[serverId]?.filter { $0.timestamp >= cutoffDate }
                self.saveHistory(for: serverId)
            }
        }
    }

    private func schedulePeriodicCleanup() {
        // Run cleanup every hour
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 3600) { [weak self] in
            self?.performCleanup()
            self?.schedulePeriodicCleanup()
        }
    }
}
