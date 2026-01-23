//
//  StatCardChoice.swift
//  ServerMonitor
//
//  Chosen design: Compact Horizontal (Candidate B)
//

import SwiftUI

/*
 DESIGN DECISION
 ===============

 Chosen: Candidate B - Compact Horizontal

 Features:
 - Large circular icon on left with accent background
 - Uppercase label above value
 - Progress bar below value (optional)
 - Horizontal layout saves vertical space

 Rationale:
 - More space-efficient than vertical layout
 - Icon creates visual anchor
 - Works well in grids and side-by-side layouts
 - Modern, dashboard-style appearance

 Rejected:
 - A (Vertical): Takes more vertical space
 - C (Minimal): Too sparse, icon too small
 - D (Dark): Good for dark theme but B adapts to both
 */

// MARK: - Chosen Design

struct DSStatCard: View {
    let title: String
    let icon: String
    let value: String
    let detail: String
    var progress: Double? = nil

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
            }

            // Stats
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(title.uppercased())
                    .font(DSTypography.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(DSTypography.title3)
                    .fontWeight(.semibold)

                if let progress = progress {
                    ProgressView(value: progress)
                        .tint(DSColor.progress(for: progress))
                }
            }

            Spacer()
        }
        .padding(DSSpacing.md)
        .background(DSColor.cardBackground)
        .cornerRadius(DSRadius.md)
    }
}

// MARK: - Dark Theme Variant

struct DSStatCardDark: View {
    let title: String
    let icon: String
    let value: String
    let detail: String
    var progress: Double? = nil

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
            }

            // Stats
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(title.uppercased())
                    .font(DSTypography.caption)
                    .foregroundColor(DSDarkTheme.textTertiary)

                Text(value)
                    .font(DSTypography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DSDarkTheme.textPrimary)

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

            Spacer()
        }
        .padding(DSSpacing.md)
        .background(DSDarkTheme.surface)
        .cornerRadius(DSRadius.md)
    }
}

// MARK: - Previews

#Preview("Chosen Design - Light") {
    VStack(spacing: DSSpacing.md) {
        DSStatCard(
            title: "CPU Load",
            icon: "cpu",
            value: "0.45 / 0.32 / 0.28",
            detail: "1 min / 5 min / 15 min"
        )

        DSStatCard(
            title: "Memory",
            icon: "memorychip",
            value: "4.2 GB / 8.0 GB",
            detail: "Used / Total",
            progress: 0.52
        )

        DSStatCard(
            title: "Disk",
            icon: "internaldrive",
            value: "120 GB / 500 GB",
            detail: "Used / Total",
            progress: 0.24
        )
    }
    .padding()
    .frame(width: 350)
}

#Preview("Chosen Design - Dark") {
    VStack(spacing: DSSpacing.md) {
        DSStatCardDark(
            title: "CPU Load",
            icon: "cpu",
            value: "0.45 / 0.32 / 0.28",
            detail: "1 min / 5 min / 15 min"
        )

        DSStatCardDark(
            title: "Memory",
            icon: "memorychip",
            value: "4.2 GB / 8.0 GB",
            detail: "Used / Total",
            progress: 0.52
        )

        DSStatCardDark(
            title: "Disk",
            icon: "internaldrive",
            value: "120 GB / 500 GB",
            detail: "Used / Total",
            progress: 0.24
        )
    }
    .padding()
    .frame(width: 350)
    .background(DSDarkTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Grid Layout") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpacing.md) {
        DSStatCardDark(title: "CPU", icon: "cpu", value: "45%", detail: "Load", progress: 0.45)
        DSStatCardDark(title: "Memory", icon: "memorychip", value: "62%", detail: "Used", progress: 0.62)
        DSStatCardDark(title: "Disk", icon: "internaldrive", value: "24%", detail: "Used", progress: 0.24)
        DSStatCardDark(title: "Uptime", icon: "clock", value: "45d", detail: "3h 22m")
    }
    .padding()
    .frame(width: 500)
    .background(DSDarkTheme.background)
    .preferredColorScheme(.dark)
}
