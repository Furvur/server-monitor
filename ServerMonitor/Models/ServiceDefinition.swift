//
//  ServiceDefinition.swift
//  ServerMonitor
//

import Foundation

struct ServiceDefinition: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var icon: String              // SF Symbol name
    var category: ServiceCategory
    var checkCommand: String      // Command to run via SSH
    var parseMode: ServiceParseMode
    var isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        category: ServiceCategory,
        checkCommand: String,
        parseMode: ServiceParseMode,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.category = category
        self.checkCommand = checkCommand
        self.parseMode = parseMode
        self.isBuiltIn = isBuiltIn
    }
}

enum ServiceCategory: String, Codable, CaseIterable {
    case container = "Containers"
    case webServer = "Web Servers"
    case database = "Databases"
    case cache = "Cache & Queues"
    case runtime = "Runtimes"
    case system = "System"
    case custom = "Custom"

    var displayName: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .container: return "shippingbox"
        case .webServer: return "globe"
        case .database: return "cylinder"
        case .cache: return "bolt.horizontal"
        case .runtime: return "gearshape.2"
        case .system: return "wrench.and.screwdriver"
        case .custom: return "star"
        }
    }
}

enum ServiceParseMode: String, Codable {
    case activeInactive       // systemctl: "active" or "inactive"
    case processCount         // pgrep -c: number of processes
    case dockerContainers     // docker ps: parse container list
    case lineCount            // count non-empty lines in output
    case exitCode             // 0 = running, non-zero = stopped
    case custom               // user-defined, just check if output is non-empty
}
