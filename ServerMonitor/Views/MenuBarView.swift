//
//  MenuBarView.swift
//  ServerMonitor
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var monitorService: MonitorService

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()

            if monitorService.servers.isEmpty {
                emptyStateView
            } else {
                serverListView
            }

            Divider()
            footerView
        }
        .frame(width: 320)
    }

    private var headerView: some View {
        HStack {
            Text("Server Monitor")
                .font(.headline)
            Spacer()
            Button(action: {
                Task {
                    await monitorService.refreshAllServers()
                }
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh all servers")
        }
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "server.rack")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No servers configured")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Open Settings to add servers")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Open Settings") {
                openSettings()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var serverListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(monitorService.servers) { server in
                    ServerRowView(
                        server: server,
                        stats: monitorService.stats[server.id]
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 300)
    }

    private var footerView: some View {
        HStack {
            Circle()
                .fill(monitorService.isMonitoring ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            Text(monitorService.isMonitoring ? "Monitoring" : "Paused")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("Settings") {
                openSettings()
            }
            .buttonStyle(.borderless)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
        .padding()
    }

    private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

struct ServerRowView: View {
    let server: Server
    let stats: ServerStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                statusIndicator
                Text(server.name)
                    .font(.headline)
                Spacer()
                if let stats = stats {
                    Text(stats.status.rawValue)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }
            }

            if let stats = stats, stats.status == .online {
                statsGrid(stats)
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
    }

    private var statusColor: Color {
        guard let stats = stats else { return .gray }
        switch stats.status {
        case .online: return .green
        case .offline, .error: return .red
        case .connecting: return .yellow
        case .unknown: return .gray
        }
    }

    @ViewBuilder
    private func statsGrid(_ stats: ServerStats) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let cpu = stats.cpuLoad {
                statRow(icon: "cpu", label: "Load", value: cpu.displayString)
            }
            if let memory = stats.memory {
                statRow(icon: "memorychip", label: "Memory", value: memory.displayString)
            }
            if let disk = stats.disk {
                statRow(icon: "internaldrive", label: "Disk", value: disk.displayString)
            }
        }
        .font(.caption)
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .frame(width: 16)
                .foregroundColor(.secondary)
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            Text(value)
                .foregroundColor(.primary)
        }
    }
}
