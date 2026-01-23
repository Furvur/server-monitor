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

// MARK: - Error Message Tests

struct SSHServiceErrorTests {

    @Test func serverStatsContainsErrorMessageOnFailure() async {
        // Create a server with invalid host to trigger connection failure
        let server = Server(
            name: "Test",
            host: "invalid.nonexistent.host.local",
            username: "testuser"
        )

        let sshService = SSHService()
        let stats = await sshService.fetchStats(for: server)

        // Should have an error message
        #expect(stats.status == .offline || stats.status == .error)
        #expect(stats.errorMessage != nil)
    }

    @Test func errorMessageNotNilWhenOffline() {
        // Test that ServerStats can hold an error message
        var stats = ServerStats(serverId: UUID(), status: .offline, errorMessage: "Test error message")

        #expect(stats.errorMessage == "Test error message")
        #expect(stats.status == .offline)

        // Test that we can update the error message
        stats.errorMessage = "Updated error message"
        #expect(stats.errorMessage == "Updated error message")
    }

    @Test func errorMessageNilWhenOnline() {
        let stats = ServerStats(serverId: UUID(), status: .online)

        #expect(stats.errorMessage == nil)
        #expect(stats.status == .online)
    }
}

// MARK: - New Parsing Method Tests

struct SSHServiceNewParsingTests {

    // MARK: - parseUptimeSeconds Tests

    @Test func parseUptimeSecondsLinuxFormat() async {
        let sshService = SSHService()
        let output = "123456.78 234567.89"

        let uptime = await sshService.parseUptimeSeconds(output)

        #expect(uptime != nil)
        #expect(uptime?.totalSeconds == 123456)
    }

    @Test func parseUptimeSecondsShortUptime() async {
        let sshService = SSHService()
        let output = "3600.50 7200.00"

        let uptime = await sshService.parseUptimeSeconds(output)

        #expect(uptime != nil)
        #expect(uptime?.totalSeconds == 3600)
        #expect(uptime?.hours == 1)
        #expect(uptime?.minutes == 0)
    }

    @Test func parseUptimeSecondsLongUptime() async {
        let sshService = SSHService()
        // 30 days in seconds = 2592000
        let output = "2592000.00 5000000.00"

        let uptime = await sshService.parseUptimeSeconds(output)

        #expect(uptime != nil)
        #expect(uptime?.totalSeconds == 2592000)
        #expect(uptime?.days == 30)
    }

    @Test func parseUptimeSecondsDisplayString() async {
        let sshService = SSHService()
        // 2 days, 3 hours, 45 minutes = 2*86400 + 3*3600 + 45*60 = 186300
        let output = "186300.00 0"

        let uptime = await sshService.parseUptimeSeconds(output)

        #expect(uptime != nil)
        #expect(uptime?.days == 2)
        #expect(uptime?.hours == 3)
        #expect(uptime?.minutes == 45)
        #expect(uptime?.displayString == "2d 3h 45m")
    }

    @Test func parseUptimeSecondsShortDisplayString() async {
        let sshService = SSHService()
        // 45 minutes = 2700 seconds
        let output = "2700.00 0"

        let uptime = await sshService.parseUptimeSeconds(output)

        #expect(uptime != nil)
        #expect(uptime?.displayString == "45m")
    }

    @Test func parseUptimeSecondsEmptyOutput() async {
        let sshService = SSHService()
        let uptime = await sshService.parseUptimeSeconds("")

        #expect(uptime == nil)
    }

    @Test func parseUptimeSecondsInvalidOutput() async {
        let sshService = SSHService()
        let uptime = await sshService.parseUptimeSeconds("not a number")

        #expect(uptime == nil)
    }

    // MARK: - parseSwap Tests

    @Test func parseSwapLinuxFormat() async {
        let sshService = SSHService()
        let output = "Swap:          2047         500        1547"

        let swap = await sshService.parseSwap(output)

        #expect(swap != nil)
        #expect(swap?.totalMB == 2047)
        #expect(swap?.usedMB == 500)
        #expect(swap?.freeMB == 1547)
    }

