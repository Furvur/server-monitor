//
//  AgentInstallView.swift
//  ServerMonitor
//
//  Sheet view for agent installation progress

import SwiftUI

struct AgentInstallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var monitorService: MonitorService
    let server: Server

    @State private var currentStep: AgentService.InstallationStep = .detecting
    @State private var progressLog: [String] = []
    @State private var isInstalling = false
    @State private var installationComplete = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            // Header
            headerSection

            Divider()
                .background(DSDarkTheme.divider)

            // Progress indicator
            progressSection

            // Log output
            logSection

            // Error message
            if let error = error {
                errorSection(error)
            }

            Spacer()

            // Actions
            actionButtons
        }
        .padding(DSSpacing.lg)
        .frame(width: 500, height: 450)
        .background(DSDarkTheme.background)
        .preferredColorScheme(.dark)
        .onAppear {
            startInstallation()
        }
    }

    // MARK: - Sections

    private var isUpdate: Bool {
        server.agentStatus == .outdated || server.agentStatus == .error || server.agentStatus == .installed
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(isUpdate ? "Update Agent" : "Install Agent")
                    .font(DSTypography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DSDarkTheme.textPrimary)

                Text("\(isUpdate ? "Updating" : "Installing") on \(server.name)")
                    .font(DSTypography.caption)
                    .foregroundColor(DSDarkTheme.textSecondary)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(DSDarkTheme.textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(isInstalling && !installationComplete && error == nil)
        }
    }

    private var progressSection: some View {
        VStack(spacing: DSSpacing.md) {
            // Step indicator
            HStack(spacing: DSSpacing.sm) {
                ForEach(installationSteps, id: \.self) { step in
                    StepIndicator(
                        step: step,
                        currentStep: currentStep,
                        isComplete: installationComplete,
                        hasError: error != nil
                    )

                    if step != installationSteps.last {
                        Rectangle()
                            .fill(stepConnectorColor(for: step))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal, DSSpacing.md)

            // Current step description
            Text(currentStep.rawValue)
                .font(DSTypography.subheadline)
                .foregroundColor(error != nil ? DSDarkTheme.offline : DSDarkTheme.textPrimary)
        }
    }

    private var logSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    ForEach(Array(progressLog.enumerated()), id: \.offset) { index, line in
                        HStack(alignment: .top, spacing: DSSpacing.xs) {
                            Text("→")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(DSDarkTheme.textTertiary)
                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(DSDarkTheme.textSecondary)
                        }
                        .id(index)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DSSpacing.sm)
            }
            .onChange(of: progressLog.count) { _, _ in
                if let lastIndex = progressLog.indices.last {
                    withAnimation {
                        proxy.scrollTo(lastIndex, anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxHeight: 180)
        .background(DSDarkTheme.surface)
        .cornerRadius(DSRadius.md)
    }

    private func errorSection(_ errorMessage: String) -> some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DSDarkTheme.offline)
            Text(errorMessage)
                .font(DSTypography.caption)
                .foregroundColor(DSDarkTheme.offline)
        }
        .padding(DSSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSDarkTheme.offline.opacity(0.1))
        .cornerRadius(DSRadius.sm)
    }

    private var actionButtons: some View {
        HStack(spacing: DSSpacing.md) {
            if installationComplete {
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(DSDarkTheme.online)
            } else if error != nil {
                Button("Retry") {
                    error = nil
                    progressLog = []
                    startInstallation()
                }
                .buttonStyle(.bordered)

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            } else {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .disabled(isInstalling)
            }
        }
    }

    // MARK: - Helpers

    private var installationSteps: [AgentService.InstallationStep] {
        [.detecting, .uploading, .configuring, .starting, .verifying]
    }

    private func stepConnectorColor(for step: AgentService.InstallationStep) -> Color {
        let stepIndex = installationSteps.firstIndex(of: step) ?? 0
        let currentIndex = installationSteps.firstIndex(of: currentStep) ?? 0

        if installationComplete {
            return DSDarkTheme.online
        } else if stepIndex < currentIndex {
            return DSDarkTheme.online
        } else {
            return DSDarkTheme.surfaceActive
        }
    }

    // MARK: - Installation

    private func startInstallation() {
        isInstalling = true
        progressLog.append("Starting installation...")

        Task {
            do {
                try await monitorService.installAgent(on: server) { step, message in
                    Task { @MainActor in
                        self.currentStep = step
                        self.progressLog.append(message)
                    }
                }

                await MainActor.run {
                    installationComplete = true
                    currentStep = .complete
                    progressLog.append("Installation complete!")
                    isInstalling = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.currentStep = .failed
                    self.progressLog.append("Error: \(error.localizedDescription)")
                    self.isInstalling = false
                }
            }
        }
    }
}

// MARK: - Step Indicator

private struct StepIndicator: View {
    let step: AgentService.InstallationStep
    let currentStep: AgentService.InstallationStep
    let isComplete: Bool
    let hasError: Bool

    private var isCurrent: Bool {
        step == currentStep
    }

    private var isPast: Bool {
        let steps: [AgentService.InstallationStep] = [.detecting, .uploading, .configuring, .starting, .verifying]
        guard let stepIndex = steps.firstIndex(of: step),
              let currentIndex = steps.firstIndex(of: currentStep) else {
            return false
        }
        return stepIndex < currentIndex
    }

    private var iconName: String {
        switch step {
        case .detecting: return "cpu"
        case .uploading: return "arrow.up.circle"
        case .configuring: return "gearshape"
        case .starting: return "play.circle"
        case .verifying: return "checkmark.seal"
        case .complete: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 32, height: 32)

            if isCurrent && !isComplete && !hasError {
                ProgressView()
                    .scaleEffect(0.6)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
            }
        }
    }

    private var backgroundColor: Color {
        if hasError && isCurrent {
            return DSDarkTheme.offline
        } else if isComplete || isPast {
            return DSDarkTheme.online
        } else if isCurrent {
            return DSDarkTheme.info
        } else {
            return DSDarkTheme.surfaceActive
        }
    }

    private var iconColor: Color {
        if isComplete || isPast || isCurrent {
            return .white
        } else {
            return DSDarkTheme.textTertiary
        }
    }
}
