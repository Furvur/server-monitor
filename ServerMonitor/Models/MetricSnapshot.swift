//
//  MetricSnapshot.swift
//  ServerMonitor
//

import Foundation

/// A time-series data point for historical metrics storage
struct MetricSnapshot: Codable, Identifiable, Sendable {
    let id: UUID
    let serverId: UUID
    let timestamp: Date

    // CPU Load
    var load1: Double?
    var load5: Double?
    var load15: Double?

    // Memory
    var memoryTotalMB: Int?
    var memoryUsedMB: Int?

    // Disk
    var diskUsagePercent: Double?

    init(
        id: UUID = UUID(),
        serverId: UUID,
        timestamp: Date = Date(),
        load1: Double? = nil,
        load5: Double? = nil,
        load15: Double? = nil,
        memoryTotalMB: Int? = nil,
        memoryUsedMB: Int? = nil,
        diskUsagePercent: Double? = nil
    ) {
        self.id = id
        self.serverId = serverId
        self.timestamp = timestamp
        self.load1 = load1
        self.load5 = load5
        self.load15 = load15
        self.memoryTotalMB = memoryTotalMB
        self.memoryUsedMB = memoryUsedMB
        self.diskUsagePercent = diskUsagePercent
    }

    /// Memory usage as a percentage (0-100)
    var memoryUsagePercent: Double? {
        guard let total = memoryTotalMB, let used = memoryUsedMB, total > 0 else {
            return nil
        }
        return Double(used) / Double(total) * 100
    }
}