    @Test func parseSwapNoSwapConfigured() async {
        let sshService = SSHService()
        let output = "Swap:             0           0           0"

        let swap = await sshService.parseSwap(output)

        #expect(swap != nil)
        #expect(swap?.totalMB == 0)
        #expect(swap?.usedMB == 0)
        #expect(swap?.isActive == false)
    }

    @Test func parseSwapActiveSwap() async {
        let sshService = SSHService()
        let output = "Swap:          4096        1024        3072"

        let swap = await sshService.parseSwap(output)

        #expect(swap != nil)
        #expect(swap?.isActive == true)
        #expect(swap?.usagePercent == 25.0)
    }

    @Test func parseSwapDisplayString() async {
        let sshService = SSHService()
        let output = "Swap:          2048        1024        1024"

        let swap = await sshService.parseSwap(output)

        #expect(swap != nil)
        #expect(swap?.displayString.contains("50%") == true)
    }

    @Test func parseSwapDisplayStringNotConfigured() async {
        let sshService = SSHService()
        let output = "Swap:             0           0           0"

        let swap = await sshService.parseSwap(output)

        #expect(swap != nil)
        #expect(swap?.displayString == "Not configured")
    }

    @Test func parseSwapEmptyOutput() async {
        let sshService = SSHService()
        let swap = await sshService.parseSwap("")

        #expect(swap != nil)
        #expect(swap?.totalMB == 0)
    }

    @Test func parseSwapCaseInsensitive() async {
        let sshService = SSHService()
        let output = "swap:          1024         256         768"

        let swap = await sshService.parseSwap(output)

        #expect(swap != nil)
        #expect(swap?.totalMB == 1024)
    }

    // MARK: - parseNetwork Tests

    @Test func parseNetworkLinuxProcNetDev() async {
        let sshService = SSHService()
        // Format: interface: rx_bytes rx_packets rx_errs rx_drop rx_fifo rx_frame rx_compressed rx_multicast tx_bytes tx_packets...
        let output = "  eth0: 1234567890 1000000 0 0 0 0 0 0 9876543210 900000 0 0 0 0 0 0"

        let network = await sshService.parseNetwork(output)

        #expect(network != nil)
        #expect(network?.bytesIn == 1234567890)
        #expect(network?.bytesOut == 9876543210)
    }

    @Test func parseNetworkDisplayBytes() async {
        let sshService = SSHService()
        // 1.5 GB in, 500 MB out
        let output = "  eth0: 1610612736 1000000 0 0 0 0 0 0 524288000 900000 0 0 0 0 0 0"

        let network = await sshService.parseNetwork(output)

        #expect(network != nil)
        #expect(network?.displayBytesIn == "1.5 GB")
        #expect(network?.displayBytesOut == "500.0 MB")
    }

    @Test func parseNetworkSmallValues() async {
        let sshService = SSHService()
        // 100 KB in, 50 KB out
        let output = "  eth0: 102400 100 0 0 0 0 0 0 51200 50 0 0 0 0 0 0"

        let network = await sshService.parseNetwork(output)

        #expect(network != nil)
        #expect(network?.displayBytesIn == "100.0 KB")
        #expect(network?.displayBytesOut == "50.0 KB")
    }

    @Test func parseNetworkTerabyteValues() async {
        let sshService = SSHService()
        // 1.5 TB
        let output = "  eth0: 1649267441664 1000000 0 0 0 0 0 0 1099511627776 900000 0 0 0 0 0 0"

        let network = await sshService.parseNetwork(output)

        #expect(network != nil)
        #expect(network?.displayBytesIn == "1.5 TB")
        #expect(network?.displayBytesOut == "1.0 TB")
    }

    @Test func parseNetworkEmptyOutput() async {
        let sshService = SSHService()
        let network = await sshService.parseNetwork("")

        #expect(network == nil)
    }

