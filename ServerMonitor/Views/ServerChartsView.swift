//
//  ServerChartsView.swift
//  ServerMonitor
//

import SwiftUI
import Charts

enum ChartTimeRange: Int, CaseIterable, Identifiable {
    case oneHour = 1
    case sixHours = 6
    case twentyFourHours = 24
    case sevenDays = 168

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .oneHour: return "1h"
        case .sixHours: return "6h"
        case .twentyFourHours: return "24h"
        case .sevenDays: return "7d"
        }
    }
}

struct ServerChartsView: View {
    let server: Server
    let historyService: HistoryService
    @State private var selectedTimeRange: ChartTimeRange = .oneHour
    @State private var snapshots: [MetricSnapshot] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Time range picker
            HStack {
                Text("Time Range")
                    .font(.headline)
                Spacer()
                Picker("", selection: $selectedTimeRange) {
                    ForEach(ChartTimeRange.allCases) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(.horizontal)

            if snapshots.isEmpty {
                ContentUnavailableView {
                    Label("No Historical Data", systemImage: "chart.line.downtrend.xyaxis")
                } description: {
                    Text("Historical data will appear here once the server has been monitored for a while.")
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        cpuLoadChart
                        memoryUsageChart
                        diskUsageChart
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadData()
        }
        .onChange(of: selectedTimeRange) { _, _ in
            loadData()
        }
    }

    private func loadData() {
        snapshots = historyService.getHistory(for: server.id, hours: selectedTimeRange.rawValue)
    }

    // MARK: - CPU Load Chart

    private var cpuLoadChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.accentColor)
                Text("CPU Load")
                    .font(.headline)
            }

            Chart {
                ForEach(snapshots) { snapshot in
                    if let load1 = snapshot.load1 {
                        LineMark(
                            x: .value("Time", snapshot.timestamp),
                            y: .value("Load", load1)
                        )
                        .foregroundStyle(by: .value("Type", "1 min"))
                    }
                    if let load5 = snapshot.load5 {
                        LineMark(
                            x: .value("Time", snapshot.timestamp),
                            y: .value("Load", load5)
                        )
                        .foregroundStyle(by: .value("Type", "5 min"))
                    }
                    if let load15 = snapshot.load15 {
                        LineMark(
                            x: .value("Time", snapshot.timestamp),
                            y: .value("Load", load15)
                        )
                        .foregroundStyle(by: .value("Type", "15 min"))
                    }
                }
            }
            .chartForegroundStyleScale([
                "1 min": Color.blue,
                "5 min": Color.green,
                "15 min": Color.orange
            ])
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: timeFormat)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartLegend(position: .top)
            .frame(height: 200)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - Memory Usage Chart

    private var memoryUsageChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "memorychip")
                    .foregroundColor(.accentColor)
                Text("Memory Usage")
                    .font(.headline)
            }

            Chart {
                ForEach(snapshots) { snapshot in
                    if let memPercent = snapshot.memoryUsagePercent {
                        AreaMark(
                            x: .value("Time", snapshot.timestamp),
                            y: .value("Usage %", memPercent)
                        )
                        .foregroundStyle(memoryGradient)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: timeFormat)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)%")
                        }
                    }
                }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 200)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - Disk Usage Chart

    private var diskUsageChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "internaldrive")
                    .foregroundColor(.accentColor)
                Text("Disk Usage")
                    .font(.headline)
            }

            Chart {
                ForEach(snapshots) { snapshot in
                    if let diskPercent = snapshot.diskUsagePercent {
                        AreaMark(
                            x: .value("Time", snapshot.timestamp),
                            y: .value("Usage %", diskPercent)
                        )
                        .foregroundStyle(diskGradient)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: timeFormat)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)%")
                        }
                    }
                }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 200)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - Helpers

    private var timeFormat: Date.FormatStyle {
        switch selectedTimeRange {
        case .oneHour, .sixHours:
            return .dateTime.hour().minute()
        case .twentyFourHours:
            return .dateTime.hour()
        case .sevenDays:
            return .dateTime.month(.abbreviated).day()
        }
    }

    private var memoryGradient: LinearGradient {
        LinearGradient(
            colors: [.green.opacity(0.6), .green.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var diskGradient: LinearGradient {
        LinearGradient(
            colors: [.blue.opacity(0.6), .blue.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
