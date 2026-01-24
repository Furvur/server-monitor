//
//  ServerChartsView.swift
//  ServerMonitor
//

import SwiftUI
import Charts

// MARK: - Sparkline Chart

struct Sparkline: View {
    let data: [Double]
    var color: Color = DSDarkTheme.online
    var showGradient: Bool = true
    var height: CGFloat = 40

    var body: some View {
        if data.isEmpty {
            Rectangle()
                .fill(DSDarkTheme.surfaceActive)
                .frame(height: height)
                .cornerRadius(DSRadius.sm)
        } else {
            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)

                    if showGradient {
                        AreaMark(
                            x: .value("Index", index),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .frame(height: height)
        }
    }
}

// MARK: - Sparkline with Value Indicator

struct SparklineWithIndicator: View {
    let data: [Double]
    var color: Color = DSDarkTheme.online
    var unit: String = "%"
    var height: CGFloat = 40

    private var minValue: Double {
        data.min() ?? 0
    }

    private var maxValue: Double {
        data.max() ?? 100
    }

    private var currentValue: Double {
        data.last ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
            Sparkline(data: data, color: color, height: height)

            // Min/Max indicators
            if !data.isEmpty {
                HStack {
                    Text(String(format: "%.0f%@", minValue, unit))
                        .font(.system(size: 9))
                        .foregroundColor(DSDarkTheme.textMuted)
                    Spacer()
                    Text(String(format: "%.0f%@", maxValue, unit))
                        .font(.system(size: 9))
                        .foregroundColor(DSDarkTheme.textMuted)
                }
            }
        }
    }
}

// MARK: - Helper to extract sparkline data from snapshots

extension Array where Element == MetricSnapshot {
    func memoryPercentages() -> [Double] {
        compactMap { $0.memoryUsagePercent }
    }

    func diskPercentages() -> [Double] {
        compactMap { $0.diskUsagePercent }
    }

    func cpuLoad1() -> [Double] {
        compactMap { $0.load1 }
    }

    func cpuLoad5() -> [Double] {
        compactMap { $0.load5 }
    }
}
