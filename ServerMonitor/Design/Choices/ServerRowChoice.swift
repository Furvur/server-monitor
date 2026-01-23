//
//  ServerRowChoice.swift
//  ServerMonitor
//
//  Chosen design: Termius Card Style (Candidate B)
//

import SwiftUI

/*
 DESIGN DECISION
 ===============

 Chosen: Candidate B - Termius Card Style

 Features:
 - Server icon with status ring (green/red border)
 - Server name with favorite star indicator
 - Connection string (user@host)
 - Status badge pill (Online/Offline)
 - Dark surface background with selection state

 Rationale:
 - Professional, polished appearance
 - Clear visual hierarchy
 - Status immediately visible via ring + badge
 - Consistent with Termius design language

 Rejected:
 - A (Current): Too basic for the new design direction
 - C (Minimal): Leading bar interesting but less rich
 - D (With Stats): Good but adds complexity; stats shown in detail view
 */

// MARK: - Chosen Design

struct DSServerRow: View {
    let name: String
    let host: String
    let username: String
    let isOnline: Bool
    let isFavorite: Bool
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

                Circle()
                    .stroke(isOnline ? DSDarkTheme.online : DSDarkTheme.offline, lineWidth: 2)
                    .frame(width: 40, height: 40)
            }

            // Server info
            VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                HStack {
                    Text(name)
                        .font(DSTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DSDarkTheme.textPrimary)

                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }

                Text("\(username)@\(host)")
                    .font(DSTypography.caption)
                    .foregroundColor(DSDarkTheme.textSecondary)
            }

            Spacer()

            // Status badge
            Text(isOnline ? "Online" : "Offline")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xxs)
                .background((isOnline ? DSDarkTheme.online : DSDarkTheme.offline).opacity(0.15))
                .cornerRadius(DSRadius.sm)
        }
        .padding(DSSpacing.md)
        .background(isSelected ? DSDarkTheme.surfaceActive : DSDarkTheme.surface)
        .cornerRadius(DSRadius.md)
    }
}

// MARK: - Preview

#Preview("Chosen Design") {
    VStack(spacing: DSSpacing.sm) {
        DSServerRow(
            name: "Production API",
            host: "api.example.com",
            username: "deploy",
            isOnline: true,
            isFavorite: true,
            isSelected: true
        )

        DSServerRow(
            name: "Staging DB",
            host: "192.168.1.50",
            username: "root",
            isOnline: true,
            isFavorite: false
        )

        DSServerRow(
            name: "Dev Server",
            host: "dev.local",
            username: "developer",
            isOnline: false,
            isFavorite: false
        )
    }
    .padding()
    .frame(width: 380)
    .background(DSDarkTheme.background)
    .preferredColorScheme(.dark)
}
