//
//  SidebarChoice.swift
//  ServerMonitor
//
//  Chosen design: Termius Grouped Sidebar (Candidate B)
//

import SwiftUI

/*
 DESIGN DECISION
 ===============

 Chosen: Candidate B - Termius Grouped Sidebar

 Features:
 - Search bar at top
 - Collapsible server groups (Favorites, Production, Development)
 - Group headers with count badges
 - Status dots + server names
 - Favorite star indicators
 - Bottom toolbar (add, folder, settings)

 Rationale:
 - Organizes servers logically by purpose
 - Search enables quick access at scale
 - Collapsible groups reduce visual clutter
 - Consistent with Termius navigation patterns

 Rejected:
 - A (Current): Basic list, no organization
 - C (Icon Rail): Too compact, loses context; could use as collapsed state later
 */

// MARK: - Chosen Design Components

struct DSSidebar: View {
    let groups: [(name: String, servers: [SidebarServer])]
    let selectedServerId: UUID?
    let onSelectServer: (UUID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            DSSearchBar(placeholder: "Search servers...")
                .padding(DSSpacing.md)

            Divider().background(DSDarkTheme.divider)

            // Grouped server list
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    ForEach(groups, id: \.name) { group in
                        DSSidebarGroup(
                            name: group.name,
                            servers: group.servers,
                            selectedServerId: selectedServerId,
                            onSelectServer: onSelectServer
                        )
                    }
                }
                .padding(DSSpacing.md)
            }

            Divider().background(DSDarkTheme.divider)

            // Bottom toolbar
            DSSidebarToolbar()
        }
        .frame(width: 260)
        .background(DSDarkTheme.surface)
    }
}

// MARK: - Supporting Types

struct SidebarServer: Identifiable {
    let id: UUID
    let name: String
    let isOnline: Bool
    let isFavorite: Bool
}

// MARK: - Search Bar

struct DSSearchBar: View {
    let placeholder: String
    @State private var searchText = ""

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DSDarkTheme.textTertiary)
                .font(.system(size: 13))

            TextField(placeholder, text: $searchText)
                .textFieldStyle(.plain)
                .font(DSTypography.subheadline)
                .foregroundColor(DSDarkTheme.textPrimary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DSDarkTheme.textTertiary)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DSSpacing.sm)
        .background(DSDarkTheme.surfaceHover)
        .cornerRadius(DSRadius.sm)
    }
}

// MARK: - Sidebar Group

struct DSSidebarGroup: View {
    let name: String
    let servers: [SidebarServer]
    let selectedServerId: UUID?
    let onSelectServer: (UUID) -> Void
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            // Group header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
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
            }
            .buttonStyle(.plain)

            // Server rows
            if isExpanded {
                VStack(spacing: DSSpacing.xxs) {
                    ForEach(servers) { server in
                        DSSidebarRow(
                            server: server,
                            isSelected: selectedServerId == server.id
                        )
                        .onTapGesture {
                            onSelectServer(server.id)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Sidebar Row

struct DSSidebarRow: View {
    let server: SidebarServer
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

// MARK: - Sidebar Toolbar

struct DSSidebarToolbar: View {
    var body: some View {
        HStack {
            Button {} label: {
                Image(systemName: "plus")
                    .font(.system(size: 14))
                    .foregroundColor(DSDarkTheme.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {} label: {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 14))
                    .foregroundColor(DSDarkTheme.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer().frame(width: DSSpacing.lg)

            Button {} label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundColor(DSDarkTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(DSSpacing.md)
    }
}

// MARK: - Preview

#Preview("Chosen Design") {
    DSSidebar(
        groups: [
            ("Favorites", [
                SidebarServer(id: UUID(), name: "Production API", isOnline: true, isFavorite: true),
                SidebarServer(id: UUID(), name: "Backup Node", isOnline: true, isFavorite: true),
            ]),
            ("Production", [
                SidebarServer(id: UUID(), name: "Production API", isOnline: true, isFavorite: true),
            ]),
            ("Development", [
                SidebarServer(id: UUID(), name: "Staging DB", isOnline: true, isFavorite: false),
                SidebarServer(id: UUID(), name: "Dev Server", isOnline: false, isFavorite: false),
            ]),
        ],
        selectedServerId: nil,
        onSelectServer: { _ in }
    )
    .frame(height: 500)
    .preferredColorScheme(.dark)
}
