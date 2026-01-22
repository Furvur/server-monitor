//
//  MetricSnapshotTests.swift
//  ServerMonitorTests
//

import Testing
import Foundation
@testable import ServerMonitor

struct MetricSnapshotTests {

    // MARK: - Initialization Tests

    @Test func initializationWithDefaults() {
        let serverId = UUID()
        let snapshot = MetricSnapshot(serverId: serverId)

        #expect(snapshot.serverId == serverId)
        #expect(snapshot.load1 == nil)
        #expect(snapshot.load5 == nil)
        #expect(snapshot.load15 == nil)
        #expect(snapshot.memoryTotalMB == nil)
        #expect(snapshot.memoryUsedMB == nil)
        #expect(snapshot.diskUsagePercent == nil)
    }

    @Test func initializationWithAllValues() {
        let serverId = UUID()
        let timestamp = Date()
        let snapshot = MetricSnapshot(
            serverId: serverId,
            timestamp: timestamp,
            load1: 0.5,
            load5: 1.0,
            load15: 1.5,
            memoryTotalMB: 8192,
            memoryUsedMB: 4096,
            diskUsagePercent: 45.5
        )

        #expect(snapshot.serverId == serverId)
        #expect(snapshot.timestamp == timestamp)
        #expect(snapshot.load1 == 0.5)
        #expect(snapshot.load5 == 1.0)
        #expect(snapshot.load15 == 1.5)
        #expect(snapshot.memoryTotalMB == 8192)
        #expect(snapshot.memoryUsedMB == 4096)
        #expect(snapshot.diskUsagePercent == 45.5)
    }

    // MARK: - Computed Properties

    @Test func memoryUsagePercentWithValidData() {
        let snapshot = MetricSnapshot(
            serverId: UUID(),
            memoryTotalMB: 8000,
            memoryUsedMB: 4000
        )

        #expect(snapshot.memoryUsagePercent == 50.0)
    }

    @Test func memoryUsagePercentWithHighUsage() {
        let snapshot = MetricSnapshot(
            serverId: UUID(),
            memoryTotalMB: 16384,
            memoryUsedMB: 14745
        )

        let percent = snapshot.memoryUsagePercent!
        #expect(percent > 89.9 && percent < 90.1)
    }

    @Test func memoryUsagePercentWithNilTotal() {
        let snapshot = MetricSnapshot(
            serverId: UUID(),
            memoryUsedMB: 4000
        )

        #expect(snapshot.memoryUsagePercent == nil)
    }

    @Test func memoryUsagePercentWithNilUsed() {
        let snapshot = MetricSnapshot(
            serverId: UUID(),
            memoryTotalMB: 8000
        )

        #expect(snapshot.memoryUsagePercent == nil)
    }

    @Test func memoryUsagePercentWithZeroTotal() {
        let snapshot = MetricSnapshot(
            serverId: UUID(),
            memoryTotalMB: 0,
            memoryUsedMB: 0
        )

        #expect(snapshot.memoryUsagePercent == nil)
    }

    // MARK: - Codable Tests

    @Test func encodingAndDecoding() throws {
        let original = MetricSnapshot(
            serverId: UUID(),
            timestamp: Date(),
            load1: 1.5,
            load5: 2.0,
            load15: 2.5,
            memoryTotalMB: 8192,
            memoryUsedMB: 6000,
            diskUsagePercent: 75.5
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(MetricSnapshot.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.serverId == original.serverId)
        #expect(decoded.load1 == original.load1)
        #expect(decoded.load5 == original.load5)
        #expect(decoded.load15 == original.load15)
        #expect(decoded.memoryTotalMB == original.memoryTotalMB)
        #expect(decoded.memoryUsedMB == original.memoryUsedMB)
        #expect(decoded.diskUsagePercent == original.diskUsagePercent)
    }

    @Test func encodingWithNilValues() throws {
        let original = MetricSnapshot(serverId: UUID())

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MetricSnapshot.self, from: data)

        #expect(decoded.load1 == nil)
        #expect(decoded.memoryTotalMB == nil)
        #expect(decoded.diskUsagePercent == nil)
    }

    // MARK: - Identifiable Tests

    @Test func identifiableConformance() {
        let snapshot1 = MetricSnapshot(serverId: UUID())
        let snapshot2 = MetricSnapshot(serverId: UUID())

        #expect(snapshot1.id != snapshot2.id)
    }
}
