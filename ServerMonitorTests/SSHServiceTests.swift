//
//  SSHServiceTests.swift
//  ServerMonitorTests
//

import Testing
import Foundation
@testable import ServerMonitor

struct SSHServiceParsingTests {

    // MARK: - parseUptime Tests

    @Test func parseUptimeLinuxFormat() async {
        let sshService = SSHService()
        let output = " 10:30:45 up 5 days, 3:42, 2 users, load average: 0.52, 1.23, 0.89"

        let cpuLoad = await sshService.parseUptime(output)

        #expect(cpuLoad != nil)
        #expect(cpuLoad?.load1 == 0.52)
        #expect(cpuLoad?.load5 == 1.23)
        #expect(cpuLoad?.load15 == 0.89)
    }

    @Test func parseUptimeMacOSFormat() async {
        let sshService = SSHService()
        let output = "10:30  up 5 days,  3:42, 2 users, load averages: 1.50 2.00 1.75"

        let cpuLoad = await sshService.parseUptime(output)

        #expect(cpuLoad != nil)
        #expect(cpuLoad?.load1 == 1.50)
        #expect(cpuLoad?.load5 == 2.00)
        #expect(cpuLoad?.load15 == 1.75)
    }

    @Test func parseUptimeHighLoad() async {
        let sshService = SSHService()
        let output = " 14:22:01 up 100 days, load average: 12.50, 10.25, 8.75"

        let cpuLoad = await sshService.parseUptime(output)

        #expect(cpuLoad != nil)
        #expect(cpuLoad?.load1 == 12.50)
        #expect(cpuLoad?.load5 == 10.25)
        #expect(cpuLoad?.load15 == 8.75)
    }

    @Test func parseUptimeInvalidOutput() async {
        let sshService = SSHService()
        let output = "some random output without load information"

        let cpuLoad = await sshService.parseUptime(output)

        #expect(cpuLoad == nil)
    }

    @Test func parseUptimeEmptyOutput() async {
        let sshService = SSHService()
        let cpuLoad = await sshService.parseUptime("")

        #expect(cpuLoad == nil)
    }

    // MARK: - parseMemory Tests

    @Test func parseMemoryLinuxFreeOutput() async {
        let sshService = SSHService()
        let output = """
                      total        used        free      shared  buff/cache   available
        Mem:           7982        3500        1200         256        3282        3900
        Swap:          2047         500        1547
        """

        let memory = await sshService.parseMemory(output)

        #expect(memory != nil)
        #expect(memory?.totalMB == 7982)
        #expect(memory?.usedMB == 3500)
        #expect(memory?.freeMB == 1200)
    }

    @Test func parseMemoryNoMemLine() async {
        let sshService = SSHService()
        let output = """
                      total        used        free
        Swap:          2047         500        1547
        """

        let memory = await sshService.parseMemory(output)

        #expect(memory == nil)
    }

    @Test func parseMemoryEmptyOutput() async {
        let sshService = SSHService()
        let memory = await sshService.parseMemory("")

        #expect(memory == nil)
    }

    // MARK: - parseDisk Tests

    @Test func parseDiskLinuxDfOutput() async {
        let sshService = SSHService()
        let output = """
        Filesystem      Size  Used Avail Use% Mounted on
        /dev/sda1       100G   45G   55G  45% /
        """

        let disk = await sshService.parseDisk(output)

        #expect(disk != nil)
        #expect(disk?.totalGB == 100)
        #expect(disk?.usedGB == 45)
        #expect(disk?.freeGB == 55)
        #expect(disk?.usagePercent == 45)
    }

    @Test func parseDiskWithTerabytes() async {
        let sshService = SSHService()
        let output = """
        Filesystem      Size  Used Avail Use% Mounted on
        /dev/sda1       2.0T  1.5T  500G  75% /
        """

        let disk = await sshService.parseDisk(output)

        #expect(disk != nil)
        #expect(disk?.totalGB == 2048) // 2T = 2048G
        #expect(disk?.usedGB == 1536)  // 1.5T = 1536G
        #expect(disk?.freeGB == 500)
        #expect(disk?.usagePercent == 75)
    }

