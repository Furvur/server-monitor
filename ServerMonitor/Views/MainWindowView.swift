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
        HStack(spacing: DSSpacing.lg) {
            // Server avatar
            ZStack {
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .fill(DSDarkTheme.accentGradient)
                    .frame(width: 64, height: 64)

                Text(String(server.name.prefix(2)).uppercased())
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(server.name)
                    .font(DSTypography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(DSDarkTheme.textPrimary)

                Text("\(server.username)@\(server.host)")
                    .font(DSTypography.subheadline)
                    .foregroundColor(DSDarkTheme.textSecondary)

                HStack(spacing: DSSpacing.sm) {
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

                    if !server.enabledServices.isEmpty {
                        Text("\(stats.runningServicesCount)/\(stats.totalServicesCount) services")
                            .font(DSTypography.caption)
                            .foregroundColor(DSDarkTheme.textTertiary)
                    }

                    Text("Updated: \(stats.lastUpdated.formatted(.relative(presentation: .named)))")
                        .font(DSTypography.caption)
                        .foregroundColor(DSDarkTheme.textTertiary)
                }
            }

            Spacer()

            // Quick actions
            VStack(spacing: DSSpacing.sm) {
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
        }
        .padding(DSSpacing.lg)
        .background(DSDarkTheme.surface)
        .cornerRadius(DSRadius.lg)
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
        VStack(spacing: 16) {
            if let cpu = stats.cpuLoad {
                StatCard(
                    title: "CPU Load",
                    icon: "cpu",
                    value: cpu.displayString,
                    detail: "1 min / 5 min / 15 min averages"
                )
            }

            if let memory = stats.memory {
                StatCard(
                    title: "Memory",
                    icon: "memorychip",
                    value: memory.displayString,
                    detail: "Used / Total",
                    progress: memory.usagePercent / 100
                )
            }

            if let disk = stats.disk {
                StatCard(
                    title: "Disk",
                    icon: "internaldrive",
                    value: disk.displayString,
                    detail: "Used / Total",
                    progress: disk.usagePercent / 100
                )
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

    private var isRunning: Bool {
        status?.isRunning ?? false
    }

    private var hasContainers: Bool {
        status?.containers != nil && !(status?.containers?.isEmpty ?? true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main service row
            HStack {
                Image(systemName: service.icon)
                    .font(.title3)
                    .foregroundColor(isRunning ? .green : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(service.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let details = status?.details {
                        Text(details)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(isRunning ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(isRunning ? "Running" : "Stopped")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Expand button for Docker containers
                if hasContainers {
                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)

            // Docker containers list (expandable)
            if hasContainers && isExpanded {
                Divider()
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(status?.containers ?? []) { container in
                        ContainerRow(container: container)
                        if container.id != status?.containers?.last?.id {
                            Divider()
                                .padding(.leading, 36)
                        }
                    }
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Container Row

struct ContainerRow: View {
    let container: DockerContainer

    var body: some View {
        HStack {
            Image(systemName: container.state.icon)
                .font(.caption)
                .foregroundColor(stateColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(container.name)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(container.displayImage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(container.state.displayName)
                    .font(.caption)
                    .foregroundColor(stateColor)

                Text(container.status)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    private var stateColor: Color {
        switch container.state {
        case .running: return .green
        case .exited: return .gray
        case .paused: return .yellow
        case .restarting: return .orange
        case .dead, .removing: return .red
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
