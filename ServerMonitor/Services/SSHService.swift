//
//  SSHService.swift
//  ServerMonitor
//

import Foundation

actor SSHService {
    private let timeout: TimeInterval = 15

    // MARK: - Main Fetch Method

    func fetchStats(for server: Server) async -> ServerStats {
        var stats = ServerStats(serverId: server.id, status: .connecting)

        do {
            // Build combined command for system stats + services
            let command = buildCommand(for: server)
            let output = try await executeSSH(server: server, command: command)

            stats = parseStats(output: output, serverId: server.id, server: server)
            stats.status = .online
        } catch SSHError.timeout {
            stats.status = .offline
        } catch SSHError.connectionFailed {
            stats.status = .offline
        } catch {
            stats.status = .error
        }

        stats.lastUpdated = Date()
        return stats
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
            "echo '===UPTIME===' && uptime",
            "echo '===MEMORY===' && free -m 2>/dev/null || vm_stat",
            "echo '===DISK===' && df -h /"
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
            } else if sectionHeader == "MEMORY" {
                stats.memory = parseMemory(sectionContent)
            } else if sectionHeader == "DISK" {
                stats.disk = parseDisk(sectionContent)
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
}

enum SSHError: Error {
    case timeout
    case connectionFailed(String)
    case authenticationFailed
    case commandFailed(String)
    case executionError(String)
}