    @Test func parseDiskWithMegabytes() async {
        let sshService = SSHService()
        let output = """
        Filesystem      Size  Used Avail Use% Mounted on
        /dev/sda1       512M  256M  256M  50% /
        """

        let disk = await sshService.parseDisk(output)

        #expect(disk != nil)
        #expect(disk?.totalGB == 0.5)
        #expect(disk?.usedGB == 0.25)
    }

    @Test func parseDiskEmptyOutput() async {
        let sshService = SSHService()
        let disk = await sshService.parseDisk("")

        #expect(disk == nil)
    }

    // MARK: - parseSize Tests

    @Test func parseSizeGigabytes() async {
        let sshService = SSHService()

        let result = await sshService.parseSize("100G")
        #expect(result == 100)
    }

    @Test func parseSizeTerabytes() async {
        let sshService = SSHService()

        let result = await sshService.parseSize("2T")
        #expect(result == 2048)
    }

    @Test func parseSizeMegabytes() async {
        let sshService = SSHService()

        let result = await sshService.parseSize("1024M")
        #expect(result == 1.0)
    }

    @Test func parseSizeKilobytes() async {
        let sshService = SSHService()

        let result = await sshService.parseSize("1048576K")
        #expect(result == 1.0)
    }

    @Test func parseSizeDecimal() async {
        let sshService = SSHService()

        let result = await sshService.parseSize("1.5G")
        #expect(result == 1.5)
    }

    // MARK: - parseDockerContainers Tests

    @Test func parseDockerContainersRunning() async {
        let sshService = SSHService()
        let output = "web\trunning\tnginx:latest\tUp 2 hours"

        let containers = await sshService.parseDockerContainers(output: output)

        #expect(containers.count == 1)
        #expect(containers[0].name == "web")
        #expect(containers[0].state == .running)
        #expect(containers[0].image == "nginx:latest")
        #expect(containers[0].status == "Up 2 hours")
    }

    @Test func parseDockerContainersMultiple() async {
        let sshService = SSHService()
        let output = """
        web\trunning\tnginx:latest\tUp 2 hours
        db\texited\tpostgres:15\tExited (0) 1 hour ago
        cache\tpaused\tredis:7\tUp 3 hours (Paused)
        """

        let containers = await sshService.parseDockerContainers(output: output)

        #expect(containers.count == 3)
        #expect(containers[0].state == .running)
        #expect(containers[1].state == .exited)
        #expect(containers[2].state == .paused)
    }

    @Test func parseDockerContainersAllStates() async {
        let sshService = SSHService()
        let output = """
        c1\trunning\timg\tstatus
        c2\texited\timg\tstatus
        c3\tpaused\timg\tstatus
        c4\trestarting\timg\tstatus
        c5\tdead\timg\tstatus
        c6\tcreated\timg\tstatus
        c7\tremoving\timg\tstatus
        c8\tunknown\timg\tstatus
        """

        let containers = await sshService.parseDockerContainers(output: output)

        #expect(containers.count == 8)
        #expect(containers[0].state == .running)
        #expect(containers[1].state == .exited)
        #expect(containers[2].state == .paused)
        #expect(containers[3].state == .restarting)
        #expect(containers[4].state == .dead)
        #expect(containers[5].state == .created)
        #expect(containers[6].state == .removing)
        #expect(containers[7].state == .exited) // unknown defaults to exited
    }

    @Test func parseDockerContainersInvalidFormat() async {
        let sshService = SSHService()
        let output = "invalid format without tabs"

        let containers = await sshService.parseDockerContainers(output: output)

        #expect(containers.isEmpty)
    }

    @Test func parseDockerContainersEmptyOutput() async {
        let sshService = SSHService()
        let containers = await sshService.parseDockerContainers(output: "")

        #expect(containers.isEmpty)
    }

    // MARK: - parseDetectedServices Tests

    @Test func parseDetectedServicesDocker() async {
        let sshService = SSHService()
        let output = """
        ===SERVICES===
        docker:installed
        """

        let detected = await sshService.parseDetectedServices(output: output)
        let dockerId = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!

        #expect(detected.contains(dockerId))
    }

