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
            Divider().background(DSDarkTheme.divider)

            if monitorService.servers.isEmpty {
                emptyStateView
            } else {
                serverListView
            }

            Divider().background(DSDarkTheme.divider)
            footerView
        }
        .frame(width: 360)
        .background(DSDarkTheme.background)
        .preferredColorScheme(.dark)
    }

    private var headerView: some View {
        HStack {
            Text("Server Monitor")
                .font(DSTypography.headline)
                .foregroundColor(DSDarkTheme.textPrimary)
            Spacer()
            Button(action: {
                Task {
                    await monitorService.refreshAllServers()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(DSDarkTheme.textSecondary)
            }
            .buttonStyle(.borderless)
            .help("Refresh all servers")
        }
        .padding(DSSpacing.md)
        .background(DSDarkTheme.surface)
    }

    private var emptyStateView: some View {
        VStack(spacing: DSSpacing.md) {
            Image(systemName: "server.rack")
                .font(.system(size: 40))
                .foregroundColor(DSDarkTheme.textTertiary)
            Text("No servers configured")
                .font(DSTypography.subheadline)
                .foregroundColor(DSDarkTheme.textSecondary)
            Text("Open Settings to add servers")
                .font(DSTypography.caption)
                .foregroundColor(DSDarkTheme.textTertiary)
            Button("Open Settings") {
                openSettings()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DSSpacing.xxl)
        .background(DSDarkTheme.background)
    }

    private var serverListView: some View {
        ScrollView {
            LazyVStack(spacing: DSSpacing.sm) {
                ForEach(monitorService.servers) { server in
                    MenuBarServerRow(
                        server: server,
                        stats: monitorService.stats[server.id]
                    )
                }
            }
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
        }
        .frame(maxHeight: 320)
    }

    private var footerView: some View {
        HStack {
            Circle()
                .fill(monitorService.isMonitoring ? DSDarkTheme.online : DSDarkTheme.textTertiary)
                .frame(width: 8, height: 8)
            Text(monitorService.isMonitoring ? "Monitoring" : "Paused")
                .font(DSTypography.caption)
                .foregroundColor(DSDarkTheme.textSecondary)

            Spacer()

            Button("Settings") {
                openSettings()
            }
            .buttonStyle(.borderless)
            .foregroundColor(DSDarkTheme.textSecondary)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundColor(DSDarkTheme.textSecondary)
        }
        .padding(DSSpacing.md)
        .background(DSDarkTheme.surface)
    }

    private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

// MARK: - Menu Bar Server Row (Compact Termius Style)

struct MenuBarServerRow: View {
    let server: Server
    let stats: ServerStats?

    private var isOnline: Bool {
        stats?.status == .online
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            // Header row
            HStack(spacing: DSSpacing.md) {
                // Status bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                    .frame(width: 3, height: 40)

                // Server info
                VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                    Text(server.name)
                        .font(DSTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DSDarkTheme.textPrimary)

                    Text(server.host)
                        .font(DSTypography.caption)
                        .foregroundColor(DSDarkTheme.textSecondary)
                }

                Spacer()

                // Status badge
                Text(stats?.status.rawValue ?? "Unknown")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                    .padding(.horizontal, DSSpacing.sm)
                    .padding(.vertical, DSSpacing.xxs)
                    .background((isOnline ? DSDarkTheme.online : DSDarkTheme.offline).opacity(0.15))
                    .cornerRadius(DSRadius.sm)
            }

            // Stats row (when online)
            if let stats = stats, stats.status == .online {
                HStack(spacing: 0) {
                    if let cpu = stats.cpuLoad {
                        MenuBarStatItem(
                            icon: "cpu",
                            value: String(format: "%.2f", cpu.load1)
                        )
                    }

                    if let memory = stats.memory {
                        Divider()
                            .frame(height: 24)
                            .background(DSDarkTheme.divider)
                        MenuBarStatItem(
                            icon: "memorychip",
                            value: String(format: "%.0f%%", memory.usagePercent),
                            color: DSColor.progress(for: memory.usagePercent / 100)
                        )
                    }

                    if let disk = stats.disk {
                        Divider()
                            .frame(height: 24)
                            .background(DSDarkTheme.divider)
                        MenuBarStatItem(
                            icon: "internaldrive",
                            value: String(format: "%.0f%%", disk.usagePercent),
                            color: DSColor.progress(for: disk.usagePercent / 100)
                        )
                    }
                }
                .padding(.leading, DSSpacing.lg)
            }
        }
        .padding(DSSpacing.md)
        .background(DSDarkTheme.surface)
        .cornerRadius(DSRadius.md)
    }
}

struct MenuBarStatItem: View {
    let icon: String
    let value: String
    var color: Color = .primary

    var body: some View {
        HStack(spacing: DSSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(DSDarkTheme.textTertiary)

            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}
