//
//  MonitorService.swift
//  ServerMonitor
//

import Foundation
import Combine
import SwiftUI

@MainActor
class MonitorService: ObservableObject {
    @Published var servers: [Server] = []
    @Published var stats: [UUID: ServerStats] = [:]
    @Published var isMonitoring: Bool = false
    @Published var refreshInterval: TimeInterval = 30  // seconds
    @Published var showInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showInMenuBar, forKey: "showInMenuBar")
            NotificationCenter.default.post(name: .menuBarVisibilityChanged, object: nil)
        }
    }

    private let sshService = SSHService()
    private var monitoringTask: Task<Void, Never>?
    private let configURL: URL

    init() {
        self.showInMenuBar = UserDefaults.standard.bool(forKey: "showInMenuBar")
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("ServerMonitor", isDirectory: true)

        // Create app folder if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        self.configURL = appFolder.appendingPathComponent("servers.json")
        loadServers()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        monitoringTask = Task {
            while !Task.isCancelled && isMonitoring {
                await refreshAllServers()
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
            }
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    func refreshAllServers() async {
        let enabledServers = servers.filter { $0.isEnabled }

        await withTaskGroup(of: ServerStats.self) { group in
            for server in enabledServers {
                group.addTask {
                    await self.sshService.fetchStats(for: server)
                }
            }

            for await stat in group {
                stats[stat.id] = stat
            }
        }
    }

    func refreshServer(_ server: Server) async {
        let stat = await sshService.fetchStats(for: server)
        stats[stat.id] = stat
    }

    // MARK: - Server Management

    func addServer(_ server: Server) {
        servers.append(server)
        saveServers()
    }

    func updateServer(_ server: Server) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
            saveServers()
        }
    }

    func deleteServer(_ server: Server) {
        servers.removeAll { $0.id == server.id }
        stats.removeValue(forKey: server.id)
        saveServers()
    }

    func deleteServers(at offsets: IndexSet) {
        let serversToDelete = offsets.map { servers[$0] }
        for server in serversToDelete {
            stats.removeValue(forKey: server.id)
        }
        servers.remove(atOffsets: offsets)
        saveServers()
    }

    // MARK: - Persistence

    private func loadServers() {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            // Add a sample server for first-time users
            servers = []
            return
        }

        do {
            let data = try Data(contentsOf: configURL)
            servers = try JSONDecoder().decode([Server].self, from: data)
        } catch {
            print("Failed to load servers: \(error)")
            servers = []
        }
    }

    private func saveServers() {
        do {
            let data = try JSONEncoder().encode(servers)
            try data.write(to: configURL)
        } catch {
            print("Failed to save servers: \(error)")
        }
    }
}

extension Notification.Name {
    static let menuBarVisibilityChanged = Notification.Name("menuBarVisibilityChanged")
}
