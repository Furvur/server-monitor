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
    var isEnabled: Bool

    init(id: UUID = UUID(), name: String, host: String, port: Int = 22, username: String, sshKeyPath: String? = nil, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.sshKeyPath = sshKeyPath
        self.isEnabled = isEnabled
    }
}
