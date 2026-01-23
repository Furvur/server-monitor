//
//  DetailViewChoice.swift
//  ServerMonitor
//
//  Chosen design: Combined Dashboard + Compact (Candidates B & C)
//

import SwiftUI

/*
 DESIGN DECISION
 ===============

 Chosen: Combination of B (Dashboard) and C (Compact)

 The "All Candidates" preview showed B and C side-by-side, which
 works well as a responsive layout:
 - B (Dashboard): Full detail view with hero header, stat grid, tags
 - C (Compact): Dense information view for secondary display or menu bar

 Features from B (Dashboard):
 - Hero header card with avatar, name, connection, status badge
 - 2x2 stat grid with large values
 - Tags section
 - Action buttons (Terminal, Refresh)

 Features from C (Compact):
 - Compact header bar
 - Inline stats row
 - Services list with status

 Usage:
 - DSDetailView: Main window detail pane
 - DSDetailViewCompact: Menu bar popover or narrow layouts
 */

// MARK: - Dashboard Detail View (Candidate B)

struct DSDetailView: View {
    let serverName: String
    let host: String
    let username: String
    let isOnline: Bool
    let uptime: String
    let tags: [String]
    let cpuPercent: Double
    let memoryPercent: Double
    let diskPercent: Double

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.lg) {
                // Hero header card
                heroHeader

                // Stats grid
                statsGrid

                // Tags section
                tagsSection
            }
            .padding(DSSpacing.lg)
        }
        .background(DSDarkTheme.background)
    }

    private var heroHeader: some View {
        HStack(spacing: DSSpacing.lg) {
            // Server avatar
            ZStack {
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .fill(DSDarkTheme.accentGradient)
                    .frame(width: 64, height: 64)

                Text(String(serverName.prefix(2)).uppercased())
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(serverName)
                    .font(DSTypography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(DSDarkTheme.textPrimary)

                Text("\(username)@\(host)")
                    .font(DSTypography.subheadline)
                    .foregroundColor(DSDarkTheme.textSecondary)

                HStack(spacing: DSSpacing.sm) {
                    // Status badge
                    HStack(spacing: DSSpacing.xxs) {
                        Circle()
                            .fill(isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                            .frame(width: 6, height: 6)
                        Text(isOnline ? "Online" : "Offline")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                    .padding(.horizontal, DSSpacing.sm)
                    .padding(.vertical, DSSpacing.xxs)
                    .background((isOnline ? DSDarkTheme.online : DSDarkTheme.offline).opacity(0.15))
                    .cornerRadius(DSRadius.sm)

                    Text("Uptime: \(uptime)")
                        .font(DSTypography.caption)
                        .foregroundColor(DSDarkTheme.textTertiary)
                }
            }

            Spacer()

            // Quick actions
            VStack(spacing: DSSpacing.sm) {
                DSActionButton(icon: "terminal", label: "Terminal")
                DSActionButton(icon: "arrow.clockwise", label: "Refresh")
            }
        }
        .padding(DSSpacing.lg)
        .background(DSDarkTheme.surface)
        .cornerRadius(DSRadius.lg)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpacing.md) {
            DSDashboardStatCard(title: "CPU", value: "\(Int(cpuPercent * 100))%", icon: "cpu")
            DSDashboardStatCard(title: "Memory", value: "\(Int(memoryPercent * 100))%", icon: "memorychip", progress: memoryPercent)
            DSDashboardStatCard(title: "Disk", value: "\(Int(diskPercent * 100))%", icon: "internaldrive", progress: diskPercent)
            DSDashboardStatCard(title: "Uptime", value: "45d", icon: "clock", subtitle: "3h 22m")
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("TAGS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(DSDarkTheme.textTertiary)

            HStack(spacing: DSSpacing.sm) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(DSTypography.caption)
                        .foregroundColor(DSDarkTheme.textPrimary)
                        .padding(.horizontal, DSSpacing.md)
                        .padding(.vertical, DSSpacing.xs)
                        .background(DSDarkTheme.surfaceActive)
                        .cornerRadius(DSRadius.sm)
                }

                Button {} label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .foregroundColor(DSDarkTheme.textTertiary)
                        .padding(DSSpacing.xs)
                        .background(DSDarkTheme.surfaceHover)
                        .cornerRadius(DSRadius.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DSSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSDarkTheme.surface)
        .cornerRadius(DSRadius.lg)
    }
}

// MARK: - Supporting Components

struct DSActionButton: View {
    let icon: String
    let label: String

    var body: some View {
        Button {} label: {
            HStack(spacing: DSSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(DSDarkTheme.textSecondary)
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .background(DSDarkTheme.surfaceHover)
            .cornerRadius(DSRadius.sm)
        }
        .buttonStyle(.plain)
    }
}

struct DSDashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    var progress: Double? = nil
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(DSDarkTheme.textTertiary)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DSDarkTheme.textSecondary)

                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: DSSpacing.xs) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(DSDarkTheme.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DSTypography.caption)
                        .foregroundColor(DSDarkTheme.textTertiary)
                }
            }

            if let progress = progress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DSDarkTheme.surfaceActive)
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(DSColor.progress(for: progress))
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(DSSpacing.lg)
        .background(DSDarkTheme.surface)
        .cornerRadius(DSRadius.md)
    }
}

