//
//  SettingsView.swift
//  ServerMonitor
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var monitorService: MonitorService
    @State private var showingAddServer = false
    @State private var serverToEdit: Server?

    var body: some View {
        TabView {
            serversTab
                .tabItem {
                    Label("Servers", systemImage: "server.rack")
                }

            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .frame(width: 500, height: 450)
    }

    private var serversTab: some View {
        VStack {
            List {
                ForEach(monitorService.servers) { server in
                    ServerListRow(server: server) {
                        serverToEdit = server
                    }
                }
                .onDelete(perform: monitorService.deleteServers)
            }
            .listStyle(.inset)

            HStack {
                Button(action: { showingAddServer = true }) {
                    Label("Add Server", systemImage: "plus")
                }
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingAddServer) {
            ServerEditView(server: nil) { newServer in
                monitorService.addServer(newServer)
            }
        }
        .sheet(item: $serverToEdit) { server in
            ServerEditView(server: server) { updatedServer in
                monitorService.updateServer(updatedServer)
            }
        }
    }

    private var generalTab: some View {
        Form {
            Section("Appearance") {
                Toggle("Show in Menu Bar", isOn: $monitorService.showInMenuBar)
                Text("When enabled, a menu bar icon provides quick access to server stats without opening the main window.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Monitoring") {
                Picker("Refresh Interval", selection: $monitorService.refreshInterval) {
                    Text("15 seconds").tag(TimeInterval(15))
                    Text("30 seconds").tag(TimeInterval(30))
                    Text("1 minute").tag(TimeInterval(60))
                    Text("5 minutes").tag(TimeInterval(300))
                }

                Toggle("Start monitoring on launch", isOn: $monitorService.autoStartOnLaunch)
            }

            Section("History") {
                Picker("Data Retention", selection: $monitorService.historyRetentionHours) {
                    Text("1 hour").tag(1)
                    Text("6 hours").tag(6)
                    Text("24 hours").tag(24)
                    Text("7 days").tag(168)
                }
                Text("Historical data older than this will be automatically deleted.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("iCloud Sync") {
                Toggle("Sync servers to iCloud", isOn: $monitorService.iCloudSyncEnabled)
                Text("When enabled, your server configurations will sync across all your devices signed into the same iCloud account.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if monitorService.iCloudSyncEnabled {
                    HStack {
                        if monitorService.isICloudAvailable {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("iCloud connected")
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Sign in to iCloud to sync")
                        }
                    }
                    .font(.caption)

                    Button("Sync Now") {
                        monitorService.forceICloudSync()
                    }
                }
            }

            Section("Status") {
                LabeledContent("Monitoring") {
                    Text(monitorService.isMonitoring ? "Active" : "Paused")
                        .foregroundColor(monitorService.isMonitoring ? .green : .secondary)
                }

                LabeledContent("Servers") {
                    Text("\(monitorService.servers.count)")
                }

                Button(monitorService.isMonitoring ? "Stop Monitoring" : "Start Monitoring") {
                    if monitorService.isMonitoring {
                        monitorService.stopMonitoring()
                    } else {
                        monitorService.startMonitoring()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ServerListRow: View {
    let server: Server
    let onEdit: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(server.name)
                    .font(.headline)
                Text("\(server.username)@\(server.host)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: .constant(server.isEnabled))
                .labelsHidden()
                .disabled(true)

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

struct ServerEditView: View {
    @Environment(\.dismiss) var dismiss

    let existingServer: Server?
    let onSave: (Server) -> Void

    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = "22"
    @State private var username: String = ""
    @State private var isEnabled: Bool = true
    @State private var testResult: String?
    @State private var isTesting: Bool = false

    init(server: Server?, onSave: @escaping (Server) -> Void) {
        self.existingServer = server
        self.onSave = onSave

        if let server = server {
            _name = State(initialValue: server.name)
            _host = State(initialValue: server.host)
            _port = State(initialValue: String(server.port))
            _username = State(initialValue: server.username)
            _isEnabled = State(initialValue: server.isEnabled)
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(existingServer == nil ? "Add Server" : "Edit Server")
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                TextField("Display Name", text: $name)
                TextField("Host (IP or hostname)", text: $host)
                TextField("Port", text: $port)
                TextField("Username", text: $username)
                Toggle("Enabled", isOn: $isEnabled)
            }
            .formStyle(.grouped)

            if let result = testResult {
                Text(result)
                    .font(.caption)
                    .foregroundColor(result.contains("Success") ? .green : .red)
                    .padding(.horizontal)
            }

            HStack {
                Button("Test Connection") {
                    testConnection()
                }
                .disabled(isTesting || !isValid)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Save") {
                    save()
                }
                .keyboardShortcut(.return)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
        .padding()
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
            isEnabled: isEnabled
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
            username: username
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
