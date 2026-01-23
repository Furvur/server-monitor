//
//  DetailViewCandidates.swift
//  ServerMonitor
//
//  Termius-inspired detail view candidates for server information.
//

import SwiftUI

// MARK: - Sample Stats for Previews

struct PreviewStats {
    let cpuLoad: (one: Double, five: Double, fifteen: Double) = (0.45, 0.32, 0.28)
    let memoryUsed: Double = 4.2
    let memoryTotal: Double = 8.0
    let diskUsed: Double = 120
    let diskTotal: Double = 500
    let uptime: String = "45 days, 3 hours"
    let lastUpdated: Date = Date()

    var memoryPercent: Double { memoryUsed / memoryTotal }
    var diskPercent: Double { diskUsed / diskTotal }

    static let sample = PreviewStats()
}

// MARK: - Candidate A: Current Design

/// Current production layout - vertical cards
struct DetailViewCandidateA: View {
    let server: PreviewServer
    let stats: PreviewStats

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    HStack {
                        Circle()
                            .fill(server.isOnline ? DSColor.online : DSColor.offline)
                            .frame(width: 12, height: 12)
                        Text(server.isOnline ? "Online" : "Offline")
                            .font(DSTypography.title2)
                            .fontWeight(.medium)
                        Spacer()
                    }

                    Text("\(server.username)@\(server.host)")
                        .font(DSTypography.subheadline)
                        .foregroundColor(.secondary)

                    Text("Last updated: \(stats.lastUpdated.formatted())")
                        .font(DSTypography.caption)
                        .foregroundColor(.secondary)
                }

                // Stats
                VStack(spacing: DSSpacing.lg) {
                    StatCardCandidateA(
                        title: "CPU Load",
                        icon: "cpu",
                        value: String(format: "%.2f / %.2f / %.2f", stats.cpuLoad.one, stats.cpuLoad.five, stats.cpuLoad.fifteen),
                        detail: "1 min / 5 min / 15 min"
                    )

                    StatCardCandidateA(
                        title: "Memory",
                        icon: "memorychip",
                        value: String(format: "%.1f GB / %.1f GB", stats.memoryUsed, stats.memoryTotal),
                        detail: "Used / Total",
                        progress: stats.memoryPercent
                    )

                    StatCardCandidateA(
                        title: "Disk",
                        icon: "internaldrive",
                        value: String(format: "%.0f GB / %.0f GB", stats.diskUsed, stats.diskTotal),
                        detail: "Used / Total",
                        progress: stats.diskPercent
                    )
                }
            }
            .padding(DSSpacing.xl)
        }
    }
}

// MARK: - Candidate B: Termius Dashboard Style