    @Test func parseNetworkInvalidFormat() async {
        let sshService = SSHService()
        let network = await sshService.parseNetwork("invalid network output")

        #expect(network == nil)
    }

    // MARK: - parseSystemInfo Tests

    @Test func parseSystemInfoUbuntu() async {
        let sshService = SSHService()
        let output = """
        NAME="Ubuntu"
        VERSION_ID="22.04"
        KERNEL=5.15.0-91-generic
        ARCH=x86_64
        HOSTNAME=webserver01
        """

        let sysInfo = await sshService.parseSystemInfo(output)

        #expect(sysInfo != nil)
        #expect(sysInfo?.osName == "Ubuntu")
        #expect(sysInfo?.osVersion == "22.04")
        #expect(sysInfo?.kernelVersion == "5.15.0-91-generic")
        #expect(sysInfo?.architecture == "x86_64")
        #expect(sysInfo?.hostname == "webserver01")
    }

    @Test func parseSystemInfoDebian() async {
        let sshService = SSHService()
        let output = """
        NAME="Debian GNU/Linux"
        VERSION_ID="12"
        KERNEL=6.1.0-17-amd64
        ARCH=x86_64
        HOSTNAME=db-server
        """

        let sysInfo = await sshService.parseSystemInfo(output)

        #expect(sysInfo != nil)
        #expect(sysInfo?.osName == "Debian GNU/Linux")
        #expect(sysInfo?.osVersion == "12")
        #expect(sysInfo?.displayOS == "Debian GNU/Linux 12")
    }

    @Test func parseSystemInfoCentOS() async {
        let sshService = SSHService()
        let output = """
        NAME="CentOS Stream"
        VERSION_ID="9"
        KERNEL=5.14.0-391.el9.x86_64
        ARCH=x86_64
        HOSTNAME=app-server
        """

        let sysInfo = await sshService.parseSystemInfo(output)

        #expect(sysInfo != nil)
        #expect(sysInfo?.osName == "CentOS Stream")
        #expect(sysInfo?.osVersion == "9")
    }

    @Test func parseSystemInfoARM() async {
        let sshService = SSHService()
        let output = """
        NAME="Ubuntu"
        VERSION_ID="24.04"
        KERNEL=6.5.0-1010-aws
        ARCH=aarch64
        HOSTNAME=arm-server
        """

        let sysInfo = await sshService.parseSystemInfo(output)

        #expect(sysInfo != nil)
        #expect(sysInfo?.architecture == "aarch64")
    }

    @Test func parseSystemInfoShortKernel() async {
        let sshService = SSHService()
        let output = """
        NAME="Ubuntu"
        VERSION_ID="22.04"
        KERNEL=5.15.0-91-generic
        ARCH=x86_64
        HOSTNAME=server
        """

        let sysInfo = await sshService.parseSystemInfo(output)

        #expect(sysInfo != nil)
        #expect(sysInfo?.shortKernel == "5.15.0")
    }

    @Test func parseSystemInfoDisplayOSNoVersion() async {
        let sshService = SSHService()
        let output = """
        NAME="Alpine Linux"
        KERNEL=6.1.0
        ARCH=x86_64
        HOSTNAME=container
        """

        let sysInfo = await sshService.parseSystemInfo(output)

        #expect(sysInfo != nil)
        #expect(sysInfo?.displayOS == "Alpine Linux")
    }

    @Test func parseSystemInfoEmptyOutput() async {
        let sshService = SSHService()
        let sysInfo = await sshService.parseSystemInfo("")

        #expect(sysInfo == nil)
    }

    @Test func parseSystemInfoMinimalOutput() async {
        let sshService = SSHService()
        let output = "KERNEL=5.15.0"

        let sysInfo = await sshService.parseSystemInfo(output)

        #expect(sysInfo != nil)
        #expect(sysInfo?.kernelVersion == "5.15.0")
    }
}

// MARK: - New Model Tests

struct NewModelTests {

