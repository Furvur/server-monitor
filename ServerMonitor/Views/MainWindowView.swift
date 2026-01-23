//
//  MainWindowView.swift
//  ServerMonitor
//

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var monitorService: MonitorService
    @State private var selectedServer: Server?
    @State private var showingAddServer = false
    @State private var serverToEdit: Server?
    @State private var serverToDelete: Server?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(DSDarkTheme.background)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddServer = true }) {
                    Image(systemName: "plus")
                }
                .help("Add Server (⌘N)")
                .keyboardShortcut("n", modifiers: .command)
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    Task {
                        await monitorService.refreshAllServers()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh all servers (⌘R)")
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }) {
                    Image(systemName: "gear")
                }
                .help("Settings (⌘,)")
            }
        }
        .sheet(isPresented: $showingAddServer) {
            ServerFormView(mode: .add) { newServer in
                monitorService.addServer(newServer)
                selectedServer = newServer
                Task {
                    await monitorService.refreshServer(newServer)
                }
            }
        }
        .sheet(item: $serverToEdit) { server in
            ServerFormView(mode: .edit(server)) { updatedServer in
                monitorService.updateServer(updatedServer)
                if selectedServer?.id == updatedServer.id {
                    selectedServer = updatedServer
                }
            }
        }
        .alert("Delete Server", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                serverToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let server = serverToDelete {
                    if selectedServer?.id == server.id {
                        selectedServer = nil
                    }
                    monitorService.deleteServer(server)
                }
                serverToDelete = nil
            }
        } message: {
            if let server = serverToDelete {
                Text("Are you sure you want to delete \"\(server.name)\"?")
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            // Search placeholder
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DSDarkTheme.textTertiary)
                    .font(.system(size: 13))
                Text("Search servers...")
                    .font(DSTypography.subheadline)
                    .foregroundColor(DSDarkTheme.textTertiary)
                Spacer()
            }
            .padding(DSSpacing.sm)
            .background(DSDarkTheme.surfaceHover)
            .cornerRadius(DSRadius.sm)
            .padding(DSSpacing.md)

            Divider().background(DSDarkTheme.divider)

            // Server list
            ScrollView {
                LazyVStack(spacing: DSSpacing.sm) {
                    ForEach(monitorService.servers) { server in
                        ServerSidebarRow(
                            server: server,
                            stats: monitorService.stats[server.id],
                            isSelected: selectedServer?.id == server.id
                        )
                        .tag(server)
                        .onTapGesture {
                            selectedServer = server
                        }
                        .contextMenu {
                            Button {
                                serverToEdit = server
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button {
                                Task {
                                    await monitorService.refreshServer(server)
                                }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }

                            Divider()

                            Button(role: .destructive) {
                                serverToDelete = server
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(DSSpacing.md)
            }

            Divider().background(DSDarkTheme.divider)

            // Bottom toolbar
            HStack {
                Button(action: { showingAddServer = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .foregroundColor(DSDarkTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Add Server")

                Spacer()

                Button(action: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundColor(DSDarkTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .padding(DSSpacing.md)
        }
        .frame(minWidth: 280)
        .background(DSDarkTheme.surface)
        .navigationTitle("Servers")
    }

    @ViewBuilder
    private var detailView: some View {
        if let server = selectedServer,
           let stats = monitorService.stats[server.id] {
            ServerDetailView(server: server, stats: stats, historyService: monitorService.historyService)
        } else if monitorService.servers.isEmpty {
            ContentUnavailableView {
                Label("No Servers", systemImage: "server.rack")
            } description: {
                Text("Add a server to start monitoring.")
            } actions: {
                Button("Add Server") {
                    showingAddServer = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            ContentUnavailableView {
                Label("Select a Server", systemImage: "server.rack")
            } description: {
                Text("Choose a server from the sidebar to view details.")
            }
        }
    }
}

// MARK: - Server Form View (Add/Edit)

enum ServerFormMode {
    case add
    case edit(Server)

    var title: String {
        switch self {
        case .add: return "Add Server"
        case .edit: return "Edit Server"
        }
    }

    var buttonTitle: String {
        switch self {
        case .add: return "Add Server"
        case .edit: return "Save Changes"
        }
    }
}

struct ServerFormView: View {
    @Environment(\.dismiss) var dismiss
    let mode: ServerFormMode
    let onSave: (Server) -> Void

    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = "22"
    @State private var username: String = ""
    @State private var selectedKeyPath: String = ""
    @State private var enabledServices: Set<UUID> = []
    @State private var testResult: String?
    @State private var isTesting: Bool = false
    @State private var isDetectingServices: Bool = false
    @State private var selectedTab = 0

    private var existingServer: Server? {
        if case .edit(let server) = mode {
            return server
        }
        return nil
    }

    init(mode: ServerFormMode, onSave: @escaping (Server) -> Void) {
        self.mode = mode
        self.onSave = onSave

        if case .edit(let server) = mode {
            _name = State(initialValue: server.name)
            _host = State(initialValue: server.host)
            _port = State(initialValue: String(server.port))
            _username = State(initialValue: server.username)
            _selectedKeyPath = State(initialValue: server.sshKeyPath ?? "")
            _enabledServices = State(initialValue: Set(server.enabledServices))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(mode.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()

            // Tab picker
            Picker("", selection: $selectedTab) {
                Text("Connection").tag(0)
                Text("Services").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Tab content
            if selectedTab == 0 {
                connectionTab
            } else {
                servicesTab
            }

            Divider()

            // Actions
            HStack {
                Button("Test Connection") {
                    testConnection()
                }
                .disabled(isTesting || !isValid)

                if isTesting {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button(mode.buttonTitle) {
                    save()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 450, height: 500)
    }

    // MARK: - Connection Tab

    private var connectionTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Display Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g. Production Server", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Host")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("IP address or hostname", text: $host)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Username")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("e.g. root", text: $username)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Port")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("22", text: $port)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("SSH Key")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $selectedKeyPath) {
                        Text("Default (ssh-agent)").tag("")
                        ForEach(availableSSHKeys, id: \.self) { keyPath in
                            Text(keyPath.replacingOccurrences(of: sshDirectory + "/", with: ""))
                                .tag(keyPath)
                        }
                    }
                    .labelsHidden()
                }

                // Test result
                if let result = testResult {
                    HStack {
                        Image(systemName: result.contains("Success") ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.contains("Success") ? .green : .red)
                        Text(result)
                            .font(.callout)
                        Spacer()
                    }
                    .padding(10)
                    .background(result.contains("Success") ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    // MARK: - Services Tab

    private var servicesTab: some View {
        VStack(spacing: 0) {
            // Auto-detect button
            HStack {
                Button {
                    autoDetectServices()
                } label: {
                    HStack {
                        if isDetectingServices {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "sparkle.magnifyingglass")
                        }
                        Text("Auto-detect Services")
                    }
                }
                .disabled(isDetectingServices || !isValid)

                Spacer()

                Text("\(enabledServices.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            // Services list by category
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(ServiceCategory.allCases, id: \.self) { category in
                        let services = BuiltInServices.byCategory[category] ?? []
                        if !services.isEmpty {
                            ServiceCategorySection(
                                category: category,
                                services: services,
                                enabledServices: $enabledServices
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var sshDirectory: String {
        NSHomeDirectory() + "/.ssh"
    }

    private var availableSSHKeys: [String] {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(atPath: sshDirectory) else {
            return []
        }

        // Files to exclude (not private keys)
        let excludedFiles: Set<String> = ["known_hosts", "known_hosts.old", "config", "authorized_keys", "environment"]
        let excludedPrefixes = ["agent.", "known_hosts"]
        let excludedSuffixes = [".pub", ".old", ".bak"]

        return files
            .filter { fileName in
                // Skip hidden files
                guard !fileName.hasPrefix(".") else { return false }
                // Skip known non-key files
                guard !excludedFiles.contains(fileName) else { return false }
                // Skip files with excluded prefixes
                guard !excludedPrefixes.contains(where: { fileName.hasPrefix($0) }) else { return false }
                // Skip files with excluded suffixes
                guard !excludedSuffixes.contains(where: { fileName.hasSuffix($0) }) else { return false }
                return true
            }
            .map { sshDirectory + "/" + $0 }
            .filter { path in
                // Verify it's a file, not a directory
                var isDir: ObjCBool = false
                guard fileManager.fileExists(atPath: path, isDirectory: &isDir) && !isDir.boolValue else {
                    return false
                }
                // Check if file looks like a private key (starts with -----)
                if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                    return content.hasPrefix("-----BEGIN")
                }
                return false
            }
            .sorted()
    }

    private var isValid: Bool {
        !name.isEmpty && !host.isEmpty && !username.isEmpty && Int(port) != nil
    }

    private func save() {
        let server = Server(
            id: existingServer?.id ?? UUID(),
            name: name,
            host: host,
            port: Int(port) ?? 22,
            username: username,
            sshKeyPath: selectedKeyPath.isEmpty ? nil : selectedKeyPath,
            enabledServices: Array(enabledServices),
            isEnabled: existingServer?.isEnabled ?? true
        )
        onSave(server)
        dismiss()
    }

    private func testConnection() {
        isTesting = true
        testResult = nil

        let server = Server(
            name: name,
            host: host,
            port: Int(port) ?? 22,
            username: username,
            sshKeyPath: selectedKeyPath.isEmpty ? nil : selectedKeyPath
        )

        Task {
            let sshService = SSHService()
            let stats = await sshService.fetchStats(for: server)

            await MainActor.run {
                isTesting = false
                if stats.status == .online {
                    testResult = "Success! Connected to server."
                } else if let errorMessage = stats.errorMessage {
                    testResult = errorMessage
                } else {
                    testResult = "Failed: \(stats.status.rawValue)"
                }
            }
        }
    }

    private func autoDetectServices() {
        isDetectingServices = true

        let server = Server(
            name: name,
            host: host,
            port: Int(port) ?? 22,
            username: username,
            sshKeyPath: selectedKeyPath.isEmpty ? nil : selectedKeyPath
        )

        Task {
            let sshService = SSHService()
            let detectedIds = await sshService.detectServices(for: server)

            await MainActor.run {
                isDetectingServices = false
                for id in detectedIds {
                    enabledServices.insert(id)
                }
            }
        }
    }
}

// MARK: - Service Category Section

struct ServiceCategorySection: View {
    let category: ServiceCategory
    let services: [ServiceDefinition]
    @Binding var enabledServices: Set<UUID>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 4) {
                ForEach(services) { service in
                    ServiceToggleRow(
                        service: service,
                        isEnabled: enabledServices.contains(service.id),
                        onToggle: { enabled in
                            if enabled {
                                enabledServices.insert(service.id)
                            } else {
                                enabledServices.remove(service.id)
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Service Toggle Row

struct ServiceToggleRow: View {
    let service: ServiceDefinition
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack {
            Text(service.name)
                .font(.subheadline)

            Spacer()

            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isEnabled ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
}

// MARK: - Server Sidebar Row (Termius Card Style)

struct ServerSidebarRow: View {
    let server: Server
    let stats: ServerStats?
    var isSelected: Bool = false

    private var isOnline: Bool {
        stats?.status == .online
    }

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Server icon with status ring
            ZStack {
                Circle()
                    .fill(DSDarkTheme.surfaceActive)
                    .frame(width: 36, height: 36)

                Image(systemName: "server.rack")
                    .font(.system(size: 14))
                    .foregroundColor(DSDarkTheme.textPrimary)

                Circle()
                    .stroke(isOnline ? DSDarkTheme.online : DSDarkTheme.offline, lineWidth: 2)
                    .frame(width: 36, height: 36)
            }

            // Server info
            VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                Text(server.name)
                    .font(DSTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DSDarkTheme.textPrimary)

                Text("\(server.username)@\(server.host)")
                    .font(DSTypography.caption)
                    .foregroundColor(DSDarkTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Status badge
            if let stats = stats {
                Text(stats.status.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isOnline ? DSDarkTheme.online : DSDarkTheme.offline)
                    .padding(.horizontal, DSSpacing.sm)
                    .padding(.vertical, DSSpacing.xxs)
                    .background((isOnline ? DSDarkTheme.online : DSDarkTheme.offline).opacity(0.15))
                    .cornerRadius(DSRadius.sm)
            }
        }
        .padding(DSSpacing.sm)
        .background(isSelected ? DSDarkTheme.surfaceActive : DSDarkTheme.surface)
        .cornerRadius(DSRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Server Detail View

enum DetailTab: String, CaseIterable {
    case overview = "Overview"
    case charts = "Charts"
}

struct ServerDetailView: View {
    let server: Server
    let stats: ServerStats
    let historyService: HistoryService
    @State private var selectedTab: DetailTab = .overview

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .frame(width: 200)

            // Tab content
            switch selectedTab {
            case .overview:
                overviewContent
            case .charts:
                ServerChartsView(server: server, historyService: historyService)
            }
        }
        .navigationTitle(server.name)
    }

    private var overviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                headerSection
                if stats.status == .online {
                    statsSection
                    if !server.enabledServices.isEmpty {
                        servicesSection
                    }
                } else {
                    statusSection
                }
                Spacer()
            }
            .padding(DSSpacing.lg)
        }
        .background(DSDarkTheme.background)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            // Top row: Name, connection info, and actions
            HStack(spacing: DSSpacing.md) {
                VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                    Text(server.name)
                        .font(DSTypography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(DSDarkTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: DSSpacing.xs) {
                        Text("\(server.username)@\(server.host)")
                            .font(DSTypography.caption)
                            .foregroundColor(DSDarkTheme.textSecondary)

                        if server.port != 22 {
                            Text(":\(server.port)")
                                .font(DSTypography.caption)
                                .foregroundColor(DSDarkTheme.textTertiary)
                        }
                    }
                    .lineLimit(1)
                }

                Spacer(minLength: DSSpacing.sm)

                // Uptime badge (if online)
                if let uptime = stats.uptime {
                    HStack(spacing: DSSpacing.xxs) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 10))
                        Text(uptime.displayString)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(DSDarkTheme.textSecondary)
                    .padding(.horizontal, DSSpacing.sm)
                    .padding(.vertical, DSSpacing.xxs)
                    .background(DSDarkTheme.surfaceHover)
                    .cornerRadius(DSRadius.sm)
                }

                // Quick action button
                Button {
                    // Terminal action placeholder
                } label: {
                    HStack(spacing: DSSpacing.xs) {
                        Image(systemName: "terminal")
                            .font(.system(size: 12))
                        Text("Terminal")
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

            // System info row
            if let sysInfo = stats.systemInfo {
                HStack(spacing: DSSpacing.md) {
                    // OS badge
                    InfoBadge(icon: "desktopcomputer", text: sysInfo.displayOS)

                    // Kernel badge
                    if !sysInfo.kernelVersion.isEmpty {
                        InfoBadge(icon: "gearshape.2", text: sysInfo.shortKernel)
                    }

                    // Architecture badge
                    if !sysInfo.architecture.isEmpty {
                        InfoBadge(icon: "cpu", text: sysInfo.architecture)
                    }
                }
            }

            // Status row: badges that can wrap
            FlowLayout(spacing: DSSpacing.sm) {
                // Status badge
                HStack(spacing: DSSpacing.xxs) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(stats.status.rawValue)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(statusColor)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xxs)
                .background(statusColor.opacity(0.15))
                .cornerRadius(DSRadius.sm)

                Text("Updated: \(stats.lastUpdated.formatted(.relative(presentation: .named)))")
                    .font(DSTypography.caption)
                    .foregroundColor(DSDarkTheme.textTertiary)
                    .padding(.vertical, DSSpacing.xxs)
            }
        }
        .padding(DSSpacing.md)
        .background(DSDarkTheme.surface)
        .cornerRadius(DSRadius.lg)
    }

    // Helper view for system info badges
    private struct InfoBadge: View {
        let icon: String
        let text: String

        var body: some View {
            HStack(spacing: DSSpacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(text)
                    .font(.system(size: 11))
            }
            .foregroundColor(DSDarkTheme.textTertiary)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: stats.status == .offline ? "wifi.slash" : "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Server is \(stats.status.rawValue.lowercased())")
                    .font(.headline)
            }

            if let errorMessage = stats.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    private var statsSection: some View {
        VStack(spacing: DSSpacing.md) {
            // Threshold warnings
            if let memory = stats.memory, memory.usagePercent >= 80 {
                ThresholdWarning(
                    title: memory.usagePercent >= 90 ? "Critical Memory Usage" : "High Memory Usage",
                    message: "Memory is at \(Int(memory.usagePercent))%. Consider freeing up memory.",
                    severity: memory.usagePercent >= 90 ? .critical : .warning
                )
            }

            if let disk = stats.disk, disk.usagePercent >= 80 {
                ThresholdWarning(
                    title: disk.usagePercent >= 90 ? "Critical Disk Usage" : "High Disk Usage",
                    message: "Disk is at \(Int(disk.usagePercent))%. Consider cleaning up files.",
                    severity: disk.usagePercent >= 90 ? .critical : .warning
                )
            }

            if let swap = stats.swap, swap.isActive && swap.usagePercent >= 50 {
                ThresholdWarning(
                    title: "Swap In Use",
                    message: "System is using swap (\(Int(swap.usagePercent))%). This may indicate memory pressure.",
                    severity: swap.usagePercent >= 80 ? .warning : .info
                )
            }

            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpacing.md) {
                // CPU Load
                if let cpu = stats.cpuLoad {
                    CompactStatCard(
                        title: "CPU Load",
                        icon: "cpu",
                        value: String(format: "%.2f", cpu.load1),
                        detail: String(format: "%.2f / %.2f", cpu.load5, cpu.load15)
                    )
                }

                // Memory
                if let memory = stats.memory {
                    CompactStatCard(
                        title: "Memory",
                        icon: "memorychip",
                        value: String(format: "%.0f%%", memory.usagePercent),
                        detail: memory.displayString,
                        progress: memory.usagePercent / 100
                    )
                }

                // Disk
                if let disk = stats.disk {
                    CompactStatCard(
                        title: "Disk",
                        icon: "internaldrive",
                        value: String(format: "%.0f%%", disk.usagePercent),
                        detail: disk.displayString,
                        progress: disk.usagePercent / 100
                    )
                }

                // Swap
                if let swap = stats.swap, swap.totalMB > 0 {
                    CompactStatCard(
                        title: "Swap",
                        icon: "arrow.left.arrow.right",
                        value: swap.isActive ? String(format: "%.0f%%", swap.usagePercent) : "Idle",
                        detail: swap.displayString,
                        progress: swap.usagePercent / 100
                    )
                }

                // Network In
                if let network = stats.network {
                    CompactStatCard(
                        title: "Net In",
                        icon: "arrow.down.circle",
                        value: network.displayBytesIn,
                        detail: "Total received"
                    )
                }

                // Network Out
                if let network = stats.network {
                    CompactStatCard(
                        title: "Net Out",
                        icon: "arrow.up.circle",
                        value: network.displayBytesOut,
                        detail: "Total sent"
                    )
                }
            }
        }
    }

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Services")
                .font(.headline)

            ForEach(server.enabledServices, id: \.self) { serviceId in
                if let service = BuiltInServices.service(withId: serviceId) {
                    ServiceStatusCard(
                        service: service,
                        status: stats.services[serviceId]
                    )
                }
            }
        }
    }

    private var statusColor: Color {
        switch stats.status {
        case .online: return .green
        case .offline, .error: return .red
        case .connecting: return .yellow
        case .unknown: return .gray
        }
    }
}

// MARK: - Service Status Card

struct ServiceStatusCard: View {
    let service: ServiceDefinition
    let status: ServiceStatus?
    @State private var isExpanded = false
    @State private var showingActions = false

    private var isRunning: Bool {
        status?.isRunning ?? false
    }

    private var hasContainers: Bool {
        status?.containers != nil && !(status?.containers?.isEmpty ?? true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main service row
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: service.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isRunning ? DSDarkTheme.online : DSDarkTheme.textTertiary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: DSSpacing.sm) {
                        Text(service.name)
                            .font(DSTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DSDarkTheme.textPrimary)

                        // Service uptime
                        if let uptimeStr = status?.uptimeDisplay {
                            Text("• \(uptimeStr)")
                                .font(DSTypography.caption)
                                .foregroundColor(DSDarkTheme.textTertiary)
                        }
                    }

                    if let details = status?.details {
                        Text(details)
                            .font(DSTypography.caption)
                            .foregroundColor(DSDarkTheme.textSecondary)
                    }
                }

                Spacer()

                // Status badge
                HStack(spacing: DSSpacing.xxs) {
                    Circle()
                        .fill(isRunning ? DSDarkTheme.online : DSDarkTheme.offline)
                        .frame(width: 6, height: 6)
                    Text(isRunning ? "Running" : "Stopped")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(isRunning ? DSDarkTheme.online : DSDarkTheme.offline)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xxs)
                .background((isRunning ? DSDarkTheme.online : DSDarkTheme.offline).opacity(0.15))
                .cornerRadius(DSRadius.sm)

                // Actions menu
                Menu {
                    Button {
                        // Restart action placeholder
                    } label: {
                        Label("Restart", systemImage: "arrow.clockwise")
                    }

                    Button {
                        // View logs action placeholder
                    } label: {
                        Label("View Logs", systemImage: "doc.text")
                    }

                    if !isRunning {
                        Button {
                            // Start action placeholder
                        } label: {
                            Label("Start", systemImage: "play.fill")
                        }
                    } else {
                        Button(role: .destructive) {
                            // Stop action placeholder
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                        .foregroundColor(DSDarkTheme.textTertiary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24)

                // Expand button for Docker containers
                if hasContainers {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(DSDarkTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DSSpacing.sm)

            // Docker containers list (expandable)
            if hasContainers && isExpanded {
                Divider().background(DSDarkTheme.divider)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(status?.containers ?? []) { container in
                        ContainerRow(container: container)
                        if container.id != status?.containers?.last?.id {
                            Divider()
                                .background(DSDarkTheme.divider)
                                .padding(.leading, 36)
                        }
                    }
                }
            }
        }
        .background(DSDarkTheme.surface)
        .cornerRadius(DSRadius.md)
    }
}

// MARK: - Container Row

struct ContainerRow: View {
    let container: DockerContainer

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: container.state.icon)
                .font(.system(size: 12))
                .foregroundColor(stateColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(container.name)
                    .font(DSTypography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DSDarkTheme.textPrimary)

                Text(container.displayImage)
                    .font(.system(size: 10))
                    .foregroundColor(DSDarkTheme.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                // State badge
                Text(container.state.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(stateColor)
                    .padding(.horizontal, DSSpacing.xs)
                    .padding(.vertical, 2)
                    .background(stateColor.opacity(0.15))
                    .cornerRadius(DSRadius.sm)

                Text(container.status)
                    .font(.system(size: 10))
                    .foregroundColor(DSDarkTheme.textTertiary)
            }
        }
        .padding(.horizontal, DSSpacing.sm)
        .padding(.vertical, DSSpacing.xs)
        .background(DSDarkTheme.surfaceHover.opacity(0.5))
    }

    private var stateColor: Color {
        switch container.state {
        case .running: return DSDarkTheme.online
        case .exited: return DSDarkTheme.textTertiary
        case .paused: return .yellow
        case .restarting: return .orange
        case .dead, .removing: return DSDarkTheme.offline
        case .created: return .blue
        }
    }
}

// MARK: - Stat Card (Compact Horizontal Style)

struct StatCard: View {
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

// MARK: - Flow Layout (Wrapping HStack)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                // Move to next line
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))

            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        totalHeight = currentY + lineHeight

        return (CGSize(width: totalWidth, height: totalHeight), frames)
    }
}

// MARK: - Threshold Warning

enum WarningSeverity {
    case info
    case warning
    case critical

    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }

    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

struct ThresholdWarning: View {
    let title: String
    let message: String
    let severity: WarningSeverity

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: severity.icon)
                .font(.system(size: 16))
                .foregroundColor(severity.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DSTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DSDarkTheme.textPrimary)

                Text(message)
                    .font(DSTypography.caption)
                    .foregroundColor(DSDarkTheme.textSecondary)
            }

            Spacer()
        }
        .padding(DSSpacing.sm)
        .background(severity.color.opacity(0.15))
        .cornerRadius(DSRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .stroke(severity.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Compact Stat Card (Grid-friendly)

struct CompactStatCard: View {
    let title: String
    let icon: String
    let value: String
    let detail: String
    var progress: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            // Header row
            HStack(spacing: DSSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(DSDarkTheme.textTertiary)

                Text(title.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DSDarkTheme.textTertiary)

                Spacer()
            }

            // Value
            Text(value)
                .font(DSTypography.title2)
                .fontWeight(.semibold)
                .foregroundColor(DSDarkTheme.textPrimary)

            // Detail
            Text(detail)
                .font(.system(size: 11))
                .foregroundColor(DSDarkTheme.textSecondary)
                .lineLimit(1)

            // Progress bar (if applicable)
            if let progress = progress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DSDarkTheme.surfaceActive)
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(DSColor.progress(for: progress))
                            .frame(width: geometry.size.width * min(progress, 1.0), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(DSSpacing.sm)
        .background(DSDarkTheme.surface)
        .cornerRadius(DSRadius.md)
    }
}
