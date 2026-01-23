//
//  SidebarCandidates.swift
//  ServerMonitor
//
//  Termius-inspired sidebar layout candidates.
//  Simplified for stable previews.
//

import SwiftUI

// MARK: - Candidate A: Current Sidebar

/// Current production sidebar - standard macOS list
struct SidebarCandidateA: View {
    var body: some View {
        List {
            ForEach(PreviewServer.samples, id: \.name) { server in
                HStack {
                    Circle()
                        .fill(server.isOnline ? DSColor.online : DSColor.offline)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading) {
                        Text(server.name)
                            .font(DSTypography.subheadline)
                        Text(server.host)
                            .font(DSTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, DSSpacing.xxs)
            }
        }
        .listStyle(.sidebar)
    }
}

// MARK: - Candidate B: Termius Grouped Sidebar

/// Termius-style sidebar with groups and search
struct SidebarCandidateB: View {
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))

                Text("Search servers...")
                    .font(DSTypography.subheadline)
                    .foregroundColor(DSDarkTheme.textTertiary)

                Spacer()
            }
            .padding(DSSpacing.sm)
            .background(Color.white.opacity(0.05))
            .cornerRadius(DSRadius.sm)
            .padding(DSSpacing.md)

            Divider().background(DSDarkTheme.divider)

            // Grouped server list
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    // Favorites group
                    SidebarGroupStatic(
                        name: "Favorites",
                        servers: PreviewServer.samples.filter { $0.isFavorite }
                    )

                    // Production group
                    SidebarGroupStatic(
                        name: "Production",
                        servers: PreviewServer.samples.filter { $0.tags.contains("production") }
                    )

                    // Development group
                    SidebarGroupStatic(
                        name: "Development",
                        servers: PreviewServer.samples.filter { $0.tags.contains("development") || $0.tags.contains("staging") }
                    )
                }
                .padding(DSSpacing.md)
            }

            Divider().background(DSDarkTheme.divider)

            // Bottom toolbar
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 14))
                    .foregroundColor(DSDarkTheme.textSecondary)

                Spacer()

                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 14))
                    .foregroundColor(DSDarkTheme.textSecondary)

                Spacer().frame(width: DSSpacing.lg)

                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundColor(DSDarkTheme.textSecondary)
            }
            .padding(DSSpacing.md)
        }
        .frame(width: 260)
        .background(DSDarkTheme.surface)
    }
}

struct SidebarGroupStatic: View {
    let name: String
    let servers: [PreviewServer]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            // Group header
            HStack {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(DSDarkTheme.textTertiary)
                    .frame(width: 12)

                Text(name.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DSDarkTheme.textTertiary)

                Spacer()

                Text("\(servers.count)")
                    .font(.system(size: 10))
                    .foregroundColor(DSDarkTheme.textTertiary)
                    .padding(.horizontal, DSSpacing.xs)
                    .padding(.vertical, 2)
                    .background(DSDarkTheme.surfaceActive)
                    .cornerRadius(4)
            }

            // Server rows
            VStack(spacing: DSSpacing.xxs) {
                ForEach(servers, id: \.name) { server in
                    SidebarRowStatic(server: server, isSelected: server.name == "Production API")
                }
            }
        }
    }
}

struct SidebarRowStatic: View {
    let server: PreviewServer
    let isSelected: Bool

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Circle()
                .fill(server.isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                .frame(width: 6, height: 6)

            Text(server.name)
                .font(DSTypography.subheadline)
                .foregroundColor(isSelected ? .white : DSDarkTheme.textPrimary)
                .lineLimit(1)

            Spacer()

            if server.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, DSSpacing.sm)
        .padding(.vertical, DSSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DSRadius.sm)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
    }
}

// MARK: - Candidate C: Termius Icon Sidebar

/// Ultra-compact icon sidebar like Termius collapsed view
struct SidebarCandidateC: View {
    var body: some View {
        HStack(spacing: 0) {
            // Icon rail
            VStack(spacing: DSSpacing.xs) {
                // App icon
                Image(systemName: "server.rack")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                    .frame(width: 44, height: 44)

                Divider()
                    .frame(width: 24)
                    .background(DSDarkTheme.divider)
                    .padding(.vertical, DSSpacing.sm)

                // Server icons
                ForEach(Array(PreviewServer.samples.enumerated()), id: \.1.name) { index, server in
                    IconItemStatic(server: server, isSelected: index == 0)
                }

                Spacer()

                // Add button
                Image(systemName: "plus.circle")
                    .font(.system(size: 18))
                    .foregroundColor(DSDarkTheme.textTertiary)
                    .frame(width: 44, height: 44)

                // Settings
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundColor(DSDarkTheme.textTertiary)
                    .frame(width: 44, height: 44)
            }
            .padding(.vertical, DSSpacing.md)
            .frame(width: 56)
            .background(DSDarkTheme.background)

            // Expanded panel
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                let server = PreviewServer.samples[0]

                Text(server.name)
                    .font(DSTypography.headline)
                    .foregroundColor(DSDarkTheme.textPrimary)

                Text("\(server.username)@\(server.host)")
                    .font(DSTypography.caption)
                    .foregroundColor(DSDarkTheme.textSecondary)

                Divider().background(DSDarkTheme.divider)

                // Tags
                HStack {
                    ForEach(server.tags, id: \.self) { tag in
                        Text(tag)
                            .font(DSTypography.caption2)
                            .foregroundColor(DSDarkTheme.textPrimary)
                            .padding(.horizontal, DSSpacing.sm)
                            .padding(.vertical, DSSpacing.xxs)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Spacer()
            }
            .padding(DSSpacing.md)
            .frame(width: 200)
            .background(DSDarkTheme.surface)
        }
    }
}

struct IconItemStatic: View {
    let server: PreviewServer
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DSRadius.sm)
                .fill(isSelected ? Color.accentColor : Color.clear)
                .frame(width: 36, height: 36)

            Text(String(server.name.prefix(1)).uppercased())
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : DSDarkTheme.textPrimary)

            // Status dot
            Circle()
                .fill(server.isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(DSDarkTheme.background, lineWidth: 2)
                )
                .offset(x: 12, y: 12)
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Previews

#Preview("A: Current") {
    SidebarCandidateA()
        .frame(width: 220, height: 400)
}

#Preview("B: Grouped") {
    SidebarCandidateB()
        .frame(height: 500)
        .preferredColorScheme(.dark)
}

#Preview("C: Icon Rail") {
    SidebarCandidateC()
        .frame(height: 500)
        .preferredColorScheme(.dark)
}

#Preview("All Candidates") {
    HStack(spacing: 1) {
        SidebarCandidateC()
            .frame(width: 256)

        Rectangle()
            .fill(DSDarkTheme.divider)
            .frame(width: 1)

        SidebarCandidateB()
    }
    .frame(height: 550)
    .background(DSDarkTheme.background)
    .preferredColorScheme(.dark)
}
