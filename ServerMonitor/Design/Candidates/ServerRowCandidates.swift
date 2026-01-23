//
//  ServerRowCandidates.swift
//  ServerMonitor
//
//  Termius-inspired design candidates for server list rows.
//  Simplified for stable previews.
//

import SwiftUI

// MARK: - Sample Data for Previews

struct PreviewServer {
    let name: String
    let host: String
    let username: String
    let isOnline: Bool
    let tags: [String]
    let isFavorite: Bool

    static let samples: [PreviewServer] = [
        PreviewServer(name: "Production API", host: "api.example.com", username: "deploy", isOnline: true, tags: ["production", "api"], isFavorite: true),
        PreviewServer(name: "Staging DB", host: "192.168.1.50", username: "root", isOnline: true, tags: ["staging", "database"], isFavorite: false),
        PreviewServer(name: "Dev Server", host: "dev.local", username: "developer", isOnline: false, tags: ["development"], isFavorite: false),
        PreviewServer(name: "Backup Node", host: "10.0.0.100", username: "admin", isOnline: true, tags: ["infrastructure"], isFavorite: true),
    ]
}

// MARK: - Candidate A: Current Design

/// Current production design - simple row with status dot
struct ServerRowCandidateA: View {
    let server: PreviewServer

    var body: some View {
        HStack {
            Circle()
                .fill(server.isOnline ? DSColor.online : DSColor.offline)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading) {
                Text(server.name)
                    .font(DSTypography.headline)
                Text("\(server.username)@\(server.host)")
                    .font(DSTypography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, DSSpacing.xxs)
    }
}

// MARK: - Candidate B: Termius Card Style

/// Termius-inspired card with icon, status ring, and clean layout
struct ServerRowCandidateB: View {
    let server: PreviewServer
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Server icon with status ring
            ZStack {
                Circle()
                    .fill(DSDarkTheme.surfaceActive)
                    .frame(width: 40, height: 40)

                Image(systemName: "server.rack")
                    .font(.system(size: 16))
                    .foregroundColor(DSDarkTheme.textPrimary)

                // Status ring
                Circle()
                    .stroke(server.isOnline ? DSDarkTheme.online : DSDarkTheme.offline, lineWidth: 2)
                    .frame(width: 40, height: 40)
            }

            // Server info
            VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                HStack {
                    Text(server.name)
                        .font(DSTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DSDarkTheme.textPrimary)

                    if server.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }

                Text("\(server.username)@\(server.host)")
                    .font(DSTypography.caption)
                    .foregroundColor(DSDarkTheme.textSecondary)
            }

            Spacer()

            // Status badge
            Text(server.isOnline ? "Online" : "Offline")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(server.isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xxs)
                .background((server.isOnline ? DSDarkTheme.online : DSDarkTheme.offline).opacity(0.15))
                .cornerRadius(DSRadius.sm)
        }
        .padding(DSSpacing.md)
        .background(isSelected ? DSDarkTheme.surfaceActive : DSDarkTheme.surface)
        .cornerRadius(DSRadius.md)
    }
}

// MARK: - Candidate C: Termius Minimal