    // MARK: - SwapStats Tests

    @Test func swapStatsUsagePercent() {
        let swap = SwapStats(totalMB: 2048, usedMB: 512, freeMB: 1536)

        #expect(swap.usagePercent == 25.0)
    }

    @Test func swapStatsUsagePercentZeroTotal() {
        let swap = SwapStats(totalMB: 0, usedMB: 0, freeMB: 0)

        #expect(swap.usagePercent == 0)
    }

    @Test func swapStatsIsActive() {
        let activeSwap = SwapStats(totalMB: 2048, usedMB: 100, freeMB: 1948)
        let inactiveSwap = SwapStats(totalMB: 2048, usedMB: 0, freeMB: 2048)

        #expect(activeSwap.isActive == true)
        #expect(inactiveSwap.isActive == false)
    }

    // MARK: - NetworkStats Tests

    @Test func networkStatsDisplayBytes() {
        let network = NetworkStats(bytesIn: 1073741824, bytesOut: 536870912) // 1GB, 512MB

        #expect(network.displayBytesIn == "1.0 GB")
        #expect(network.displayBytesOut == "512.0 MB")
    }

    // MARK: - UptimeStats Tests

    @Test func uptimeStatsDaysHoursMinutes() {
        let uptime = UptimeStats(totalSeconds: 185100) // 2d 3h 45m

        #expect(uptime.days == 2)
        #expect(uptime.hours == 3)
        #expect(uptime.minutes == 45)
    }

    @Test func uptimeStatsDisplayString() {
        let longUptime = UptimeStats(totalSeconds: 185100) // 2d 3h 45m
        let mediumUptime = UptimeStats(totalSeconds: 7500) // 2h 5m
        let shortUptime = UptimeStats(totalSeconds: 1800) // 30m

        #expect(longUptime.displayString == "2d 3h 45m")
        #expect(mediumUptime.displayString == "2h 5m")
        #expect(shortUptime.displayString == "30m")
    }

    @Test func uptimeStatsShortDisplayString() {
        let longUptime = UptimeStats(totalSeconds: 185100)
        let mediumUptime = UptimeStats(totalSeconds: 7500)
        let shortUptime = UptimeStats(totalSeconds: 1800)

        #expect(longUptime.shortDisplayString == "2d")
        #expect(mediumUptime.shortDisplayString == "2h")
        #expect(shortUptime.shortDisplayString == "30m")
    }

    // MARK: - SystemInfo Tests

    @Test func systemInfoDisplayOS() {
        let withVersion = SystemInfo(osName: "Ubuntu", osVersion: "22.04", kernelVersion: "5.15.0", hostname: "server", architecture: "x86_64")
        let withoutVersion = SystemInfo(osName: "Alpine Linux", osVersion: "", kernelVersion: "6.1.0", hostname: "container", architecture: "x86_64")

        #expect(withVersion.displayOS == "Ubuntu 22.04")
        #expect(withoutVersion.displayOS == "Alpine Linux")
    }

    @Test func systemInfoShortKernel() {
        let sysInfo = SystemInfo(osName: "Ubuntu", osVersion: "22.04", kernelVersion: "5.15.0-91-generic", hostname: "server", architecture: "x86_64")

        #expect(sysInfo.shortKernel == "5.15.0")
    }

    // MARK: - ServiceStatus Uptime Tests

    @Test func serviceStatusUptimeDisplay() {
        let withUptime = ServiceStatus(serviceId: UUID(), isRunning: true, uptimeSeconds: 185100)
        let withoutUptime = ServiceStatus(serviceId: UUID(), isRunning: true, uptimeSeconds: nil)
        let shortUptime = ServiceStatus(serviceId: UUID(), isRunning: true, uptimeSeconds: 1800)

        #expect(withUptime.uptimeDisplay == "2d 3h")
        #expect(withoutUptime.uptimeDisplay == nil)
        #expect(shortUptime.uptimeDisplay == "30m")
    }
}
