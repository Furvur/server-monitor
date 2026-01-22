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
    var isEnabled: Bool

    init(id: UUID = UUID(), name: String, host: String, port: Int = 22, username: String, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.isEnabled = isEnabled
    }

    var sshDestination: String {
        if port == 22 {
            return "\(username)@\(host)"
        } else {
            return "-p \(port) \(username)@\(host)"
        }
    }
}