/// Minimal Termius style - clean lines, subtle status
struct ServerRowCandidateC: View {
    let server: PreviewServer
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Leading status bar
            RoundedRectangle(cornerRadius: 2)
                .fill(server.isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                .frame(width: 3, height: 36)

            // Server info
            VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                Text(server.name)
                    .font(DSTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DSDarkTheme.textPrimary)

                HStack(spacing: DSSpacing.xs) {
                    Text(server.host)
                        .font(DSTypography.caption)
                        .foregroundColor(DSDarkTheme.textSecondary)

                    if let tag = server.tags.first {
                        Text("•")
                            .foregroundColor(DSDarkTheme.textTertiary)
                        Text(tag)
                            .font(DSTypography.caption2)
                            .foregroundColor(DSDarkTheme.textTertiary)
                            .padding(.horizontal, DSSpacing.xs)
                            .padding(.vertical, 2)
                            .background(DSDarkTheme.surfaceActive)
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            // Favorite indicator
            if server.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(isSelected ? DSDarkTheme.surfaceActive : Color.clear)
        .cornerRadius(DSRadius.sm)
    }
}

// MARK: - Candidate D: With Stats Preview

/// Termius style with inline stats preview
struct ServerRowCandidateD: View {
    let server: PreviewServer
    var isSelected: Bool = false

    // Simulated stats
    let cpuUsage: Double = 0.45
    let memoryUsage: Double = 0.62

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Avatar/Icon
            ZStack {
                RoundedRectangle(cornerRadius: DSRadius.sm)
                    .fill(server.isOnline ? DSDarkTheme.accentGradient : LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)

                Text(String(server.name.prefix(2)).uppercased())
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }

            // Server info
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                HStack(spacing: DSSpacing.xs) {
                    Text(server.name)
                        .font(DSTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DSDarkTheme.textPrimary)

                    Circle()
                        .fill(server.isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                        .frame(width: 6, height: 6)
                }

                Text("\(server.username)@\(server.host)")
                    .font(DSTypography.caption)
                    .foregroundColor(DSDarkTheme.textSecondary)
            }

            Spacer()

            // Inline stats (when online)
            if server.isOnline {
                HStack(spacing: DSSpacing.md) {
                    MiniStatView(icon: "cpu", value: cpuUsage)
                    MiniStatView(icon: "memorychip", value: memoryUsage)
                }
            }
        }
        .padding(DSSpacing.md)
        .background(isSelected ? DSDarkTheme.surfaceActive : DSDarkTheme.surface)
        .cornerRadius(DSRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

struct MiniStatView: View {
    let icon: String
    let value: Double

    var body: some View {
        HStack(spacing: DSSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(DSDarkTheme.textTertiary)

            Text("\(Int(value * 100))%")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(DSColor.progress(for: value))
        }
    }
}

// MARK: - Previews

#Preview("A: Current") {
    VStack(spacing: DSSpacing.sm) {
        ForEach(0..<2) { i in
            ServerRowCandidateA(server: PreviewServer.samples[i])
        }
    }
    .padding()
    .frame(width: 350)
}

#Preview("B: Card Style") {
    VStack(spacing: DSSpacing.sm) {
        ServerRowCandidateB(server: PreviewServer.samples[0], isSelected: true)
        ServerRowCandidateB(server: PreviewServer.samples[1])
        ServerRowCandidateB(server: PreviewServer.samples[2])
    }
    .padding()
    .frame(width: 380)
    .background(DSDarkTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("C: Minimal") {
    VStack(spacing: DSSpacing.xxs) {
        ServerRowCandidateC(server: PreviewServer.samples[0], isSelected: true)
        ServerRowCandidateC(server: PreviewServer.samples[1])
        ServerRowCandidateC(server: PreviewServer.samples[2])
    }
    .padding()
    .frame(width: 350)
    .background(DSDarkTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("D: With Stats") {
    VStack(spacing: DSSpacing.sm) {
        ServerRowCandidateD(server: PreviewServer.samples[0], isSelected: true)
        ServerRowCandidateD(server: PreviewServer.samples[1])
        ServerRowCandidateD(server: PreviewServer.samples[2])
    }
    .padding()
    .frame(width: 420)
    .background(DSDarkTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("All Candidates") {
    ScrollView {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            Text("Server Row Candidates")
                .font(DSTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(DSDarkTheme.textPrimary)

            Group {
                Text("A: Current Design")
                    .font(DSTypography.caption)
                    .foregroundColor(DSDarkTheme.textTertiary)

                VStack(spacing: DSSpacing.sm) {
                    ServerRowCandidateA(server: PreviewServer.samples[0])
                    ServerRowCandidateA(server: PreviewServer.samples[2])
                }
            }

            Divider().background(DSDarkTheme.divider)

            Group {
                Text("B: Termius Card Style")
                    .font(DSTypography.caption)
                    .foregroundColor(DSDarkTheme.textTertiary)

                VStack(spacing: DSSpacing.sm) {
                    ServerRowCandidateB(server: PreviewServer.samples[0], isSelected: true)
                    ServerRowCandidateB(server: PreviewServer.samples[2])
                }
            }

            Divider().background(DSDarkTheme.divider)

            Group {
                Text("C: Termius Minimal")
                    .font(DSTypography.caption)
                    .foregroundColor(DSDarkTheme.textTertiary)

                VStack(spacing: DSSpacing.xxs) {
                    ServerRowCandidateC(server: PreviewServer.samples[0], isSelected: true)
                    ServerRowCandidateC(server: PreviewServer.samples[2])
                }
            }

            Divider().background(DSDarkTheme.divider)

            Group {
                Text("D: With Stats Preview")
                    .font(DSTypography.caption)
                    .foregroundColor(DSDarkTheme.textTertiary)

                VStack(spacing: DSSpacing.sm) {
                    ServerRowCandidateD(server: PreviewServer.samples[0], isSelected: true)
                    ServerRowCandidateD(server: PreviewServer.samples[2])
                }
            }
        }
        .padding(DSSpacing.xl)
    }
    .frame(width: 420, height: 900)
    .background(DSDarkTheme.background)
    .preferredColorScheme(.dark)
}
