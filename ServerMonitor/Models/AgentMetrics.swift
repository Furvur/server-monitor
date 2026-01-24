//
//  AgentMetrics.swift
//  ServerMonitor
//
//  Codable structs matching the JSON schema produced by the server-side agent

import Foundation

// MARK: - Agent Metrics (Top-level)

struct AgentMetrics: Codable {
    let version: String
    let collectedAt: Date
    let load: AgentLoadMetrics
    let memory: AgentMemoryStats
    let disk: AgentDiskStats
    let swap: AgentSwapStats
    let network: AgentNetworkStats
    let uptime: AgentUptimeStats
    let systemInfo: AgentSystemInfo
    let services: [AgentServiceStatus]?

    enum CodingKeys: String, CodingKey {
        case version
        case collectedAt = "collected_at"
        case load, memory, disk, swap, network, uptime
        case systemInfo = "system_info"
        case services
    }
}

// MARK: - Load Metrics

struct AgentLoadMetrics: Codable {
    let load1: Double
    let load5: Double
    let load15: Double

    enum CodingKeys: String, CodingKey {
        case load1 = "load_1"
        case load5 = "load_5"
        case load15 = "load_15"
    }
}

// MARK: - Memory Stats

struct AgentMemoryStats: Codable {
    let totalMB: Int
    let usedMB: Int
    let freeMB: Int

    enum CodingKeys: String, CodingKey {
        case totalMB = "total_mb"
        case usedMB = "used_mb"
        case freeMB = "free_mb"
    }
}

// MARK: - Disk Stats

struct AgentDiskStats: Codable {
    let totalGB: Double
    let usedGB: Double
    let freeGB: Double
    let usagePercent: Double

    enum CodingKeys: String, CodingKey {
        case totalGB = "total_gb"
        case usedGB = "used_gb"
        case freeGB = "free_gb"
        case usagePercent = "usage_percent"
    }
}

// MARK: - Swap Stats

struct AgentSwapStats: Codable {
    let totalMB: Int
    let usedMB: Int
    let freeMB: Int

    enum CodingKeys: String, CodingKey {
        case totalMB = "total_mb"
        case usedMB = "used_mb"
        case freeMB = "free_mb"
    }
}

// MARK: - Network Stats

struct AgentNetworkStats: Codable {
    let bytesIn: UInt64
    let bytesOut: UInt64

    enum CodingKeys: String, CodingKey {
        case bytesIn = "bytes_in"
        case bytesOut = "bytes_out"
    }
}

// MARK: - Uptime Stats

struct AgentUptimeStats: Codable {
    let totalSeconds: Int

    enum CodingKeys: String, CodingKey {
        case totalSeconds = "total_seconds"
    }
}

// MARK: - System Info

struct AgentSystemInfo: Codable {
    let osName: String
    let osVersion: String
    let kernelVersion: String
    let hostname: String
    let architecture: String

    enum CodingKeys: String, CodingKey {
        case osName = "os_name"
        case osVersion = "os_version"
        case kernelVersion = "kernel_version"
        case hostname
        case architecture
    }
}

// MARK: - Service Status

struct AgentServiceStatus: Codable {
    let name: String
    let isRunning: Bool
    let details: String?
    let containers: [AgentContainerStatus]?

    enum CodingKeys: String, CodingKey {
        case name
        case isRunning = "is_running"
        case details
        case containers
    }
}

// MARK: - Container Status

struct AgentContainerStatus: Codable {
    let name: String
    let state: String
    let image: String
    let status: String
}

// MARK: - Conversion to ServerStats

extension AgentMetrics {
    /// Converts agent metrics to the app's ServerStats model
    func toServerStats(serverId: UUID) -> ServerStats {
        var stats = ServerStats(serverId: serverId, status: .online)

        // CPU Load
        stats.cpuLoad = CPULoad(
            load1: load.load1,
            load5: load.load5,
            load15: load.load15
        )

        // Memory
        stats.memory = MemoryStats(
            totalMB: memory.totalMB,
            usedMB: memory.usedMB,
            freeMB: memory.freeMB
        )

        // Disk
        stats.disk = DiskStats(
            totalGB: disk.totalGB,
            usedGB: disk.usedGB,
            freeGB: disk.freeGB,
            usagePercent: disk.usagePercent
        )

        // Swap
        stats.swap = SwapStats(
            totalMB: swap.totalMB,
            usedMB: swap.usedMB,
            freeMB: swap.freeMB
        )

        // Network
        stats.network = NetworkStats(
            bytesIn: network.bytesIn,
            bytesOut: network.bytesOut
        )

        // Uptime
        stats.uptime = UptimeStats(totalSeconds: uptime.totalSeconds)

        // System Info
        stats.systemInfo = SystemInfo(
            osName: systemInfo.osName,
            osVersion: systemInfo.osVersion,
            kernelVersion: systemInfo.kernelVersion,
            hostname: systemInfo.hostname,
            architecture: systemInfo.architecture
        )

        // Services (if present)
        if let agentServices = services {
            var serviceStatuses: [UUID: ServiceStatus] = [:]

            for agentService in agentServices {
                // Try to match with built-in service by name
                if let builtInService = BuiltInServices.all.first(where: {
                    $0.name.lowercased() == agentService.name.lowercased()
                }) {
                    var serviceStatus = ServiceStatus(
                        serviceId: builtInService.id,
                        isRunning: agentService.isRunning,
                        details: agentService.details
                    )

                    // Convert containers if present (Docker)
                    if let agentContainers = agentService.containers {
                        serviceStatus.containers = agentContainers.map { container in
                            DockerContainer(
                                name: container.name,
                                state: ContainerState(rawValue: container.state) ?? .exited,
                                image: container.image,
                                status: container.status
                            )
                        }
                    }

                    serviceStatuses[builtInService.id] = serviceStatus
                }
            }

            stats.services = serviceStatuses
        }

        stats.lastUpdated = collectedAt

        return stats
    }
}

// MARK: - JSON Decoder Configuration

extension AgentMetrics {
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func parse(from jsonString: String) throws -> AgentMetrics {
        guard let data = jsonString.data(using: .utf8) else {
            throw AgentMetricsError.invalidData
        }
        return try decoder.decode(AgentMetrics.self, from: data)
    }
}

enum AgentMetricsError: Error {
    case invalidData
    case parsingFailed(String)
}
