//
//  StatCardCandidates.swift
//  ServerMonitor
//
//  Design candidates for the StatCard component.
//  Simplified for stable previews.
//

import SwiftUI

// MARK: - Candidate A: Current Design (Vertical Stack)

/// The current production design - vertical layout with icon + title header
struct StatCardCandidateA: View {
    let title: String
    let icon: String
    let value: String
    let detail: String
    var progress: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(DSTypography.title2)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(DSTypography.headline)
            }

            Text(value)
                .font(DSTypography.title)
                .fontWeight(.semibold)

            if let progress = progress {
                ProgressView(value: progress)
                    .tint(DSColor.progress(for: progress))
            }

            Text(detail)
                .font(DSTypography.caption)
                .foregroundColor(.secondary)
        }
        .padding(DSSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSColor.cardBackground)
        .cornerRadius(DSRadius.md)
    }
}

// MARK: - Candidate B: Compact Horizontal

/// Alternative design - more compact with icon on left, stats on right
struct StatCardCandidateB: View {
    let title: String
    let icon: String
    let value: String
    let detail: String
    var progress: Double? = nil

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Large icon on left
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
            }

            // Stats on right
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(title)
                    .font(DSTypography.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

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

// MARK: - Candidate C: Minimal with Large Value

/// Minimal design - emphasizes the value, de-emphasizes chrome
struct StatCardCandidateC: View {
    let title: String
    let icon: String
    let value: String
    let detail: String
    var progress: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(DSTypography.caption)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(DSTypography.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            if let progress = progress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)

                        Rectangle()
                            .fill(DSColor.progress(for: progress))
                            .frame(width: geometry.size.width * progress, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
            }

            Text(detail)
                .font(DSTypography.caption2)
                .foregroundColor(.secondary)
        }
        .padding(DSSpacing.md)
        .background(DSColor.cardBackground)
        .cornerRadius(DSRadius.md)
    }
}

// MARK: - Candidate D: Termius Dark Style

/// Termius-inspired dark card with subtle gradients
struct StatCardCandidateD: View {
    let title: String
    let icon: String
    let value: String
    let detail: String
    var progress: Double? = nil

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

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
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

            Text(detail)
                .font(DSTypography.caption)
                .foregroundColor(DSDarkTheme.textTertiary)
        }
        .padding(DSSpacing.lg)
        .background(DSDarkTheme.surface)
        .cornerRadius(DSRadius.md)
    }
}

// MARK: - Previews

#Preview("A: Current") {
    StatCardCandidateA(
        title: "Memory",
        icon: "memorychip",
        value: "4.2 GB / 8.0 GB",
        detail: "Used / Total",
        progress: 0.52
    )
    .padding()
    .frame(width: 350)
}

#Preview("B: Compact") {
    StatCardCandidateB(
        title: "Memory",
        icon: "memorychip",
        value: "4.2 GB / 8.0 GB",
        detail: "Used / Total",
        progress: 0.52
    )
    .padding()
    .frame(width: 350)
}

#Preview("C: Minimal") {
    StatCardCandidateC(
        title: "Memory",
        icon: "memorychip",
        value: "4.2 GB / 8.0 GB",
        detail: "Used / Total",
        progress: 0.52
    )
    .padding()
    .frame(width: 350)
}

#Preview("D: Termius Dark") {
    StatCardCandidateD(
        title: "Memory",
        icon: "memorychip",
        value: "4.2 GB / 8.0 GB",
        detail: "Used / Total",
        progress: 0.52
    )
    .padding()
    .frame(width: 350)
    .background(DSDarkTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("All Candidates") {
    ScrollView {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            Text("StatCard Candidates")
                .font(DSTypography.title2)
                .fontWeight(.bold)

            Group {
                Text("A: Current (Vertical)")
                    .font(DSTypography.caption)
                    .foregroundColor(.secondary)

                StatCardCandidateA(
                    title: "Memory",
                    icon: "memorychip",
                    value: "4.2 GB / 8.0 GB",
                    detail: "Used / Total",
                    progress: 0.52
                )
            }

            Group {
                Text("B: Compact Horizontal")
                    .font(DSTypography.caption)
                    .foregroundColor(.secondary)

                StatCardCandidateB(
                    title: "Memory",
                    icon: "memorychip",
                    value: "4.2 GB / 8.0 GB",
                    detail: "Used / Total",
                    progress: 0.52
                )
            }

            Group {
                Text("C: Minimal")
                    .font(DSTypography.caption)
                    .foregroundColor(.secondary)

                StatCardCandidateC(
                    title: "Memory",
                    icon: "memorychip",
                    value: "4.2 GB / 8.0 GB",
                    detail: "Used / Total",
                    progress: 0.52
                )
            }

            Group {
                Text("D: Termius Dark")
                    .font(DSTypography.caption)
                    .foregroundColor(.secondary)

                StatCardCandidateD(
                    title: "Memory",
                    icon: "memorychip",
                    value: "4.2 GB / 8.0 GB",
                    detail: "Used / Total",
                    progress: 0.52
                )
            }
        }
        .padding(DSSpacing.xl)
    }
    .frame(width: 400, height: 750)
}
