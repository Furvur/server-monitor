//
//  ServerTests.swift
//  ServerMonitorTests
//

import Testing
import Foundation
@testable import ServerMonitor

struct ServerTests {

    // MARK: - Initialization Tests

    @Test func initializationWithDefaults() {
        let server = Server(name: "Test", host: "192.168.1.1", username: "root")

        #expect(server.name == "Test")
        #expect(server.host == "192.168.1.1")
        #expect(server.port == 22)
        #expect(server.username == "root")
        #expect(server.sshKeyPath == nil)
        #expect(server.enabledServices.isEmpty)
        #expect(server.isEnabled == true)
    }

    @Test func initializationWithCustomValues() {
        let serviceId = UUID()
        let server = Server(
            name: "Production",
            host: "prod.example.com",
            port: 2222,
            username: "deploy",
            sshKeyPath: "/Users/test/.ssh/id_rsa",
            enabledServices: [serviceId],
            isEnabled: false
        )

        #expect(server.name == "Production")
        #expect(server.host == "prod.example.com")
        #expect(server.port == 2222)
        #expect(server.username == "deploy")
        #expect(server.sshKeyPath == "/Users/test/.ssh/id_rsa")
        #expect(server.enabledServices == [serviceId])
        #expect(server.isEnabled == false)
    }

    // MARK: - Codable Tests

    @Test func encodingAndDecoding() throws {
        let original = Server(
            name: "Test Server",
            host: "test.example.com",
            port: 2222,
            username: "admin",
            sshKeyPath: "/path/to/key",
            enabledServices: [UUID()],
            isEnabled: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Server.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.host == original.host)
        #expect(decoded.port == original.port)
        #expect(decoded.username == original.username)
        #expect(decoded.sshKeyPath == original.sshKeyPath)
        #expect(decoded.enabledServices == original.enabledServices)
        #expect(decoded.isEnabled == original.isEnabled)
    }

    @Test func decodingFromJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "name": "My Server",
            "host": "server.local",
            "port": 22,
            "username": "user",
            "enabledServices": [],
            "isEnabled": true
        }
        """

        let data = json.data(using: .utf8)!
        let server = try JSONDecoder().decode(Server.self, from: data)

        #expect(server.name == "My Server")
        #expect(server.host == "server.local")
        #expect(server.port == 22)
        #expect(server.username == "user")
        #expect(server.sshKeyPath == nil)
    }

    // MARK: - Hashable Tests

    @Test func hashableConformance() {
        let server1 = Server(name: "Test", host: "host1", username: "user")
        let server2 = Server(name: "Test", host: "host1", username: "user")

        // Different IDs should produce different hashes
        #expect(server1.hashValue != server2.hashValue)

        // Same server should be in a set only once
        var set = Set<Server>()
        set.insert(server1)
        set.insert(server1)
        #expect(set.count == 1)
    }

    // MARK: - Equality Tests

    @Test func equalityIsBasedOnAllProperties() {
        let id = UUID()
        let server1 = Server(id: id, name: "Server 1", host: "host", username: "user")
        let server2 = Server(id: id, name: "Server 1", host: "host", username: "user")
        let server3 = Server(id: id, name: "Different", host: "host", username: "user")

        // Same properties = equal
        #expect(server1 == server2)
        // Different properties = not equal (even with same id)
        #expect(server1 != server3)
    }
}
