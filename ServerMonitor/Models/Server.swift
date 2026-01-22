//
//  Server.swift
//  ServerMonitor
//

import Foundation

struct Server: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var host: String  // Can be hostname, IP, or SSH config alias
    var port: Int
    var username: String
    var sshKeyPath: String?  // Path to SSH private key, nil means use default/agent
    var enabledServices: [UUID]  // IDs of services to monitor on this server
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int = 22,
        username: String,
        sshKeyPath: String? = nil,
        enabledServices: [UUID] = [],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.sshKeyPath = sshKeyPath
        self.enabledServices = enabledServices
        self.isEnabled = isEnabled
    }

    /// Get the ServiceDefinition objects for enabled services
    var enabledServiceDefinitions: [ServiceDefinition] {
        enabledServices.compactMap { serviceId in
            BuiltInServices.service(withId: serviceId)
        }
    }
}
