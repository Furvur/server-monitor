//
//  HistoryServiceTests.swift
//  ServerMonitorTests
//

import Testing
import Foundation
@testable import ServerMonitor

struct HistoryServiceTests {

    // Helper to create a test history service with a temporary directory
    private func createTestHistoryService(retentionHours: Int = 24) -> HistoryService {
        return HistoryService(retentionHours: retentionHours)
    }

    // MARK: - Initialization Tests

    @Test func initializationWithDefaultRetention() {
        let service = HistoryService()
        #expect(service.retentionHours == 24)
    }

    @Test func initializationWithCustomRetention() {
        let service = HistoryService(retentionHours: 6)
        #expect(service.retentionHours == 6)
    }

    // MARK: - Record and Retrieve Tests

    @Test func recordAndRetrieveSnapshot() async throws {
        let service = createTestHistoryService()
        let serverId = UUID()
        let snapshot = MetricSnapshot(
            serverId: serverId,
            load1: 1.5,
            load5: 2.0,
            load15: 2.5
        )

        service.recordSnapshot(snapshot)

        // Give time for async write
        try await Task.sleep(nanoseconds: 100_000_000)

        let history = service.getHistory(for: serverId)
        #expect(!history.isEmpty)
        #expect(history.last?.load1 == 1.5)
    }

    @Test func recordMultipleSnapshots() async throws {
        let service = createTestHistoryService()
        let serverId = UUID()

        for i in 1...5 {
            let snapshot = MetricSnapshot(
                serverId: serverId,
                load1: Double(i)
            )
            service.recordSnapshot(snapshot)
        }

        // Give time for async writes
        try await Task.sleep(nanoseconds: 200_000_000)

        let history = service.getHistory(for: serverId)
        #expect(history.count == 5)
    }

    @Test func getHistoryForNonexistentServer() {
        let service = createTestHistoryService()
        let history = service.getHistory(for: UUID())
        #expect(history.isEmpty)
    }

    // MARK: - Time Filtering Tests

    @Test func getHistoryWithTimeFilter() async throws {
        let service = createTestHistoryService()
        let serverId = UUID()

        // Create snapshots at different times
        let now = Date()
        let twoHoursAgo = now.addingTimeInterval(-2 * 3600)
        let fourHoursAgo = now.addingTimeInterval(-4 * 3600)

        let snapshot1 = MetricSnapshot(serverId: serverId, timestamp: fourHoursAgo, load1: 1.0)
        let snapshot2 = MetricSnapshot(serverId: serverId, timestamp: twoHoursAgo, load1: 2.0)
        let snapshot3 = MetricSnapshot(serverId: serverId, timestamp: now, load1: 3.0)

        service.recordSnapshot(snapshot1)
        service.recordSnapshot(snapshot2)
        service.recordSnapshot(snapshot3)

        try await Task.sleep(nanoseconds: 200_000_000)

        // Get last 3 hours - should only include snapshot2 and snapshot3
        let history = service.getHistory(for: serverId, hours: 3)
        #expect(history.count == 2)
    }

    @Test func getHistoryWithNoTimeFilter() async throws {
        let service = createTestHistoryService()
        let serverId = UUID()

        let snapshot1 = MetricSnapshot(serverId: serverId, load1: 1.0)
        let snapshot2 = MetricSnapshot(serverId: serverId, load1: 2.0)

        service.recordSnapshot(snapshot1)
        service.recordSnapshot(snapshot2)

        try await Task.sleep(nanoseconds: 200_000_000)

        let history = service.getHistory(for: serverId, hours: nil)
        #expect(history.count == 2)
    }

    // MARK: - Sorting Tests

    @Test func historyIsSortedByTimestamp() async throws {
        let service = createTestHistoryService()
        let serverId = UUID()

        let now = Date()
        let earlier = now.addingTimeInterval(-3600)
        let earliest = now.addingTimeInterval(-7200)

        // Insert out of order
        service.recordSnapshot(MetricSnapshot(serverId: serverId, timestamp: now, load1: 3.0))
        service.recordSnapshot(MetricSnapshot(serverId: serverId, timestamp: earliest, load1: 1.0))
        service.recordSnapshot(MetricSnapshot(serverId: serverId, timestamp: earlier, load1: 2.0))

        try await Task.sleep(nanoseconds: 200_000_000)

        let history = service.getHistory(for: serverId)

        #expect(history.count == 3)
        #expect(history[0].load1 == 1.0)
        #expect(history[1].load1 == 2.0)
        #expect(history[2].load1 == 3.0)
    }

    // MARK: - Delete Tests

    @Test func deleteHistoryRemovesData() async throws {
        let service = createTestHistoryService()
        let serverId = UUID()

        service.recordSnapshot(MetricSnapshot(serverId: serverId, load1: 1.0))
        try await Task.sleep(nanoseconds: 100_000_000)

        service.deleteHistory(for: serverId)
        try await Task.sleep(nanoseconds: 100_000_000)

        let history = service.getHistory(for: serverId)
        #expect(history.isEmpty)
    }

    // MARK: - Time Range Tests

    @Test func getTimeRangeReturnsCorrectRange() async throws {
        let service = createTestHistoryService()
        let serverId = UUID()

        let start = Date().addingTimeInterval(-3600)
        let end = Date()

        service.recordSnapshot(MetricSnapshot(serverId: serverId, timestamp: start, load1: 1.0))
        service.recordSnapshot(MetricSnapshot(serverId: serverId, timestamp: end, load1: 2.0))

        try await Task.sleep(nanoseconds: 200_000_000)

        let range = service.getTimeRange(for: serverId)
        #expect(range != nil)
        #expect(abs(range!.start.timeIntervalSince(start)) < 1)
        #expect(abs(range!.end.timeIntervalSince(end)) < 1)
    }

    @Test func getTimeRangeReturnsNilForEmptyHistory() {
        let service = createTestHistoryService()
        let range = service.getTimeRange(for: UUID())
        #expect(range == nil)
    }

    // MARK: - Retention Tests

    @Test func retentionHoursCanBeChanged() {
        let service = createTestHistoryService(retentionHours: 24)
        #expect(service.retentionHours == 24)

        service.retentionHours = 6
        #expect(service.retentionHours == 6)
    }

    // MARK: - Multiple Servers Tests

    @Test func separateHistoryPerServer() async throws {
        let service = createTestHistoryService()
        let server1 = UUID()
        let server2 = UUID()

        service.recordSnapshot(MetricSnapshot(serverId: server1, load1: 1.0))
        service.recordSnapshot(MetricSnapshot(serverId: server1, load1: 1.5))
        service.recordSnapshot(MetricSnapshot(serverId: server2, load1: 2.0))

        try await Task.sleep(nanoseconds: 200_000_000)

        let history1 = service.getHistory(for: server1)
        let history2 = service.getHistory(for: server2)

        #expect(history1.count == 2)
        #expect(history2.count == 1)
    }
}
