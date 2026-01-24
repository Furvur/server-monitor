//
//  Server.swift
//  ServerMonitor
//

import Foundation

// MARK: - Agent Status

enum AgentStatus: String, Codable, Sendable {
    case unknown       // Not yet checked
    case notInstalled  // Agent not present on server
    case installed     // Agent present and running
    case outdated      // Agent present but needs update
    case error         // Agent present but not functioning
}

// MARK: - Server Model

struct Server: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var host: String  // Can be hostname, IP, or SSH config alias
    var port: Int
    var username: String
    var sshKeyPath: String?  // Path to SSH private key, nil means use default/agent
    var enabledServices: [UUID]  // IDs of services to monitor on this server
    var isEnabled: Bool

    // Agent-related fields
    var agentStatus: AgentStatus
    var agentVersion: String?
    var preferAgentMode: Bool  // User preference to use agent when available

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int = 22,
        username: String,
        sshKeyPath: String? = nil,
        enabledServices: [UUID] = [],
        isEnabled: Bool = true,
        agentStatus: AgentStatus = .unknown,
        agentVersion: String? = nil,
        preferAgentMode: Bool = true
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.sshKeyPath = sshKeyPath
        self.enabledServices = enabledServices
        self.isEnabled = isEnabled
        self.agentStatus = agentStatus
        self.agentVersion = agentVersion
        self.preferAgentMode = preferAgentMode
    }

    /// Get the ServiceDefinition objects for enabled services
    var enabledServiceDefinitions: [ServiceDefinition] {
        enabledServices.compactMap { serviceId in
            BuiltInServices.service(withId: serviceId)
        }
    }

    /// Whether the server should use agent-based fetching
    var useAgentFetching: Bool {
        preferAgentMode && agentStatus == .installed
    }

    // MARK: - Codable with migration support

    enum CodingKeys: String, CodingKey {
        case id, name, host, port, username, sshKeyPath
        case enabledServices, isEnabled
        case agentStatus, agentVersion, preferAgentMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        host = try container.decode(String.self, forKey: .host)
        port = try container.decode(Int.self, forKey: .port)
        username = try container.decode(String.self, forKey: .username)
        sshKeyPath = try container.decodeIfPresent(String.self, forKey: .sshKeyPath)
        enabledServices = try container.decode([UUID].self, forKey: .enabledServices)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)

        // Agent fields with defaults for migration from old configs
        agentStatus = try container.decodeIfPresent(AgentStatus.self, forKey: .agentStatus) ?? .unknown
        agentVersion = try container.decodeIfPresent(String.self, forKey: .agentVersion)
        preferAgentMode = try container.decodeIfPresent(Bool.self, forKey: .preferAgentMode) ?? true
    }
}
