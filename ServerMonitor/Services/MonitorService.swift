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
    @Published var refreshInterval: TimeInterval {
        didSet {
            UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
            // Restart monitoring if interval changed while monitoring
            if isMonitoring && oldValue != refreshInterval {
                restartMonitoring()
            }
        }
    }
    @Published var showInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showInMenuBar, forKey: "showInMenuBar")
            NotificationCenter.default.post(name: .menuBarVisibilityChanged, object: nil)
        }
    }
    @Published var autoStartOnLaunch: Bool {
        didSet {
            UserDefaults.standard.set(autoStartOnLaunch, forKey: "autoStartOnLaunch")
        }
    }
    @Published var historyRetentionHours: Int {
        didSet {
            UserDefaults.standard.set(historyRetentionHours, forKey: "historyRetentionHours")
            historyService.retentionHours = historyRetentionHours
        }
    }

    private let sshService = SSHService()
    private var monitoringTask: Task<Void, Never>?
    private let configURL: URL
    let historyService: HistoryService

    init() {
        // Load persisted settings with defaults
        self.showInMenuBar = UserDefaults.standard.bool(forKey: "showInMenuBar")

        let savedRefreshInterval = UserDefaults.standard.double(forKey: "refreshInterval")
        self.refreshInterval = savedRefreshInterval > 0 ? savedRefreshInterval : 30

        // Default to true for autoStartOnLaunch if not previously set
        if UserDefaults.standard.object(forKey: "autoStartOnLaunch") == nil {
            UserDefaults.standard.set(true, forKey: "autoStartOnLaunch")
            self.autoStartOnLaunch = true
        } else {
            self.autoStartOnLaunch = UserDefaults.standard.bool(forKey: "autoStartOnLaunch")
        }

        let savedRetention = UserDefaults.standard.integer(forKey: "historyRetentionHours")
        self.historyRetentionHours = savedRetention > 0 ? savedRetention : 24

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("ServerMonitor", isDirectory: true)

        // Create app folder if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        self.configURL = appFolder.appendingPathComponent("servers.json")
        self.historyService = HistoryService(retentionHours: savedRetention > 0 ? savedRetention : 24)

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

    func restartMonitoring() {
        stopMonitoring()
        startMonitoring()
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
                // Record snapshot for history
                if stat.status == .online {
                    recordSnapshot(for: stat)
                }
            }
        }
    }

    private func recordSnapshot(for stats: ServerStats) {
        let snapshot = MetricSnapshot(
            serverId: stats.id,
            timestamp: stats.lastUpdated,
            load1: stats.cpuLoad?.load1,
            load5: stats.cpuLoad?.load5,
            load15: stats.cpuLoad?.load15,
            memoryTotalMB: stats.memory?.totalMB,
            memoryUsedMB: stats.memory?.usedMB,
            diskUsagePercent: stats.disk?.usagePercent
        )
        historyService.recordSnapshot(snapshot)
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