    @Test func parseDetectedServicesMultiple() async {
        let sshService = SSHService()
        let output = """
        ===SERVICES===
        docker:installed
        nginx:installed
        postgresql:installed
        redis:installed
        """

        let detected = await sshService.parseDetectedServices(output: output)

        #expect(detected.count >= 4)
    }

    @Test func parseDetectedServicesNoneInstalled() async {
        let sshService = SSHService()
        let output = """
        ===SERVICES===
        """

        let detected = await sshService.parseDetectedServices(output: output)

        #expect(detected.isEmpty)
    }

    @Test func parseDetectedServicesEmptyOutput() async {
        let sshService = SSHService()
        let detected = await sshService.parseDetectedServices(output: "")

        #expect(detected.isEmpty)
    }

    // MARK: - parseServiceStatus Tests

    @Test func parseServiceStatusActiveInactiveRunning() async {
        let sshService = SSHService()
        let service = ServiceDefinition(
            name: "Test",
            icon: "gear",
            category: .system,
            checkCommand: "test",
            parseMode: .activeInactive
        )

        let status = await sshService.parseServiceStatus(output: "active", service: service)

        #expect(status.isRunning == true)
    }

    @Test func parseServiceStatusActiveInactiveStopped() async {
        let sshService = SSHService()
        let service = ServiceDefinition(
            name: "Test",
            icon: "gear",
            category: .system,
            checkCommand: "test",
            parseMode: .activeInactive
        )

        let status = await sshService.parseServiceStatus(output: "inactive", service: service)

        #expect(status.isRunning == false)
    }

    @Test func parseServiceStatusProcessCountRunning() async {
        let sshService = SSHService()
        let service = ServiceDefinition(
            name: "Test",
            icon: "gear",
            category: .runtime,
            checkCommand: "test",
            parseMode: .processCount
        )

        let status = await sshService.parseServiceStatus(output: "5", service: service)

        #expect(status.isRunning == true)
        #expect(status.details == "5 processes")
    }

    @Test func parseServiceStatusProcessCountSingle() async {
        let sshService = SSHService()
        let service = ServiceDefinition(
            name: "Test",
            icon: "gear",
            category: .runtime,
            checkCommand: "test",
            parseMode: .processCount
        )

        let status = await sshService.parseServiceStatus(output: "1", service: service)

        #expect(status.isRunning == true)
        #expect(status.details == "1 process")
    }

    @Test func parseServiceStatusProcessCountZero() async {
        let sshService = SSHService()
        let service = ServiceDefinition(
            name: "Test",
            icon: "gear",
            category: .runtime,
            checkCommand: "test",
            parseMode: .processCount
        )

        let status = await sshService.parseServiceStatus(output: "0", service: service)

        #expect(status.isRunning == false)
        #expect(status.details == nil)
    }

    @Test func parseServiceStatusExitCodeSuccess() async {
        let sshService = SSHService()
        let service = ServiceDefinition(
            name: "Test",
            icon: "gear",
            category: .system,
            checkCommand: "test",
            parseMode: .exitCode
        )

        let status = await sshService.parseServiceStatus(output: "OK", service: service)

        #expect(status.isRunning == true)
    }

    @Test func parseServiceStatusExitCodeEmpty() async {
        let sshService = SSHService()
        let service = ServiceDefinition(
            name: "Test",
            icon: "gear",
            category: .system,
            checkCommand: "test",
            parseMode: .exitCode
        )

        let status = await sshService.parseServiceStatus(output: "", service: service)

        #expect(status.isRunning == false)
    }

    @Test func parseServiceStatusLineCount() async {
        let sshService = SSHService()
        let service = ServiceDefinition(
            name: "Test",
            icon: "gear",
            category: .system,
            checkCommand: "test",
            parseMode: .lineCount
        )

        let status = await sshService.parseServiceStatus(output: "line1\nline2\nline3", service: service)

        #expect(status.isRunning == true)
        #expect(status.details == "3 items")
    }

    @Test func parseServiceStatusCustom() async {
        let sshService = SSHService()
        let service = ServiceDefinition(
            name: "Test",
            icon: "gear",
            category: .custom,
            checkCommand: "test",
            parseMode: .custom
        )

        let status = await sshService.parseServiceStatus(output: "custom output here", service: service)

        #expect(status.isRunning == true)
        #expect(status.details == "custom output here")
    }
}
