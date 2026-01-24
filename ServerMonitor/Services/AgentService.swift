//
//  AgentService.swift
//  ServerMonitor
//
//  Handles agent installation, uninstallation, and management

import Foundation

actor AgentService {
    // Agent paths on the remote server
    private let agentBinaryPath = "/usr/local/bin/server-monitor-agent"
    private let agentMetricsPath = "/var/lib/server-monitor/metrics.json"
    private let agentServiceName = "server-monitor-agent"

    // Current bundled agent version
    static let bundledVersion = "1.0.0"

    // MARK: - Installation

    enum InstallationStep: String {
        case detecting = "Detecting system architecture..."
        case uploading = "Uploading agent binary..."
        case configuring = "Configuring systemd service..."
        case starting = "Starting agent service..."
        case verifying = "Verifying installation..."
        case complete = "Installation complete!"
        case failed = "Installation failed"
    }

    enum AgentServiceError: Error, LocalizedError {
        case architectureDetectionFailed
        case binaryNotFound(String)
        case uploadFailed(String)
        case serviceConfigFailed(String)
        case serviceStartFailed(String)
        case verificationFailed(String)
        case sshError(String)

        var errorDescription: String? {
            switch self {
            case .architectureDetectionFailed:
                return "Failed to detect server architecture"
            case .binaryNotFound(let arch):
                return "Agent binary not found for architecture: \(arch)"
            case .uploadFailed(let reason):
                return "Failed to upload agent: \(reason)"
            case .serviceConfigFailed(let reason):
                return "Failed to configure service: \(reason)"
            case .serviceStartFailed(let reason):
                return "Failed to start service: \(reason)"
            case .verificationFailed(let reason):
                return "Verification failed: \(reason)"
            case .sshError(let message):
                return "SSH error: \(message)"
            }
        }
    }

    /// Installs the agent on a remote server
    func installAgent(
        on server: Server,
        sudoPassword: String? = nil,
        progressHandler: @escaping (InstallationStep, String) -> Void
    ) async throws {
        // Step 1: Detect architecture
        progressHandler(.detecting, "Connecting to server...")
        let arch = try await detectArchitecture(on: server)
        progressHandler(.detecting, "Detected architecture: \(arch)")

        // Step 2: Get the appropriate binary
        progressHandler(.uploading, "Preparing agent binary...")
        let binaryData = try getBinaryData(for: arch)

        // Step 3: Upload binary
        progressHandler(.uploading, "Uploading agent binary to server...")
        try await uploadBinary(binaryData, to: server, sudoPassword: sudoPassword)
        progressHandler(.uploading, "Binary uploaded successfully")

        // Step 4: Configure systemd
        progressHandler(.configuring, "Creating systemd service...")
        try await configureSystemdService(on: server, sudoPassword: sudoPassword)
        progressHandler(.configuring, "Service configured")

        // Step 5: Start service
        progressHandler(.starting, "Starting agent service...")
        try await startService(on: server, sudoPassword: sudoPassword)
        progressHandler(.starting, "Service started")

        // Step 6: Verify installation
        progressHandler(.verifying, "Waiting for first metrics collection...")
        try await Task.sleep(nanoseconds: 5_000_000_000) // Wait 5 seconds
        try await verifyInstallation(on: server)

        progressHandler(.complete, "Agent installed successfully!")
    }

    /// Uninstalls the agent from a remote server
    func uninstallAgent(from server: Server) async throws {
        let command = """
        sudo systemctl stop \(agentServiceName) 2>/dev/null || true
        sudo systemctl disable \(agentServiceName) 2>/dev/null || true
        sudo rm -f /etc/systemd/system/\(agentServiceName).service
        sudo rm -f \(agentBinaryPath)
        sudo rm -rf /var/lib/server-monitor
        sudo rm -rf /var/log/server-monitor
        sudo systemctl daemon-reload
        echo "uninstalled"
        """

        let output = try await executeSSH(server: server, command: command)
        if !output.contains("uninstalled") {
            throw AgentServiceError.sshError("Uninstallation may have failed")
        }
    }

    // MARK: - Private Methods

    private func detectArchitecture(on server: Server) async throws -> String {
        let output = try await executeSSH(server: server, command: "uname -m")
        let arch = output.trimmingCharacters(in: .whitespacesAndNewlines)

        switch arch {
        case "x86_64", "amd64":
            return "amd64"
        case "aarch64", "arm64":
            return "arm64"
        default:
            throw AgentServiceError.architectureDetectionFailed
        }
    }

    private func getBinaryData(for arch: String) throws -> Data {
        let binaryName = "server-monitor-agent-linux-\(arch)"

        // Try to find the binary in the app bundle Resources folder
        if let bundleURL = Bundle.main.url(forResource: binaryName, withExtension: nil) {
            return try Data(contentsOf: bundleURL)
        }

        // For development, try the agent/dist directory relative to the project
        if let projectPath = Bundle.main.resourceURL?.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() {
            let devPath = projectPath.appendingPathComponent("agent/dist/\(binaryName)")
            if FileManager.default.fileExists(atPath: devPath.path) {
                return try Data(contentsOf: devPath)
            }
        }

        throw AgentServiceError.binaryNotFound(arch)
    }

    private func uploadBinary(_ data: Data, to server: Server, sudoPassword: String?) async throws {
        // Write binary to a local temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let localTempFile = tempDir.appendingPathComponent("server-monitor-agent-\(UUID().uuidString)")

        do {
            try data.write(to: localTempFile)
        } catch {
            throw AgentServiceError.uploadFailed("Failed to write temporary file: \(error.localizedDescription)")
        }

        defer {
            try? FileManager.default.removeItem(at: localTempFile)
        }

        // Create directories on remote server (sudo for system dirs, no sudo for temp dir)
        let setupCommand = sudoCommand("mkdir -p /var/lib/server-monitor /var/log/server-monitor", password: sudoPassword)
        _ = try await executeSSH(server: server, command: setupCommand)

        // Create temp directory without sudo so the SSH user can write to it
        _ = try await executeSSH(server: server, command: "mkdir -p /tmp/server-monitor-install")

        // Use SCP to upload to a temporary location on the server
        let remoteTempPath = "/tmp/server-monitor-install/agent-binary"
        try await executeSCP(localPath: localTempFile.path, remotePath: remoteTempPath, server: server)

        // Move the binary to final location and set permissions
        let installCommand = sudoCommand("""
        mv \(remoteTempPath) \(agentBinaryPath) && \
        chmod +x \(agentBinaryPath) && \
        rm -rf /tmp/server-monitor-install && \
        test -x \(agentBinaryPath) && echo "upload_ok" || echo "upload_failed"
        """, password: sudoPassword)

        let output = try await executeSSH(server: server, command: installCommand)
        if !output.contains("upload_ok") {
            throw AgentServiceError.uploadFailed("Binary installation verification failed")
        }
    }

    /// Wraps a command with sudo, optionally piping password via stdin
    private func sudoCommand(_ command: String, password: String?) -> String {
        if let password = password {
            // Use sudo -S to read password from stdin
            // Echo password and pipe to sudo
            let escapedPassword = password.replacingOccurrences(of: "'", with: "'\\''")
            return "echo '\(escapedPassword)' | sudo -S bash -c '\(command.replacingOccurrences(of: "'", with: "'\\''"))'"
        } else {
            return "sudo \(command)"
        }
    }

    private func configureSystemdService(on server: Server, sudoPassword: String?) async throws {
        let serviceUnit = """
        [Unit]
        Description=Server Monitor Agent
        After=network.target

        [Service]
        Type=simple
        ExecStart=\(agentBinaryPath) --interval 60
        Restart=always
        RestartSec=10

        [Install]
        WantedBy=multi-user.target
        """

        // Write the service file and configure systemd
        let writeServiceCommand = "cat > /etc/systemd/system/\(agentServiceName).service << 'SERVICEEOF'\n\(serviceUnit)\nSERVICEEOF"
        let configCommand = sudoCommand(writeServiceCommand, password: sudoPassword)

        _ = try await executeSSH(server: server, command: configCommand)

        // Reload and enable the service
        let enableCommand = sudoCommand("systemctl daemon-reload && systemctl enable \(agentServiceName)", password: sudoPassword)
        let output = try await executeSSH(server: server, command: enableCommand + " && echo 'config_ok'")

        if !output.contains("config_ok") {
            throw AgentServiceError.serviceConfigFailed("Failed to configure systemd service")
        }
    }

    private func startService(on server: Server, sudoPassword: String?) async throws {
        let startCommand = sudoCommand("systemctl start \(agentServiceName)", password: sudoPassword)
        _ = try await executeSSH(server: server, command: startCommand)

        // Wait a moment for the service to start
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Check if service is active
        let checkCommand = sudoCommand("systemctl is-active \(agentServiceName)", password: sudoPassword)
        let output = try await executeSSH(server: server, command: checkCommand)

        if !output.trimmingCharacters(in: .whitespacesAndNewlines).contains("active") {
            throw AgentServiceError.serviceStartFailed("Service did not start properly")
        }
    }

    private func verifyInstallation(on server: Server) async throws {
        let command = "test -f \(agentMetricsPath) && echo 'verified' || echo 'not_found'"
        let output = try await executeSSH(server: server, command: command)

        if !output.contains("verified") {
            throw AgentServiceError.verificationFailed("Metrics file not created - agent may not be running")
        }
    }

    // MARK: - SSH/SCP Execution

    private func executeSCP(localPath: String, remotePath: String, server: Server) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/scp")

            var arguments = [
                "-o", "BatchMode=yes",
                "-o", "ConnectTimeout=30",
                "-o", "StrictHostKeyChecking=accept-new"
            ]

            if let keyPath = server.sshKeyPath, !keyPath.isEmpty {
                arguments += ["-i", keyPath]
            }

            if server.port != 22 {
                arguments += ["-P", String(server.port)]
            }

            arguments += [localPath, "\(server.username)@\(server.host):\(remotePath)"]

            process.arguments = arguments

            let errorPipe = Pipe()
            process.standardError = errorPipe
            process.standardOutput = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown SCP error"
                    continuation.resume(throwing: AgentServiceError.uploadFailed("SCP failed: \(errorOutput)"))
                }
            } catch {
                continuation.resume(throwing: AgentServiceError.uploadFailed("SCP error: \(error.localizedDescription)"))
            }
        }
    }

    private func executeSSH(server: Server, command: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")

            var arguments = [
                "-o", "BatchMode=yes",
                "-o", "ConnectTimeout=10",
                "-o", "StrictHostKeyChecking=accept-new"
            ]

            if let keyPath = server.sshKeyPath, !keyPath.isEmpty {
                arguments += ["-i", keyPath]
            }

            if server.port != 22 {
                arguments += ["-p", String(server.port)]
            }

            arguments += ["\(server.username)@\(server.host)", command]

            process.arguments = arguments

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                if process.terminationStatus == 0 {
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    continuation.resume(returning: output)
                } else {
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: AgentServiceError.sshError(errorOutput))
                }
            } catch {
                continuation.resume(throwing: AgentServiceError.sshError(error.localizedDescription))
            }
        }
    }
}
