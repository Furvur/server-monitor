//
//  MainWindowView.swift
//  ServerMonitor
//

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var monitorService: MonitorService

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .frame(minWidth: 600, minHeight: 400)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    Task {
                        await monitorService.refreshAllServers()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh all servers")
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }) {
                    Image(systemName: "gear")
                }
                .help("Settings")
            }
        }
    }

    @State private var selectedServer: Server?

    private var sidebar: some View {
        List(monitorService.servers, selection: $selectedServer) { server in
            ServerSidebarRow(
                server: server,
                stats: monitorService.stats[server.id]
            )
            .tag(server)
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .navigationTitle("Servers")
    }

    @ViewBuilder
    private var detailView: some View {
        if let server = selectedServer,
           let stats = monitorService.stats[server.id] {
            ServerDetailView(server: server, stats: stats)
        } else if monitorService.servers.isEmpty {
            ContentUnavailableView {
                Label("No Servers", systemImage: "server.rack")
            } description: {
                Text("Add servers in Settings to start monitoring.")
            } actions: {
                Button("Open Settings") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            }
        } else {
            ContentUnavailableView {
                Label("Select a Server", systemImage: "server.rack")
            } description: {
                Text("Choose a server from the sidebar to view details.")
            }
        }
    }
}

struct ServerSidebarRow: View {
    let server: Server
    let stats: ServerStats?

    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading) {
                Text(server.name)
                    .font(.headline)
                if let stats = stats {
                    Text(stats.status.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
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
}

struct ServerDetailView: View {
    let server: Server
    let stats: ServerStats

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                if stats.status == .online {
                    statsSection
                } else {
                    statusSection
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle(server.name)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                Text(stats.status.rawValue)
                    .font(.title2)
                    .fontWeight(.medium)
            }

            Text("\(server.username)@\(server.host)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Last updated: \(stats.lastUpdated.formatted())")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Server is \(stats.status.rawValue.lowercased())")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private var statsSection: some View {
        VStack(spacing: 16) {
            if let cpu = stats.cpuLoad {
                StatCard(
                    title: "CPU Load",
                    icon: "cpu",
                    value: cpu.displayString,
                    detail: "1 min / 5 min / 15 min averages"
                )
            }

            if let memory = stats.memory {
                StatCard(
                    title: "Memory",
                    icon: "memorychip",
                    value: memory.displayString,
                    detail: "Used / Total",
                    progress: memory.usagePercent / 100
                )
            }

            if let disk = stats.disk {
                StatCard(
                    title: "Disk",
                    icon: "internaldrive",
                    value: disk.displayString,
                    detail: "Used / Total",
                    progress: disk.usagePercent / 100
                )
            }
        }
    }

    private var statusColor: Color {
        switch stats.status {
        case .online: return .green
        case .offline, .error: return .red
        case .connecting: return .yellow
        case .unknown: return .gray
        }
    }
}

struct StatCard: View {
    let title: String
    let icon: String
    let value: String
    let detail: String
    var progress: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
            }

            Text(value)
                .font(.title)
                .fontWeight(.semibold)

            if let progress = progress {
                ProgressView(value: progress)
                    .tint(progressColor(for: progress))
            }

            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func progressColor(for value: Double) -> Color {
        if value > 0.9 { return .red }
        if value > 0.7 { return .orange }
        return .green
    }
}
