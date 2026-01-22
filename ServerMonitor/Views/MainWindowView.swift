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
        .frame(minWidth: 600, minHeight: 400)
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
        List(monitorService.servers, selection: $selectedServer) { server in
            ServerSidebarRow(
                server: server,
                stats: monitorService.stats[server.id]
            )
            .tag(server)
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
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .navigationTitle("Servers")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showingAddServer = true }) {
                    Image(systemName: "plus")
                }
                .help("Add Server")
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let server = selectedServer,
           let stats = monitorService.stats[server.id] {
            ServerDetailView(server: server, stats: stats)
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
    @State private var testResult: String?
    @State private var isTesting: Bool = false

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
        }
    }

    var body: some View {
        VStack(spacing: 16) {
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

            // Form fields
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

            Spacer()

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
        }
        .padding()
        .frame(width: 400, height: 380)
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
                } else {
                    testResult = "Failed: \(stats.status.rawValue)"
                }
            }
        }
    }
}

// MARK: - Server Sidebar Row

struct ServerSidebarRow: View {
    let server: Server
    let stats: ServerStats?

    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading) {
                Text(server.name)
                    .font(.headline)
                if let stats = stats {
                    Text(stats.status.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var statusColor: Color {
        guard let stats = stats else { return .gray }
        switch stats.status {
        case .online: return .green
        case .offline, .error: return .red
        case .connecting: return .yellow
        case .unknown: return .gray
        }
    }
}

// MARK: - Server Detail View

struct ServerDetailView: View {
    let server: Server
    let stats: ServerStats

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                if stats.status == .online {
                    statsSection
                } else {
                    statusSection
                }
                Spacer()
            }
            .padding()
        }
        .navigationTitle(server.name)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                Text(stats.status.rawValue)
                    .font(.title2)
                    .fontWeight(.medium)
            }

            Text("\(server.username)@\(server.host)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Last updated: \(stats.lastUpdated.formatted())")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Server is \(stats.status.rawValue.lowercased())")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
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

    private var statusColor: Color {
        switch stats.status {
        case .online: return .green
        case .offline, .error: return .red
        case .connecting: return .yellow
        case .unknown: return .gray
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let icon: String
    let value: String
    let detail: String
    var progress: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
            }

            Text(value)
                .font(.title)
                .fontWeight(.semibold)

            if let progress = progress {
                ProgressView(value: progress)
                    .tint(progressColor(for: progress))
            }

            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func progressColor(for value: Double) -> Color {
        if value > 0.9 { return .red }
        if value > 0.7 { return .orange }
        return .green
    }
}
