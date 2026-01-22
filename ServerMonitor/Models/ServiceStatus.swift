//
//  ServiceStatus.swift
//  ServerMonitor
//

import Foundation

struct ServiceStatus: Sendable {
    var serviceId: UUID
    var isRunning: Bool
    var details: String?          // "3 containers", "2 workers", etc.
    var containers: [DockerContainer]?  // Only for Docker
    var lastChecked: Date

    init(serviceId: UUID, isRunning: Bool = false, details: String? = nil, containers: [DockerContainer]? = nil) {
        self.serviceId = serviceId
        self.isRunning = isRunning
        self.details = details
        self.containers = containers
        self.lastChecked = Date()
    }
}

struct DockerContainer: Codable, Sendable, Identifiable {
    var id: String { name }
    var name: String
    var state: ContainerState
    var image: String
    var status: String            // "Up 3 days", "Exited (0) 2h ago"

    var displayImage: String {
        // Truncate long image names
        if image.count > 25 {
            return String(image.prefix(22)) + "..."
        }
        return image
    }
}

enum ContainerState: String, Codable, Sendable {
    case running
    case exited
    case paused
    case restarting
    case dead
    case created
    case removing

    var displayName: String {
        rawValue.capitalized
    }

    var isHealthy: Bool {
        self == .running
    }

    var icon: String {
        switch self {
        case .running: return "checkmark.circle.fill"
        case .exited: return "stop.circle.fill"
        case .paused: return "pause.circle.fill"
        case .restarting: return "arrow.clockwise.circle.fill"
        case .dead, .removing: return "xmark.circle.fill"
        case .created: return "circle.dashed"
        }
    }

    var color: String {
        switch self {
        case .running: return "green"
        case .exited: return "gray"
        case .paused: return "yellow"
        case .restarting: return "orange"
        case .dead, .removing: return "red"
        case .created: return "blue"
        }
    }
}
