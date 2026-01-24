//
//  SSHService.swift
//  ServerMonitor
//

import Foundation

actor SSHService {
    private let timeout: TimeInterval = 15

    // Agent constants
    private let agentMetricsPath = "/var/lib/server-monitor/metrics.json"
    private let agentBinaryPath = "/usr/local/bin/server-monitor-agent"

    // MARK: - Main Fetch Method

    func fetchStats(for server: Server) async -> ServerStats {
        // Use agent-based fetching if available and preferred
        if server.useAgentFetching {
            return await fetchStatsViaAgent(for: server)
        }

        // Fall back to command-based fetching
        return await fetchStatsViaCommands(for: server)
    }

    // MARK: - Agent-Based Fetching

    private func fetchStatsViaAgent(for server: Server) async -> ServerStats {
        var stats = ServerStats(serverId: server.id, status: .connecting)

        do {
            // Simple cat command to read the pre-collected metrics
            let output = try await executeSSH(server: server, command: "cat \(agentMetricsPath)")

            // Parse the JSON output from the agent
            let agentMetrics = try AgentMetrics.parse(from: output)
            stats = agentMetrics.toServerStats(serverId: server.id)
            stats.status = .online
        } catch let error as SSHError {
            // On SSH errors, report the error
            let (status, message) = parseSSHError(error, server: server)
            stats.status = status
            stats.errorMessage = message
        } catch {
            // On agent parsing errors, fall back to command-based fetching
            return await fetchStatsViaCommands(for: server)
        }

        stats.lastUpdated = Date()
        return stats
    }

    // MARK: - Command-Based Fetching (Original Method)

    private func fetchStatsViaCommands(for server: Server) async -> ServerStats {
        var stats = ServerStats(serverId: server.id, status: .connecting)

        do {
            // Build combined command for system stats + services
            let command = buildCommand(for: server)
            let output = try await executeSSH(server: server, command: command)

            stats = parseStats(output: output, serverId: server.id, server: server)
            stats.status = .online
        } catch let error as SSHError {
            let (status, message) = parseSSHError(error, server: server)
            stats.status = status
            stats.errorMessage = message
        } catch {
            stats.status = .error
            stats.errorMessage = "Unexpected error: \(error.localizedDescription)"
        }

        stats.lastUpdated = Date()
        return stats
    }

    // MARK: - Agent Status Detection

    func checkAgentStatus(for server: Server) async -> AgentStatus {
        do {
            // Check if agent binary exists and metrics file is recent (< 5 minutes old)
            let command = """
            if [ -f \(agentBinaryPath) ]; then
                if [ -f \(agentMetricsPath) ]; then
                    find \(agentMetricsPath) -mmin -5 -type f 2>/dev/null | grep -q . && echo "installed" || echo "stale"
                else
                    echo "no_metrics"
                fi
            else
                echo "not_installed"
            fi
            """

            let output = try await executeSSH(server: server, command: command)
            let result = output.trimmingCharacters(in: .whitespacesAndNewlines)

            switch result {
            case "installed":
                return .installed
            case "stale", "no_metrics":
                return .error  // Agent is there but not producing fresh metrics
            default:
                return .notInstalled
            }
        } catch {
            return .unknown
        }
    }

    func getAgentVersion(for server: Server) async -> String? {
        do {
            let output = try await executeSSH(server: server, command: "\(agentBinaryPath) --version 2>/dev/null || echo ''")
            let version = output.trimmingCharacters(in: .whitespacesAndNewlines)
            if version.isEmpty || version.contains("not found") {
                return nil
            }
            // Extract version number from "server-monitor-agent version X.Y.Z"
            if let range = version.range(of: "version ") {
                return String(version[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            }
            return version
        } catch {
            return nil
        }
    }

    // MARK: - Error Parsing

    private func parseSSHError(_ error: SSHError, server: Server) -> (ServerStatus, String) {
        switch error {
        case .timeout:
            return (.offline, "Connection timed out - server may be unreachable or blocked by firewall")

        case .connectionFailed(let output):
            return parseConnectionError(output, server: server)

        case .authenticationFailed:
            return (.error, "Authentication failed - check SSH key and username")

        case .commandFailed(let output):
            return (.error, "Command failed: \(output.prefix(100))")

        case .executionError(let message):
            return (.error, "Execution error: \(message)")
        }
    }

    private func parseConnectionError(_ output: String, server: Server) -> (ServerStatus, String) {
        let lowercased = output.lowercased()

        // Timeout errors
        if lowercased.contains("connection timed out") || lowercased.contains("timed out") {
            return (.offline, "Connection timed out - server may be unreachable")
        }

        // Connection refused
        if lowercased.contains("connection refused") {
            let portInfo = server.port != 22 ? " (port \(server.port))" : ""
            return (.offline, "Connection refused - SSH may not be running\(portInfo)")
        }

        // Network unreachable
        if lowercased.contains("no route to host") {
            return (.offline, "No route to host - check network connectivity")
        }

        if lowercased.contains("network is unreachable") {
            return (.offline, "Network unreachable - check your internet connection")
        }

        // DNS errors
        if lowercased.contains("could not resolve hostname") || lowercased.contains("name or service not known") {
            return (.offline, "Cannot resolve hostname '\(server.host)' - check server address")
        }

        // Host key errors
        if output.contains("REMOTE HOST IDENTIFICATION HAS CHANGED") {
            return (.error, "Host key changed - server may have been reinstalled or this could be a security issue")
        }

        if lowercased.contains("host key verification failed") {
            return (.error, "Host key verification failed - try connecting manually first")
        }

        // Authentication errors
        if lowercased.contains("permission denied") {
            if lowercased.contains("publickey") {
                return (.error, "Authentication failed - SSH key not accepted for user '\(server.username)'")
            }
            return (.error, "Permission denied - check username and SSH key")
        }

        // SSH key file errors
        if lowercased.contains("no such file") {
            if let keyPath = server.sshKeyPath, output.contains(keyPath) {
                return (.error, "SSH key file not found: \(keyPath)")
            }
            return (.error, "File not found during connection")
        }

        if lowercased.contains("bad permissions") || lowercased.contains("permissions") && lowercased.contains("ignored") {
            return (.error, "SSH key has incorrect permissions - run: chmod 600 <key_file>")
        }

        // Passphrase required
        if lowercased.contains("passphrase") || lowercased.contains("enter passphrase") {
            return (.error, "SSH key requires passphrase - add key to ssh-agent first")
        }

        // Port errors
        if lowercased.contains("port") && lowercased.contains("closed") {
            return (.offline, "Port \(server.port) is closed on \(server.host)")
        }

        // Generic connection failure
        return (.offline, "Connection failed: \(output.prefix(100))")
    }

    // MARK: - Auto-detect Services

    func detectServices(for server: Server) async -> [UUID] {
        do {
            let output = try await executeSSH(server: server, command: BuiltInServices.autoDetectCommand)
            return parseDetectedServices(output: output)
        } catch {
            return []
        }
    }

    // MARK: - Command Building

    private func buildCommand(for server: Server) -> String {
        var commands = [
            // Basic system stats
            "echo '===UPTIME===' && uptime",
            "echo '===UPTIME_SECONDS===' && cat /proc/uptime 2>/dev/null | cut -d' ' -f1 || sysctl -n kern.boottime 2>/dev/null",
            "echo '===MEMORY===' && free -m 2>/dev/null || vm_stat",
            "echo '===SWAP===' && free -m 2>/dev/null | grep -i swap || swapon --show --bytes 2>/dev/null",
            "echo '===DISK===' && df -h /",
            // Network stats (Linux)
            "echo '===NETWORK===' && cat /proc/net/dev 2>/dev/null | grep -E 'eth0|ens|enp|wlan|bond' | head -1 || netstat -ib 2>/dev/null | grep -E 'en0|eth0' | head -1",
            // System info
            "echo '===SYSINFO===' && (cat /etc/os-release 2>/dev/null | grep -E '^(NAME|VERSION_ID)=' || sw_vers 2>/dev/null) && echo \"KERNEL=$(uname -r)\" && echo \"ARCH=$(uname -m)\" && echo \"HOSTNAME=$(hostname)\""
        ]

        // Add service check commands
        for serviceId in server.enabledServices {
            if let service = BuiltInServices.service(withId: serviceId) {
                commands.append("echo '===SERVICE:\(serviceId.uuidString)===' && \(service.checkCommand)")
            }
        }

        return commands.joined(separator: " && ")
    }

    // MARK: - SSH Execution

    private func executeSSH(server: Server, command: String) async throws -> String {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        var arguments = [
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=5",
            "-o", "StrictHostKeyChecking=accept-new"
        ]

        if let keyPath = server.sshKeyPath, !keyPath.isEmpty {
            arguments.append(contentsOf: ["-i", keyPath])
        }

        if server.port != 22 {
            arguments.append(contentsOf: ["-p", String(server.port)])
        }

        arguments.append("\(server.username)@\(server.host)")
        arguments.append(command)

        process.arguments = arguments

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()

                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                    if process.isRunning {
                        process.terminate()
                    }
                }

                process.waitUntilExit()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                if process.terminationStatus == 0 {
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    continuation.resume(returning: output)
                } else {
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                    if errorOutput.contains("Connection refused") || errorOutput.contains("Connection timed out") {
                        continuation.resume(throwing: SSHError.connectionFailed(errorOutput))
                    } else if errorOutput.contains("Permission denied") {
                        continuation.resume(throwing: SSHError.authenticationFailed)
                    } else {
                        // Still return output even if exit code is non-zero (some commands may fail)
                        let output = String(data: outputData, encoding: .utf8) ?? ""
                        if !output.isEmpty {
                            continuation.resume(returning: output)
                        } else {
                            continuation.resume(throwing: SSHError.commandFailed(errorOutput))
                        }
                    }
                }
            } catch {
                continuation.resume(throwing: SSHError.executionError(error.localizedDescription))
            }
        }
    }

    // MARK: - Parsing

    private func parseStats(output: String, serverId: UUID, server: Server) -> ServerStats {
        var stats = ServerStats(serverId: serverId)

        let sections = output.components(separatedBy: "===")

        var i = 1
        while i < sections.count {
            let sectionHeader = sections[i].trimmingCharacters(in: .whitespacesAndNewlines)
            let sectionContent = i + 1 < sections.count ? sections[i + 1] : ""

            if sectionHeader == "UPTIME" {
                stats.cpuLoad = parseUptime(sectionContent)
            } else if sectionHeader == "UPTIME_SECONDS" {
                stats.uptime = parseUptimeSeconds(sectionContent)
            } else if sectionHeader == "MEMORY" {
                stats.memory = parseMemory(sectionContent)
            } else if sectionHeader == "SWAP" {
                stats.swap = parseSwap(sectionContent)
            } else if sectionHeader == "DISK" {
                stats.disk = parseDisk(sectionContent)
            } else if sectionHeader == "NETWORK" {
                stats.network = parseNetwork(sectionContent)
            } else if sectionHeader == "SYSINFO" {
                stats.systemInfo = parseSystemInfo(sectionContent)
            } else if sectionHeader.hasPrefix("SERVICE:") {
                let uuidString = String(sectionHeader.dropFirst("SERVICE:".count))
                if let serviceId = UUID(uuidString: uuidString),
                   let service = BuiltInServices.service(withId: serviceId) {
                    let serviceStatus = parseServiceStatus(
                        output: sectionContent,
                        service: service
                    )
                    stats.services[serviceId] = serviceStatus
                }
            }

            i += 2
        }

        return stats
    }

    func parseServiceStatus(output: String, service: ServiceDefinition) -> ServiceStatus {
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)

        switch service.parseMode {
        case .activeInactive:
            let isRunning = trimmedOutput.lowercased().contains("active") &&
                           !trimmedOutput.lowercased().contains("inactive")
            return ServiceStatus(serviceId: service.id, isRunning: isRunning)

        case .processCount:
            let count = Int(trimmedOutput) ?? 0
            let isRunning = count > 0
            let details = count > 0 ? "\(count) process\(count == 1 ? "" : "es")" : nil
            return ServiceStatus(serviceId: service.id, isRunning: isRunning, details: details)

        case .dockerContainers:
            let containers = parseDockerContainers(output: trimmedOutput)
            let runningCount = containers.filter { $0.state == .running }.count
            let totalCount = containers.count
            let isRunning = runningCount > 0
            let details: String?
            if totalCount == 0 {
                details = "No containers"
            } else if runningCount == totalCount {
                details = "\(runningCount) running"
            } else {
                details = "\(runningCount)/\(totalCount) running"
            }
            return ServiceStatus(
                serviceId: service.id,
                isRunning: isRunning,
                details: details,
                containers: containers
            )

        case .lineCount:
            let lines = trimmedOutput.components(separatedBy: .newlines).filter { !$0.isEmpty }
            let count = lines.count
            let isRunning = count > 0
            let details = count > 0 ? "\(count) item\(count == 1 ? "" : "s")" : nil
            return ServiceStatus(serviceId: service.id, isRunning: isRunning, details: details)

        case .exitCode:
            // If we got output, assume success (exit code 0)
            let isRunning = !trimmedOutput.isEmpty
            return ServiceStatus(serviceId: service.id, isRunning: isRunning)

        case .custom:
            let isRunning = !trimmedOutput.isEmpty
            return ServiceStatus(serviceId: service.id, isRunning: isRunning, details: trimmedOutput.isEmpty ? nil : trimmedOutput)
        }
    }

    func parseDockerContainers(output: String) -> [DockerContainer] {
        // Format: name\tstate\timage\tstatus
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }

        return lines.compactMap { line -> DockerContainer? in
            let parts = line.components(separatedBy: "\t")
            guard parts.count >= 4 else { return nil }

            let name = parts[0]
            let stateStr = parts[1].lowercased()
            let image = parts[2]
            let status = parts[3]

            let state: ContainerState
            switch stateStr {
            case "running": state = .running
            case "exited": state = .exited
            case "paused": state = .paused
            case "restarting": state = .restarting
            case "dead": state = .dead
            case "created": state = .created
            case "removing": state = .removing
            default: state = .exited
            }

            return DockerContainer(name: name, state: state, image: image, status: status)
        }
    }

    // Internal for testing
    func parseDetectedServices(output: String) -> [UUID] {
        var detectedIds: [UUID] = []

        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasSuffix(":installed") {
                let serviceName = String(trimmed.dropLast(":installed".count))

                // Map detected service name to built-in service ID
                let matchingService = BuiltInServices.all.first { service in
                    service.name.lowercased().contains(serviceName.lowercased()) ||
                    serviceName.lowercased().contains(service.name.lowercased())
                }

                if let service = matchingService {
                    detectedIds.append(service.id)
                }
            }
        }

        return detectedIds
    }

    // MARK: - System Stats Parsing (internal for testing)

    func parseUptime(_ output: String) -> CPULoad? {
        guard let loadRange = output.range(of: "load average") ?? output.range(of: "load averages") else {
            return nil
        }

        let afterLoad = String(output[loadRange.upperBound...])
        let numbers = afterLoad.components(separatedBy: CharacterSet(charactersIn: ": ,"))
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }

        guard numbers.count >= 3 else { return nil }

        return CPULoad(load1: numbers[0], load5: numbers[1], load15: numbers[2])
    }

    func parseMemory(_ output: String) -> MemoryStats? {
        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            if line.starts(with: "Mem:") {
                let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if parts.count >= 4,
                   let total = Int(parts[1]),
                   let used = Int(parts[2]),
                   let free = Int(parts[3]) {
                    return MemoryStats(totalMB: total, usedMB: used, freeMB: free)
                }
            }
        }

        return nil
    }

    func parseDisk(_ output: String) -> DiskStats? {
        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            if line.contains("/") && !line.starts(with: "Filesystem") {
                let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if parts.count >= 5 {
                    let total = parseSize(parts[1])
                    let used = parseSize(parts[2])
                    let free = parseSize(parts[3])
                    let percentStr = parts[4].replacingOccurrences(of: "%", with: "")
                    let percent = Double(percentStr) ?? 0

                    return DiskStats(totalGB: total, usedGB: used, freeGB: free, usagePercent: percent)
                }
            }
        }

        return nil
    }

    func parseSize(_ str: String) -> Double {
        let value = Double(str.filter { $0.isNumber || $0 == "." }) ?? 0
        if str.hasSuffix("T") { return value * 1024 }
        if str.hasSuffix("G") { return value }
        if str.hasSuffix("M") { return value / 1024 }
        if str.hasSuffix("K") { return value / (1024 * 1024) }
        return value
    }

    // MARK: - New Parsing Methods

    func parseUptimeSeconds(_ output: String) -> UptimeStats? {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Linux: /proc/uptime gives seconds directly (e.g., "123456.78 234567.89")
        if let seconds = Double(trimmed.components(separatedBy: " ").first ?? "") {
            return UptimeStats(totalSeconds: Int(seconds))
        }

        // macOS: sysctl gives boot time as "{ sec = 1234567890, usec = 123456 }"
        if trimmed.contains("sec =") {
            if let secRange = trimmed.range(of: "sec = "),
               let endRange = trimmed[secRange.upperBound...].range(of: ",") {
                let secString = String(trimmed[secRange.upperBound..<endRange.lowerBound])
                if let bootTime = Double(secString.trimmingCharacters(in: .whitespaces)) {
                    let uptime = Date().timeIntervalSince1970 - bootTime
                    return UptimeStats(totalSeconds: Int(uptime))
                }
            }
        }

        return nil
    }

    func parseSwap(_ output: String) -> SwapStats? {
        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            let lowercased = line.lowercased()
            // Parse "Swap: total used free" format from free -m
            if lowercased.starts(with: "swap:") {
                let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if parts.count >= 4,
                   let total = Int(parts[1]),
                   let used = Int(parts[2]),
                   let free = Int(parts[3]) {
                    return SwapStats(totalMB: total, usedMB: used, freeMB: free)
                }
            }
        }

        return SwapStats(totalMB: 0, usedMB: 0, freeMB: 0)
    }

    func parseNetwork(_ output: String) -> NetworkStats? {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Linux /proc/net/dev format:
        // interface: rx_bytes rx_packets ... tx_bytes tx_packets ...
        // Columns: 1=rx_bytes, 9=tx_bytes (0-indexed after interface name)
        let parts = trimmed.components(separatedBy: CharacterSet.whitespaces).filter { !$0.isEmpty }

        // Remove interface name (ends with ":")
        let numbers = parts.filter { !$0.contains(":") }

        if numbers.count >= 9,
           let bytesIn = UInt64(numbers[0]),
           let bytesOut = UInt64(numbers[8]) {
            return NetworkStats(bytesIn: bytesIn, bytesOut: bytesOut)
        }

        // macOS netstat -ib format: Name Mtu Network Address Ipkts Ierrs Ibytes Opkts Oerrs Obytes
        // Columns: 6=Ibytes (rx), 9=Obytes (tx) (0-indexed)
        if numbers.count >= 10,
           let bytesIn = UInt64(numbers[6]),
           let bytesOut = UInt64(numbers[9]) {
            return NetworkStats(bytesIn: bytesIn, bytesOut: bytesOut)
        }

        return nil
    }

    func parseSystemInfo(_ output: String) -> SystemInfo? {
        var osName = "Linux"
        var osVersion = ""
        var kernelVersion = ""
        var hostname = ""
        var architecture = ""

        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Parse /etc/os-release format
            if trimmed.hasPrefix("NAME=") {
                osName = trimmed
                    .replacingOccurrences(of: "NAME=", with: "")
                    .replacingOccurrences(of: "\"", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("VERSION_ID=") {
                osVersion = trimmed
                    .replacingOccurrences(of: "VERSION_ID=", with: "")
                    .replacingOccurrences(of: "\"", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
            // Parse our custom output
            else if trimmed.hasPrefix("KERNEL=") {
                kernelVersion = trimmed
                    .replacingOccurrences(of: "KERNEL=", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("ARCH=") {
                architecture = trimmed
                    .replacingOccurrences(of: "ARCH=", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("HOSTNAME=") {
                hostname = trimmed
                    .replacingOccurrences(of: "HOSTNAME=", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
            // macOS sw_vers format
            else if trimmed.hasPrefix("ProductName:") {
                osName = trimmed
                    .replacingOccurrences(of: "ProductName:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("ProductVersion:") {
                osVersion = trimmed
                    .replacingOccurrences(of: "ProductVersion:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        // Only return if we got meaningful data
        guard !kernelVersion.isEmpty || !osName.isEmpty else {
            return nil
        }

        return SystemInfo(
            osName: osName,
            osVersion: osVersion,
            kernelVersion: kernelVersion,
            hostname: hostname,
            architecture: architecture
        )
    }
}

enum SSHError: Error {
    case timeout
    case connectionFailed(String)
    case authenticationFailed
    case commandFailed(String)
    case executionError(String)
}