/// Termius-inspired dashboard with header card and grid stats
struct DetailViewCandidateB: View {
    let server: PreviewServer
    let stats: PreviewStats

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.lg) {
                // Hero header card
                HStack(spacing: DSSpacing.lg) {
                    // Server avatar
                    ZStack {
                        RoundedRectangle(cornerRadius: DSRadius.md)
                            .fill(DSDarkTheme.accentGradient)
                            .frame(width: 64, height: 64)

                        Text(String(server.name.prefix(2)).uppercased())
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        Text(server.name)
                            .font(DSTypography.title2)
                            .fontWeight(.semibold)

                        Text("\(server.username)@\(server.host)")
                            .font(DSTypography.subheadline)
                            .foregroundColor(DSDarkTheme.textSecondary)

                        HStack(spacing: DSSpacing.sm) {
                            // Status badge
                            HStack(spacing: DSSpacing.xxs) {
                                Circle()
                                    .fill(server.isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                                    .frame(width: 6, height: 6)
                                Text(server.isOnline ? "Online" : "Offline")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(server.isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                            .padding(.horizontal, DSSpacing.sm)
                            .padding(.vertical, DSSpacing.xxs)
                            .background((server.isOnline ? DSDarkTheme.online : DSDarkTheme.offline).opacity(0.15))
                            .cornerRadius(DSRadius.sm)

                            // Uptime
                            Text("Uptime: \(stats.uptime)")
                                .font(DSTypography.caption)
                                .foregroundColor(DSDarkTheme.textTertiary)
                        }
                    }

                    Spacer()

                    // Quick actions
                    VStack(spacing: DSSpacing.sm) {
                        ActionButton(icon: "terminal", label: "Terminal")
                        ActionButton(icon: "arrow.clockwise", label: "Refresh")
                    }
                }
                .padding(DSSpacing.lg)
                .background(DSDarkTheme.surface)
                .cornerRadius(DSRadius.lg)

                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: DSSpacing.md) {
                    DashboardStatCard(
                        title: "CPU",
                        value: String(format: "%.0f%%", stats.cpuLoad.one * 100),
                        icon: "cpu",
                        trend: -0.05
                    )

                    DashboardStatCard(
                        title: "Memory",
                        value: String(format: "%.0f%%", stats.memoryPercent * 100),
                        icon: "memorychip",
                        progress: stats.memoryPercent
                    )

                    DashboardStatCard(
                        title: "Disk",
                        value: String(format: "%.0f%%", stats.diskPercent * 100),
                        icon: "internaldrive",
                        progress: stats.diskPercent
                    )

                    DashboardStatCard(
                        title: "Uptime",
                        value: "45d",
                        icon: "clock",
                        subtitle: "3h 22m"
                    )
                }

                // Tags section
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("TAGS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(DSDarkTheme.textTertiary)

                    HStack(spacing: DSSpacing.sm) {
                        ForEach(server.tags, id: \.self) { tag in
                            Text(tag)
                                .font(DSTypography.caption)
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
            .padding(DSSpacing.lg)
        }
        .background(DSDarkTheme.background)
    }
}

struct ActionButton: View {
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

struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    var progress: Double? = nil
    var trend: Double? = nil
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

                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(abs(Int(trend * 100)))%")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(trend >= 0 ? DSDarkTheme.warning : DSDarkTheme.online)
                }
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

// MARK: - Candidate C: Termius Compact

/// Ultra-compact Termius style for information density
struct DetailViewCandidateC: View {
    let server: PreviewServer
    let stats: PreviewStats

    var body: some View {
        VStack(spacing: 0) {
            // Compact header bar
            HStack(spacing: DSSpacing.md) {
                ZStack {
                    Circle()
                        .fill(DSDarkTheme.accentGradient)
                        .frame(width: 36, height: 36)

                    Text(String(server.name.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(server.name)
                        .font(DSTypography.headline)

                    Text(server.host)
                        .font(DSTypography.caption)
                        .foregroundColor(DSDarkTheme.textSecondary)
                }

                Spacer()

                Circle()
                    .fill(server.isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                    .frame(width: 8, height: 8)
            }
            .padding(DSSpacing.md)
            .background(DSDarkTheme.surface)

            Divider().background(DSDarkTheme.divider)

            // Inline stats bar
            HStack(spacing: 0) {
                CompactStatItem(
                    icon: "cpu",
                    label: "CPU",
                    value: String(format: "%.0f%%", stats.cpuLoad.one * 100)
                )

                Divider().background(DSDarkTheme.divider)

                CompactStatItem(
                    icon: "memorychip",
                    label: "MEM",
                    value: String(format: "%.0f%%", stats.memoryPercent * 100),
                    color: DSColor.progress(for: stats.memoryPercent)
                )

                Divider().background(DSDarkTheme.divider)

                CompactStatItem(
                    icon: "internaldrive",
                    label: "DISK",
                    value: String(format: "%.0f%%", stats.diskPercent * 100),
                    color: DSColor.progress(for: stats.diskPercent)
                )

                Divider().background(DSDarkTheme.divider)

                CompactStatItem(
                    icon: "clock",
                    label: "UP",
                    value: "45d"
                )
            }
            .frame(height: 56)
            .background(DSDarkTheme.surface)

            Divider().background(DSDarkTheme.divider)

            // Services list
            ScrollView {
                VStack(spacing: 0) {
                    ServiceRowCompact(name: "nginx", status: "running", port: "80, 443")
                    Divider().background(DSDarkTheme.divider).padding(.leading, 44)
                    ServiceRowCompact(name: "postgresql", status: "running", port: "5432")
                    Divider().background(DSDarkTheme.divider).padding(.leading, 44)
                    ServiceRowCompact(name: "redis", status: "running", port: "6379")
                    Divider().background(DSDarkTheme.divider).padding(.leading, 44)
                    ServiceRowCompact(name: "docker", status: "running", port: "-")
                }
            }
            .background(DSDarkTheme.background)
        }
    }
}

struct CompactStatItem: View {
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

struct ServiceRowCompact: View {
    let name: String
    let status: String
    let port: String

    var isRunning: Bool { status == "running" }

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

            Text(status)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isRunning ? DSDarkTheme.online : DSDarkTheme.offline)
                .padding(.trailing, DSSpacing.lg)
        }
        .frame(height: 44)
        .background(DSDarkTheme.surface)
    }
}

// MARK: - Previews

#Preview("Candidate A - Current") {
    DetailViewCandidateA(
        server: PreviewServer.samples[0],
        stats: PreviewStats.sample
    )
    .frame(width: 500, height: 600)
}

#Preview("Candidate B - Dashboard") {
    DetailViewCandidateB(
        server: PreviewServer.samples[0],
        stats: PreviewStats.sample
    )
    .frame(width: 500, height: 650)
    .preferredColorScheme(.dark)
}

#Preview("Candidate C - Compact") {
    DetailViewCandidateC(
        server: PreviewServer.samples[0],
        stats: PreviewStats.sample
    )
    .frame(width: 400, height: 500)
    .preferredColorScheme(.dark)
}

#Preview("All Candidates") {
    HStack(spacing: 0) {
        DetailViewCandidateB(
            server: PreviewServer.samples[0],
            stats: PreviewStats.sample
        )
        .frame(width: 450)

        Divider()

        DetailViewCandidateC(
            server: PreviewServer.samples[0],
            stats: PreviewStats.sample
        )
        .frame(width: 350)
    }
    .frame(height: 650)
    .preferredColorScheme(.dark)
}
