//
//  SSHService.swift
//  ServerMonitor
//

import Foundation

actor SSHService {
    private let timeout: TimeInterval = 10

    func fetchStats(for server: Server) async -> ServerStats {
        var stats = ServerStats(serverId: server.id, status: .connecting)

        do {
            let output = try await executeSSH(server: server, command: statsCommand)
            stats = parseStats(output: output, serverId: server.id)
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

    // Combined command to get all stats in one SSH connection
    private var statsCommand: String {
        """
        echo "===UPTIME===" && uptime && \
        echo "===MEMORY===" && free -m 2>/dev/null || vm_stat && \
        echo "===DISK===" && df -h /
        """
    }

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

        // Use specified SSH key if provided
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
                        continuation.resume(throwing: SSHError.commandFailed(errorOutput))
                    }
                }
            } catch {
                continuation.resume(throwing: SSHError.executionError(error.localizedDescription))
            }
        }
    }

    private func parseStats(output: String, serverId: UUID) -> ServerStats {
        var stats = ServerStats(serverId: serverId)

        let sections = output.components(separatedBy: "===")

        for i in stride(from: 1, to: sections.count, by: 2) {
            let sectionName = sections[i].trimmingCharacters(in: .whitespacesAndNewlines)
            let sectionContent = i + 1 < sections.count ? sections[i + 1] : ""

            switch sectionName {
            case "UPTIME":
                stats.cpuLoad = parseUptime(sectionContent)
            case "MEMORY":
                stats.memory = parseMemory(sectionContent)
            case "DISK":
                stats.disk = parseDisk(sectionContent)
            default:
                break
            }
        }

        return stats
    }

    private func parseUptime(_ output: String) -> CPULoad? {
        // Parse: "load average: 0.52, 0.58, 0.59" or similar
        guard let loadRange = output.range(of: "load average") ?? output.range(of: "load averages") else {
            return nil
        }

        let afterLoad = String(output[loadRange.upperBound...])
        let numbers = afterLoad.components(separatedBy: CharacterSet(charactersIn: ": ,"))
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }

        guard numbers.count >= 3 else { return nil }

        return CPULoad(load1: numbers[0], load5: numbers[1], load15: numbers[2])
    }

    private func parseMemory(_ output: String) -> MemoryStats? {
        // Parse Linux `free -m` output:
        // Mem:          15896        8234        4521        ...
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

    private func parseDisk(_ output: String) -> DiskStats? {
        // Parse `df -h /` output:
        // Filesystem      Size  Used Avail Use% Mounted on
        // /dev/sda1       100G   45G   55G  45% /
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

    private func parseSize(_ str: String) -> Double {
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
