//
//  iCloudSyncServiceTests.swift
//  ServerMonitorTests
//

import Testing
import Foundation
@testable import ServerMonitor

struct iCloudSyncServiceTests {

    // MARK: - Merge Tests

    @Test func mergeEmptyLocalWithCloudServers() {
        let cloudServers = [
            Server(name: "Cloud Server 1", host: "cloud1.example.com", username: "admin"),
            Server(name: "Cloud Server 2", host: "cloud2.example.com", username: "root")
        ]

        let merged = iCloudSyncService.shared.mergeServers(local: [], cloud: cloudServers)

        #expect(merged.count == 2)
    }

    @Test func mergeLocalWithEmptyCloud() {
        let localServers = [
            Server(name: "Local Server 1", host: "local1.example.com", username: "admin"),
            Server(name: "Local Server 2", host: "local2.example.com", username: "root")
        ]

        let merged = iCloudSyncService.shared.mergeServers(local: localServers, cloud: [])

        #expect(merged.count == 2)
    }

    @Test func mergeWithNoConflicts() {
        let localServers = [
            Server(name: "Local Server", host: "local.example.com", username: "admin")
        ]
        let cloudServers = [
            Server(name: "Cloud Server", host: "cloud.example.com", username: "root")
        ]

        let merged = iCloudSyncService.shared.mergeServers(local: localServers, cloud: cloudServers)

        #expect(merged.count == 2)
        #expect(merged.contains { $0.name == "Local Server" })
        #expect(merged.contains { $0.name == "Cloud Server" })
    }

    @Test func mergeWithSameIdPreferCloud() {
        let sharedId = UUID()
        let localServer = Server(
            id: sharedId,
            name: "Local Version",
            host: "local.example.com",
            username: "localuser"
        )
        let cloudServer = Server(
            id: sharedId,
            name: "Cloud Version",
            host: "cloud.example.com",
            username: "clouduser"
        )

        let merged = iCloudSyncService.shared.mergeServers(local: [localServer], cloud: [cloudServer])

        #expect(merged.count == 1)
        // Cloud version should win for conflicts
        #expect(merged[0].name == "Cloud Version")
        #expect(merged[0].host == "cloud.example.com")
        #expect(merged[0].username == "clouduser")
    }

    @Test func mergePreservesAllUniqueServers() {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        let localServers = [
            Server(id: id1, name: "Server 1", host: "host1", username: "user1"),
            Server(id: id2, name: "Server 2", host: "host2", username: "user2")
        ]
        let cloudServers = [
            Server(id: id2, name: "Server 2 Updated", host: "host2-new", username: "user2"),
            Server(id: id3, name: "Server 3", host: "host3", username: "user3")
        ]

        let merged = iCloudSyncService.shared.mergeServers(local: localServers, cloud: cloudServers)

        #expect(merged.count == 3)
        #expect(merged.contains { $0.id == id1 })
        #expect(merged.contains { $0.id == id2 })
        #expect(merged.contains { $0.id == id3 })

        // Verify id2 has cloud version
        let server2 = merged.first { $0.id == id2 }
        #expect(server2?.name == "Server 2 Updated")
        #expect(server2?.host == "host2-new")
    }

    @Test func mergeSortsResultByName() {
        let localServers = [
            Server(name: "Zebra Server", host: "z.example.com", username: "user"),
            Server(name: "Alpha Server", host: "a.example.com", username: "user")
        ]

        let merged = iCloudSyncService.shared.mergeServers(local: localServers, cloud: [])

        #expect(merged[0].name == "Alpha Server")
        #expect(merged[1].name == "Zebra Server")
    }

    @Test func mergeHandlesEmptyInputs() {
        let merged = iCloudSyncService.shared.mergeServers(local: [], cloud: [])
        #expect(merged.isEmpty)
    }

    @Test func mergeHandlesLargeNumberOfServers() {
        var localServers: [Server] = []
        var cloudServers: [Server] = []

        // Create 50 local servers
        for i in 0..<50 {
            localServers.append(Server(name: "Local \(i)", host: "local\(i).example.com", username: "user"))
        }

        // Create 50 cloud servers (different)
        for i in 0..<50 {
            cloudServers.append(Server(name: "Cloud \(i)", host: "cloud\(i).example.com", username: "user"))
        }

        let merged = iCloudSyncService.shared.mergeServers(local: localServers, cloud: cloudServers)

        #expect(merged.count == 100)
    }

    // MARK: - Availability Tests

    @Test func isAvailablePropertyExists() {
        // Just verify the property can be accessed without crashing
        _ = iCloudSyncService.shared.isAvailable
    }

    // MARK: - Singleton Tests

    @Test func sharedInstanceIsSingleton() {
        let instance1 = iCloudSyncService.shared
        let instance2 = iCloudSyncService.shared

        #expect(instance1 === instance2)
    }
}
