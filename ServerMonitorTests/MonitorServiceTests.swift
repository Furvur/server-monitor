//
//  MonitorServiceTests.swift
//  ServerMonitorTests
//

import Testing
import Foundation
@testable import ServerMonitor

@MainActor
struct MonitorServiceTests {

    // Helper to create a clean MonitorService for testing
    private func createCleanService() -> MonitorService {
        // Clear any existing defaults for clean test
        UserDefaults.standard.removeObject(forKey: "refreshInterval")
        UserDefaults.standard.removeObject(forKey: "autoStartOnLaunch")
        UserDefaults.standard.removeObject(forKey: "historyRetentionHours")

        let service = MonitorService()
        // Clear any servers loaded from disk
        while !service.servers.isEmpty {
            service.deleteServer(service.servers[0])
        }
        return service
    }

    // MARK: - Initialization Tests

    @Test func initializationLoadsDefaults() {
        // Clear any existing defaults for clean test
        UserDefaults.standard.removeObject(forKey: "refreshInterval")
        UserDefaults.standard.removeObject(forKey: "autoStartOnLaunch")
        UserDefaults.standard.removeObject(forKey: "historyRetentionHours")

        let service = MonitorService()

        // Check defaults (servers may exist from disk, so don't check servers.isEmpty)
        #expect(service.refreshInterval == 30)
        #expect(service.autoStartOnLaunch == true)
        #expect(service.historyRetentionHours == 24)
        #expect(service.isMonitoring == false)
    }

    // MARK: - Settings Persistence Tests

    @Test func refreshIntervalPersistsToUserDefaults() {
        let service = MonitorService()

        service.refreshInterval = 60

        #expect(UserDefaults.standard.double(forKey: "refreshInterval") == 60)
    }

    @Test func autoStartOnLaunchPersistsToUserDefaults() {
        let service = MonitorService()

        service.autoStartOnLaunch = false
        #expect(UserDefaults.standard.bool(forKey: "autoStartOnLaunch") == false)

        service.autoStartOnLaunch = true
        #expect(UserDefaults.standard.bool(forKey: "autoStartOnLaunch") == true)
    }

    @Test func historyRetentionHoursPersistsToUserDefaults() {
        let service = MonitorService()

        service.historyRetentionHours = 6

        #expect(UserDefaults.standard.integer(forKey: "historyRetentionHours") == 6)
    }

    @Test func showInMenuBarPersistsToUserDefaults() {
        let service = MonitorService()

        service.showInMenuBar = true
        #expect(UserDefaults.standard.bool(forKey: "showInMenuBar") == true)

        service.showInMenuBar = false
        #expect(UserDefaults.standard.bool(forKey: "showInMenuBar") == false)
    }

    // MARK: - Server Management Tests

    @Test func addServerAddsToList() {
        let service = createCleanService()
        let server = Server(name: "Test", host: "test.local", username: "user")

        service.addServer(server)

        #expect(service.servers.contains { $0.name == "Test" })
    }

    @Test func addMultipleServers() {
        let service = createCleanService()
        let initialCount = service.servers.count

        service.addServer(Server(name: "Server 1", host: "host1", username: "user"))
        service.addServer(Server(name: "Server 2", host: "host2", username: "user"))
        service.addServer(Server(name: "Server 3", host: "host3", username: "user"))

        #expect(service.servers.count == initialCount + 3)
    }

    @Test func updateServerModifiesExisting() {
        let service = createCleanService()
        var server = Server(name: "Original", host: "host", username: "user")
        service.addServer(server)

        server.name = "Updated"
        service.updateServer(server)

        #expect(service.servers.contains { $0.id == server.id && $0.name == "Updated" })
    }

    @Test func updateServerDoesNothingForNonexistent() {
        let service = createCleanService()
        let existingServer = Server(name: "Existing", host: "host", username: "user")
        service.addServer(existingServer)
        let countBefore = service.servers.count

        let newServer = Server(name: "New", host: "different", username: "user")
        service.updateServer(newServer)

        #expect(service.servers.count == countBefore)
        #expect(service.servers.contains { $0.name == "Existing" })
    }

    @Test func deleteServerRemovesFromList() {
        let service = createCleanService()
        let server = Server(name: "ToDelete", host: "host", username: "user")
        service.addServer(server)

        service.deleteServer(server)

        #expect(!service.servers.contains { $0.id == server.id })
    }

    @Test func deleteServerRemovesStats() {
        let service = createCleanService()
        let server = Server(name: "Test", host: "host", username: "user")
        service.addServer(server)
        service.stats[server.id] = ServerStats(serverId: server.id, status: .online)

        service.deleteServer(server)

        #expect(service.stats[server.id] == nil)
    }

    @Test func deleteServersAtOffsets() {
        let service = createCleanService()
        let server0 = Server(name: "Server 0", host: "host0", username: "user")
        let server1 = Server(name: "Server 1", host: "host1", username: "user")
        let server2 = Server(name: "Server 2", host: "host2", username: "user")
        service.addServer(server0)
        service.addServer(server1)
        service.addServer(server2)

        // Find the index of server1 and delete it
        if let index = service.servers.firstIndex(where: { $0.id == server1.id }) {
            service.deleteServers(at: IndexSet([index]))
        }

        #expect(!service.servers.contains { $0.id == server1.id })
        #expect(service.servers.contains { $0.id == server0.id })
        #expect(service.servers.contains { $0.id == server2.id })
    }

    // MARK: - Monitoring State Tests

    @Test func startMonitoringSetsFlag() {
        let service = MonitorService()

        service.startMonitoring()

        #expect(service.isMonitoring == true)
    }

    @Test func stopMonitoringClearsFlag() {
        let service = MonitorService()
        service.startMonitoring()

        service.stopMonitoring()

        #expect(service.isMonitoring == false)
    }

    @Test func startMonitoringDoesNotDoubleStart() {
        let service = MonitorService()

        service.startMonitoring()
        service.startMonitoring() // Should not create a second task

        #expect(service.isMonitoring == true)

        service.stopMonitoring()
    }

    @Test func restartMonitoringStopsAndStarts() {
        let service = MonitorService()
        service.startMonitoring()

        service.restartMonitoring()

        #expect(service.isMonitoring == true)

        service.stopMonitoring()
    }

    // MARK: - History Service Integration Tests

    @Test func historyServiceIsInitialized() {
        let service = MonitorService()
        #expect(service.historyService.retentionHours == service.historyRetentionHours)
    }

    @Test func historyRetentionChangeUpdatesHistoryService() {
        let service = MonitorService()

        service.historyRetentionHours = 6

        #expect(service.historyService.retentionHours == 6)
    }
}