// MARK: - Compact Detail View (Candidate C)

struct DSDetailViewCompact: View {
    let serverName: String
    let host: String
    let isOnline: Bool
    let cpuPercent: Double
    let memoryPercent: Double
    let diskPercent: Double
    let services: [(name: String, isRunning: Bool, port: String)]

    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            compactHeader

            Divider().background(DSDarkTheme.divider)

            // Inline stats bar
            statsBar

            Divider().background(DSDarkTheme.divider)

            // Services list
            servicesList
        }
        .background(DSDarkTheme.background)
    }

    private var compactHeader: some View {
        HStack(spacing: DSSpacing.md) {
            ZStack {
                Circle()
                    .fill(DSDarkTheme.accentGradient)
                    .frame(width: 36, height: 36)

                Text(String(serverName.prefix(1)).uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(serverName)
                    .font(DSTypography.headline)
                    .foregroundColor(DSDarkTheme.textPrimary)

                Text(host)
                    .font(DSTypography.caption)
                    .foregroundColor(DSDarkTheme.textSecondary)
            }

            Spacer()

            Circle()
                .fill(isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                .frame(width: 8, height: 8)
        }
        .padding(DSSpacing.md)
        .background(DSDarkTheme.surface)
    }

    private var statsBar: some View {
        HStack(spacing: 0) {
            DSCompactStatItem(icon: "cpu", label: "CPU", value: "\(Int(cpuPercent * 100))%")
            Divider().background(DSDarkTheme.divider)
            DSCompactStatItem(icon: "memorychip", label: "MEM", value: "\(Int(memoryPercent * 100))%", color: DSColor.progress(for: memoryPercent))
            Divider().background(DSDarkTheme.divider)
            DSCompactStatItem(icon: "internaldrive", label: "DISK", value: "\(Int(diskPercent * 100))%", color: DSColor.progress(for: diskPercent))
        }
        .frame(height: 56)
        .background(DSDarkTheme.surface)
    }

    private var servicesList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(services.indices, id: \.self) { index in
                    DSServiceRow(
                        name: services[index].name,
                        isRunning: services[index].isRunning,
                        port: services[index].port
                    )
                    if index < services.count - 1 {
                        Divider()
                            .background(DSDarkTheme.divider)
                            .padding(.leading, 44)
                    }
                }
            }
        }
    }
}

struct DSCompactStatItem: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: DSSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(DSDarkTheme.textTertiary)

            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(DSDarkTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DSServiceRow: View {
    let name: String
    let isRunning: Bool
    let port: String

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            Circle()
                .fill(isRunning ? DSDarkTheme.online : DSDarkTheme.offline)
                .frame(width: 8, height: 8)
                .padding(.leading, DSSpacing.lg)

            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DSDarkTheme.textPrimary)

            Spacer()

            Text(port)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(DSDarkTheme.textTertiary)

            Text(isRunning ? "running" : "stopped")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isRunning ? DSDarkTheme.online : DSDarkTheme.offline)
                .padding(.trailing, DSSpacing.lg)
        }
        .frame(height: 44)
        .background(DSDarkTheme.surface)
    }
}

// MARK: - Previews

#Preview("Dashboard View") {
    DSDetailView(
        serverName: "Production API",
        host: "api.example.com",
        username: "deploy",
        isOnline: true,
        uptime: "45 days, 3 hours",
        tags: ["production", "api"],
        cpuPercent: 0.45,
        memoryPercent: 0.62,
        diskPercent: 0.24
    )
    .frame(width: 500, height: 600)
    .preferredColorScheme(.dark)
}

#Preview("Compact View") {
    DSDetailViewCompact(
        serverName: "Production API",
        host: "api.example.com",
        isOnline: true,
        cpuPercent: 0.45,
        memoryPercent: 0.62,
        diskPercent: 0.24,
        services: [
            ("nginx", true, "80, 443"),
            ("postgresql", true, "5432"),
            ("redis", true, "6379"),
            ("docker", true, "-"),
        ]
    )
    .frame(width: 350, height: 400)
    .preferredColorScheme(.dark)
}

#Preview("Combined Layout") {
    HStack(spacing: 1) {
        DSDetailView(
            serverName: "Production API",
            host: "api.example.com",
            username: "deploy",
            isOnline: true,
            uptime: "45 days, 3 hours",
            tags: ["production", "api"],
            cpuPercent: 0.45,
            memoryPercent: 0.62,
            diskPercent: 0.24
        )
        .frame(width: 450)

        Rectangle()
            .fill(DSDarkTheme.divider)
            .frame(width: 1)

        DSDetailViewCompact(
            serverName: "Production API",
            host: "api.example.com",
            isOnline: true,
            cpuPercent: 0.45,
            memoryPercent: 0.62,
            diskPercent: 0.24,
            services: [
                ("nginx", true, "80, 443"),
                ("postgresql", true, "5432"),
                ("redis", true, "6379"),
            ]
        )
        .frame(width: 300)
    }
    .frame(height: 600)
    .preferredColorScheme(.dark)
}
