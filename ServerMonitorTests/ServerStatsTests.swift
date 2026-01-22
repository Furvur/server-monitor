//
//  ServerStatsTests.swift
//  ServerMonitorTests
//

import Testing
import Foundation
@testable import ServerMonitor

struct ServerStatsTests {

    // MARK: - Initialization Tests

    @Test func initializationWithDefaults() {
        let serverId = UUID()
        let stats = ServerStats(serverId: serverId)

        #expect(stats.id == serverId)
        #expect(stats.status == .unknown)
        #expect(stats.cpuLoad == nil)
        #expect(stats.memory == nil)
        #expect(stats.disk == nil)
        #expect(stats.services.isEmpty)
    }

    @Test func initializationWithStatus() {
        let serverId = UUID()
        let stats = ServerStats(serverId: serverId, status: .online)

        #expect(stats.status == .online)
    }

    // MARK: - Computed Properties Tests

    @Test func runningServicesCountWithNoServices() {
        let stats = ServerStats(serverId: UUID())
        #expect(stats.runningServicesCount == 0)
        #expect(stats.totalServicesCount == 0)
    }

    @Test func runningServicesCountWithMixedServices() {
        var stats = ServerStats(serverId: UUID())
        let service1 = UUID()
        let service2 = UUID()
        let service3 = UUID()

        stats.services[service1] = ServiceStatus(serviceId: service1, isRunning: true)
        stats.services[service2] = ServiceStatus(serviceId: service2, isRunning: false)
        stats.services[service3] = ServiceStatus(serviceId: service3, isRunning: true)

        #expect(stats.runningServicesCount == 2)
        #expect(stats.totalServicesCount == 3)
    }

    // MARK: - ServerStatus Tests

    @Test func serverStatusRawValues() {
        #expect(ServerStatus.online.rawValue == "Online")
        #expect(ServerStatus.offline.rawValue == "Offline")
        #expect(ServerStatus.connecting.rawValue == "Connecting...")
        #expect(ServerStatus.error.rawValue == "Error")
        #expect(ServerStatus.unknown.rawValue == "Unknown")
    }

    @Test func serverStatusColors() {
        #expect(ServerStatus.online.color == "green")
        #expect(ServerStatus.offline.color == "red")
        #expect(ServerStatus.error.color == "red")
        #expect(ServerStatus.connecting.color == "yellow")
        #expect(ServerStatus.unknown.color == "gray")
    }

    // MARK: - CPULoad Tests

    @Test func cpuLoadDisplayString() {
        let cpuLoad = CPULoad(load1: 0.5, load5: 1.25, load15: 2.0)
        #expect(cpuLoad.displayString == "0.50 / 1.25 / 2.00")
    }

    @Test func cpuLoadDisplayStringWithHighValues() {
        let cpuLoad = CPULoad(load1: 10.123, load5: 8.456, load15: 5.789)
        #expect(cpuLoad.displayString == "10.12 / 8.46 / 5.79")
    }

    // MARK: - MemoryStats Tests

    @Test func memoryStatsUsagePercent() {
        let memory = MemoryStats(totalMB: 8000, usedMB: 4000, freeMB: 4000)
        #expect(memory.usagePercent == 50.0)
    }

    @Test func memoryStatsUsagePercentWithZeroTotal() {
        let memory = MemoryStats(totalMB: 0, usedMB: 0, freeMB: 0)
        #expect(memory.usagePercent == 0)
    }

    @Test func memoryStatsDisplayString() {
        let memory = MemoryStats(totalMB: 8192, usedMB: 4096, freeMB: 4096)
        // 4096 / 1024 = 4.0G, 8192 / 1024 = 8.0G, 50%
        #expect(memory.displayString == "4.0G / 8.0G (50%)")
    }

    // MARK: - DiskStats Tests

    @Test func diskStatsDisplayString() {
        let disk = DiskStats(totalGB: 500, usedGB: 250, freeGB: 250, usagePercent: 50)
        #expect(disk.displayString == "250.0G / 500.0G (50%)")
    }

    @Test func diskStatsDisplayStringWithDecimals() {
        let disk = DiskStats(totalGB: 931.5, usedGB: 456.7, freeGB: 474.8, usagePercent: 49)
        #expect(disk.displayString == "456.7G / 931.5G (49%)")
    }
}
