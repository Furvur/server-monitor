//
//  DesignSystem.swift
//  ServerMonitor
//
//  Design tokens and constants for consistent styling across the app.
//  This file defines the visual language of the application.
//

import SwiftUI

// MARK: - Colors

enum DSColor {
    // Status colors
    static let online = Color.green
    static let offline = Color.red
    static let warning = Color.orange
    static let connecting = Color.yellow
    static let unknown = Color.gray

    // Semantic colors
    static let success = Color.green
    static let error = Color.red
    static let info = Color.blue

    // Background colors
    static let cardBackground = Color(nsColor: .controlBackgroundColor)
    static let cardBackgroundSubtle = Color(nsColor: .controlBackgroundColor).opacity(0.5)

    // Progress colors
    static func progress(for value: Double) -> Color {
        if value > 0.9 { return .red }
        if value > 0.7 { return .orange }
        return .green
    }
}

// MARK: - Termius-Inspired Dark Theme

/// Dark theme palette inspired by Termius
/// Use these for a more modern, dark-first aesthetic
enum DSDarkTheme {
    // Base backgrounds (darkest to lightest)
    static let background = Color(white: 0.06)      // Main app background
    static let surface = Color(white: 0.08)         // Cards, panels
    static let surfaceHover = Color(white: 0.10)    // Hover states
    static let surfaceActive = Color(white: 0.12)   // Active/selected states
    static let elevated = Color(white: 0.14)        // Elevated components

    // Borders and dividers
    static let border = Color.white.opacity(0.08)
    static let borderSubtle = Color.white.opacity(0.05)
    static let divider = Color.white.opacity(0.1)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    static let textMuted = Color.white.opacity(0.3)

    // Status colors (slightly adjusted for dark backgrounds)
    static let online = Color(red: 0.3, green: 0.85, blue: 0.4)
    static let offline = Color(red: 0.95, green: 0.3, blue: 0.3)
    static let warning = Color(red: 1.0, green: 0.7, blue: 0.2)
    static let info = Color(red: 0.3, green: 0.6, blue: 1.0)

    // Accent gradients (for avatars, buttons)
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.4, green: 0.5, blue: 1.0), Color(red: 0.7, green: 0.4, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.3, green: 0.7, blue: 0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Interactive states
    static let hoverOverlay = Color.white.opacity(0.05)
    static let pressedOverlay = Color.white.opacity(0.08)
    static let selectedOverlay = Color.accentColor.opacity(0.2)
}

// MARK: - Dark Theme View Modifier

struct DarkThemeBackground: ViewModifier {
    var level: DarkBackgroundLevel = .base

    enum DarkBackgroundLevel {
        case base, surface, elevated

        var color: Color {
            switch self {
            case .base: return DSDarkTheme.background
            case .surface: return DSDarkTheme.surface
            case .elevated: return DSDarkTheme.elevated
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .background(level.color)
            .preferredColorScheme(.dark)
    }
}

extension View {
    func darkThemeBackground(_ level: DarkThemeBackground.DarkBackgroundLevel = .base) -> some View {
        modifier(DarkThemeBackground(level: level))
    }
}

// MARK: - Typography

enum DSTypography {
    // Font styles as ViewModifiers for consistency
    static let largeTitle = Font.largeTitle
    static let title = Font.title
    static let title2 = Font.title2
    static let title3 = Font.title3
    static let headline = Font.headline
    static let subheadline = Font.subheadline
    static let body = Font.body
    static let callout = Font.callout
    static let caption = Font.caption
    static let caption2 = Font.caption2
}

// MARK: - Spacing

enum DSSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 6
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 40
}

// MARK: - Corner Radius

enum DSRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
}

// MARK: - Icon Sizes

enum DSIconSize {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 10
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 40
}

// MARK: - Component Dimensions

enum DSDimension {
    // Status indicators
    static let statusDotSmall: CGFloat = 8
    static let statusDotMedium: CGFloat = 10
    static let statusDotLarge: CGFloat = 12

