//
//  ServerStats.swift
//  ServerMonitor
//

import Foundation

struct ServerStats: Identifiable, Sendable {
    let id: UUID  // Matches Server.id
    var status: ServerStatus
    var cpuLoad: CPULoad?
    var memory: MemoryStats?
    var disk: DiskStats?
    var services: [UUID: ServiceStatus]  // Service ID -> Status
    var lastUpdated: Date
    var errorMessage: String?  // Detailed error message when status is .error or .offline

    nonisolated init(serverId: UUID, status: ServerStatus = .unknown, errorMessage: String? = nil) {
        self.id = serverId
        self.status = status
        self.cpuLoad = nil
        self.memory = nil
        self.disk = nil
        self.services = [:]
        self.lastUpdated = Date()
        self.errorMessage = errorMessage
    }

    /// Count of running services
    var runningServicesCount: Int {
        services.values.filter { $0.isRunning }.count
    }

    /// Count of total monitored services
    var totalServicesCount: Int {
        services.count
    }
}

enum ServerStatus: String, Sendable {
    case online = "Online"
    case offline = "Offline"
    case connecting = "Connecting..."
    case error = "Error"
    case unknown = "Unknown"

    var color: String {
        switch self {
        case .online: return "green"
        case .offline, .error: return "red"
        case .connecting: return "yellow"
        case .unknown: return "gray"
        }
    }
}

struct CPULoad: Sendable {
    var load1: Double   // 1-minute average
    var load5: Double   // 5-minute average
    var load15: Double  // 15-minute average

    var displayString: String {
        String(format: "%.2f / %.2f / %.2f", load1, load5, load15)
    }
}

struct MemoryStats: Sendable {
    var totalMB: Int
    var usedMB: Int
    var freeMB: Int

    var usagePercent: Double {
        guard totalMB > 0 else { return 0 }
        return Double(usedMB) / Double(totalMB) * 100
    }

    var displayString: String {
        let usedGB = Double(usedMB) / 1024
        let totalGB = Double(totalMB) / 1024
        return String(format: "%.1fG / %.1fG (%.0f%%)", usedGB, totalGB, usagePercent)
    }
}

struct DiskStats: Sendable {
    var totalGB: Double
    var usedGB: Double
    var freeGB: Double
    var usagePercent: Double

    var displayString: String {
        String(format: "%.1fG / %.1fG (%.0f%%)", usedGB, totalGB, usagePercent)
    }
}
