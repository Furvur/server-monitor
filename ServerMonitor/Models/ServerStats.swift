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
    var swap: SwapStats?
    var network: NetworkStats?
    var uptime: UptimeStats?
    var systemInfo: SystemInfo?
    var services: [UUID: ServiceStatus]  // Service ID -> Status
    var lastUpdated: Date
    var errorMessage: String?  // Detailed error message when status is .error or .offline

    nonisolated init(serverId: UUID, status: ServerStatus = .unknown, errorMessage: String? = nil) {
        self.id = serverId
        self.status = status
        self.cpuLoad = nil
        self.memory = nil
        self.disk = nil
        self.swap = nil
        self.network = nil
        self.uptime = nil
        self.systemInfo = nil
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

struct SwapStats: Sendable {
    var totalMB: Int
    var usedMB: Int
    var freeMB: Int

    var usagePercent: Double {
        guard totalMB > 0 else { return 0 }
        return Double(usedMB) / Double(totalMB) * 100
    }

    var displayString: String {
        if totalMB == 0 {
            return "Not configured"
        }
        let usedGB = Double(usedMB) / 1024
        let totalGB = Double(totalMB) / 1024
        if totalGB >= 1 {
            return String(format: "%.1fG / %.1fG (%.0f%%)", usedGB, totalGB, usagePercent)
        } else {
            return String(format: "%dM / %dM (%.0f%%)", usedMB, totalMB, usagePercent)
        }
    }

    var isActive: Bool {
        usedMB > 0
    }
}

struct NetworkStats: Sendable {
    var bytesIn: UInt64
    var bytesOut: UInt64

    var displayBytesIn: String {
        formatBytes(bytesIn)
    }

    var displayBytesOut: String {
        formatBytes(bytesOut)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        let gb = mb / 1024
        let tb = gb / 1024

        if tb >= 1 { return String(format: "%.1f TB", tb) }
        if gb >= 1 { return String(format: "%.1f GB", gb) }
        if mb >= 1 { return String(format: "%.1f MB", mb) }
        if kb >= 1 { return String(format: "%.1f KB", kb) }
        return "\(bytes) B"
    }
}

struct UptimeStats: Sendable {
    var totalSeconds: Int

    var days: Int { totalSeconds / 86400 }
    var hours: Int { (totalSeconds % 86400) / 3600 }
    var minutes: Int { (totalSeconds % 3600) / 60 }

    var displayString: String {
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var shortDisplayString: String {
        if days > 0 {
            return "\(days)d"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

struct SystemInfo: Sendable {
    var osName: String          // "Ubuntu", "Debian", "CentOS"
    var osVersion: String       // "22.04", "12", "8"
    var kernelVersion: String   // "5.15.0-91-generic"
    var hostname: String
    var architecture: String    // "x86_64", "aarch64"

    var displayOS: String {
        if osVersion.isEmpty {
            return osName
        }
        return "\(osName) \(osVersion)"
    }

    var shortKernel: String {
        // Return just the version number without extra details
        let parts = kernelVersion.components(separatedBy: "-")
        if let first = parts.first {
            return first
        }
        return kernelVersion
    }
}