    // Icon frames
    static let iconFrameSmall: CGFloat = 16
    static let iconFrameMedium: CGFloat = 24

    // Windows
    static let menuBarWidth: CGFloat = 320
    static let menuBarMaxHeight: CGFloat = 300
    static let settingsWidth: CGFloat = 500
    static let settingsHeight: CGFloat = 450
    static let mainWindowMinWidth: CGFloat = 600
    static let mainWindowMinHeight: CGFloat = 400
    static let sidebarMinWidth: CGFloat = 200
    static let formSheetWidth: CGFloat = 450
    static let formSheetHeight: CGFloat = 500
}

// MARK: - Shadows

enum DSShadow {
    static let subtle = Color.black.opacity(0.1)
    static let medium = Color.black.opacity(0.2)
}

// MARK: - Preview

#Preview("Design Tokens") {
    ScrollView {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            // Colors
            Section {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Colors")
                        .font(DSTypography.headline)

                    HStack(spacing: DSSpacing.md) {
                        colorSwatch("Online", DSColor.online)
                        colorSwatch("Offline", DSColor.offline)
                        colorSwatch("Warning", DSColor.warning)
                        colorSwatch("Connecting", DSColor.connecting)
                        colorSwatch("Unknown", DSColor.unknown)
                    }
                }
            }

            // Typography
            Section {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Typography")
                        .font(DSTypography.headline)

                    Text("Large Title").font(DSTypography.largeTitle)
                    Text("Title").font(DSTypography.title)
                    Text("Title 2").font(DSTypography.title2)
                    Text("Headline").font(DSTypography.headline)
                    Text("Subheadline").font(DSTypography.subheadline)
                    Text("Body").font(DSTypography.body)
                    Text("Caption").font(DSTypography.caption)
                    Text("Caption 2").font(DSTypography.caption2)
                }
            }

            // Spacing
            Section {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Spacing")
                        .font(DSTypography.headline)

                    HStack(spacing: DSSpacing.md) {
                        spacingSwatch("xxs", DSSpacing.xxs)
                        spacingSwatch("xs", DSSpacing.xs)
                        spacingSwatch("sm", DSSpacing.sm)
                        spacingSwatch("md", DSSpacing.md)
                        spacingSwatch("lg", DSSpacing.lg)
                        spacingSwatch("xl", DSSpacing.xl)
                    }
                }
            }

            // Radius
            Section {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Corner Radius")
                        .font(DSTypography.headline)

                    HStack(spacing: DSSpacing.md) {
                        radiusSwatch("sm", DSRadius.sm)
                        radiusSwatch("md", DSRadius.md)
                        radiusSwatch("lg", DSRadius.lg)
                    }
                }
            }
        }
        .padding(DSSpacing.xl)
    }
    .frame(width: 500, height: 600)
}

// MARK: - Preview Helpers

private func colorSwatch(_ name: String, _ color: Color) -> some View {
    VStack(spacing: DSSpacing.xxs) {
        Circle()
            .fill(color)
            .frame(width: 32, height: 32)
        Text(name)
            .font(DSTypography.caption2)
    }
}

private func spacingSwatch(_ name: String, _ size: CGFloat) -> some View {
    VStack(spacing: DSSpacing.xxs) {
        Rectangle()
            .fill(Color.accentColor)
            .frame(width: size, height: 24)
        Text(name)
            .font(DSTypography.caption2)
    }
}

private func radiusSwatch(_ name: String, _ radius: CGFloat) -> some View {
    VStack(spacing: DSSpacing.xxs) {
        RoundedRectangle(cornerRadius: radius)
            .fill(DSColor.cardBackground)
            .stroke(Color.accentColor, lineWidth: 2)
            .frame(width: 48, height: 32)
        Text(name)
            .font(DSTypography.caption2)
    }
}
