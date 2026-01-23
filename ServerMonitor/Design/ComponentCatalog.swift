//
//  ComponentCatalog.swift
//  ServerMonitor
//
//  A visual catalog of all UI components in the app.
//  Use Xcode Previews to browse components without running the app.
//

import SwiftUI

// MARK: - Status Indicator Component

/// A circular status indicator used throughout the app
struct DSStatusIndicator: View {
    enum Size {
        case small, medium, large

        var dimension: CGFloat {
            switch self {
            case .small: return DSDimension.statusDotSmall
            case .medium: return DSDimension.statusDotMedium
            case .large: return DSDimension.statusDotLarge
            }
        }
    }

    let status: ServerStatus
    var size: Size = .medium

    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: size.dimension, height: size.dimension)
    }

    private var statusColor: Color {
        switch status {
        case .online: return DSColor.online
        case .offline, .error: return DSColor.offline
        case .connecting: return DSColor.connecting
        case .unknown: return DSColor.unknown
        }
    }
}

// MARK: - Card Component

/// A standard card container used for stats and content blocks
struct DSCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(DSSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DSColor.cardBackground)
            .cornerRadius(DSRadius.md)
    }
}

// MARK: - Section Header Component

/// A consistent section header style
struct DSSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(DSTypography.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
}

// MARK: - Preview: Component Catalog

#Preview("Component Catalog") {
    ScrollView {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            // Status Indicators
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                DSSectionHeader(title: "Status Indicators")

                HStack(spacing: DSSpacing.lg) {
                    VStack(spacing: DSSpacing.xxs) {
                        DSStatusIndicator(status: .online, size: .large)
                        Text("Online").font(DSTypography.caption2)
                    }
                    VStack(spacing: DSSpacing.xxs) {
                        DSStatusIndicator(status: .offline, size: .large)
                        Text("Offline").font(DSTypography.caption2)
                    }
                    VStack(spacing: DSSpacing.xxs) {
                        DSStatusIndicator(status: .connecting, size: .large)
                        Text("Connecting").font(DSTypography.caption2)
                    }
                    VStack(spacing: DSSpacing.xxs) {
                        DSStatusIndicator(status: .unknown, size: .large)
                        Text("Unknown").font(DSTypography.caption2)
                    }
                }

                HStack(spacing: DSSpacing.md) {
                    HStack(spacing: DSSpacing.xxs) {
                        DSStatusIndicator(status: .online, size: .small)
                        Text("Small").font(DSTypography.caption)
                    }
                    HStack(spacing: DSSpacing.xxs) {
                        DSStatusIndicator(status: .online, size: .medium)
                        Text("Medium").font(DSTypography.caption)
                    }
                    HStack(spacing: DSSpacing.xxs) {
                        DSStatusIndicator(status: .online, size: .large)
                        Text("Large").font(DSTypography.caption)
                    }
                }
            }

            Divider()

            // Cards
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                DSSectionHeader(title: "Cards")

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        HStack {
                            Image(systemName: "cpu")
                                .font(DSTypography.title2)
                                .foregroundColor(.accentColor)
                            Text("CPU Load")
                                .font(DSTypography.headline)
                        }
                        Text("0.45 / 0.32 / 0.28")
                            .font(DSTypography.title)
                            .fontWeight(.semibold)
                        Text("1 min / 5 min / 15 min averages")
                            .font(DSTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        HStack {
                            Image(systemName: "memorychip")
                                .font(DSTypography.title2)
                                .foregroundColor(.accentColor)
                            Text("Memory")
                                .font(DSTypography.headline)
                        }
                        Text("4.2 GB / 8.0 GB")
                            .font(DSTypography.title)
                            .fontWeight(.semibold)
                        ProgressView(value: 0.52)
                            .tint(DSColor.progress(for: 0.52))
                        Text("Used / Total")
                            .font(DSTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Section Headers
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                DSSectionHeader(title: "Section Headers")

                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    DSSectionHeader(title: "Web Servers")
                    DSSectionHeader(title: "Databases")
                    DSSectionHeader(title: "Containers")
                }
            }

            Divider()

            // Buttons
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                DSSectionHeader(title: "Buttons")

                HStack(spacing: DSSpacing.md) {
                    Button("Primary") {}
                        .buttonStyle(.borderedProminent)

                    Button("Secondary") {}
                        .buttonStyle(.bordered)

                    Button("Plain") {}
                        .buttonStyle(.plain)

                    Button("Borderless") {}
                        .buttonStyle(.borderless)
                }

                HStack(spacing: DSSpacing.md) {
                    Button(role: .destructive) {
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {} label: {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Divider()

            // Form Fields
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                DSSectionHeader(title: "Form Fields")

                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text("Display Name")
                        .font(DSTypography.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g. Production Server", text: .constant(""))
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text("Host")
                        .font(DSTypography.caption)
                        .foregroundColor(.secondary)
                    TextField("IP address or hostname", text: .constant("192.168.1.100"))
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding(DSSpacing.xl)
    }
    .frame(width: 450, height: 800)
}

// MARK: - Preview: Empty States

#Preview("Empty States") {
    VStack(spacing: DSSpacing.xl) {
        // No servers
        VStack(spacing: DSSpacing.md) {
            Image(systemName: "server.rack")
                .font(.system(size: DSIconSize.xxl))
                .foregroundColor(.secondary)
            Text("No servers configured")
                .font(DSTypography.subheadline)
                .foregroundColor(.secondary)
            Text("Open Settings to add servers")
                .font(DSTypography.caption)
                .foregroundColor(.secondary)
            Button("Open Settings") {}
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DSSpacing.xxl)

        Divider()

        // Select a server
        ContentUnavailableView {
            Label("Select a Server", systemImage: "server.rack")
        } description: {
            Text("Choose a server from the sidebar to view details.")
        }
    }
    .padding(DSSpacing.xl)
    .frame(width: 400, height: 500)
}

// MARK: - Preview: Alerts & Feedback

#Preview("Alerts & Feedback") {
    VStack(spacing: DSSpacing.lg) {
        // Success message
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(DSColor.success)
            Text("Success! Connected to server.")
                .font(DSTypography.callout)
            Spacer()
        }
        .padding(DSSpacing.md)
        .background(DSColor.success.opacity(0.1))
        .cornerRadius(DSRadius.md)

        // Error message
        HStack {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(DSColor.error)
            Text("Connection failed: Host unreachable")
                .font(DSTypography.callout)
            Spacer()
        }
        .padding(DSSpacing.md)
        .background(DSColor.error.opacity(0.1))
        .cornerRadius(DSRadius.md)

        // Warning message
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DSColor.warning)
            Text("Sign in to iCloud to sync")
                .font(DSTypography.callout)
            Spacer()
        }
        .padding(DSSpacing.md)
        .background(DSColor.warning.opacity(0.1))
        .cornerRadius(DSRadius.md)

        // Info message
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(DSColor.info)
            Text("Your data syncs automatically")
                .font(DSTypography.callout)
            Spacer()
        }
        .padding(DSSpacing.md)
        .background(DSColor.info.opacity(0.1))
        .cornerRadius(DSRadius.md)
    }
    .padding(DSSpacing.xl)
    .frame(width: 400)
}
