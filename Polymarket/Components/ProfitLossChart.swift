//
//  ProfitLossChart.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 2/5/25.
//

import SwiftUI
import Charts

struct ProfitLossChart: View {
    let data: [PolymarketDataService.PnLDataPoint]
    let range: PolymarketDataService.PnLRange
    
    var hideXAxis: Bool = false
    var hideYAxis: Bool = false
    var hideWatermark: Bool = true
   
    var isToday: Bool { range == .today }
    var todayStart: Date {
        return Calendar.current.startOfDay(for: .now)
    }
    var todayEnd: Date {
        return Calendar.current.startOfDay(for: .now.addingTimeInterval(60 * 60 * 24))
    }
    
    var baseline: Double { data.first?.p ?? 0 }
    var lowestValue: Double { data.min(by: { $0.p < $1.p })?.p ?? 0 }
    var highestValue: Double { data.max(by: { $0.p < $1.p })?.p ?? 0 }

    var chartXScaleDomain: ClosedRange<Date> {
        if isToday {
            return todayStart ... todayEnd
        }
        return (data.first?.t ?? Date()) ... (data.last?.t ?? Date())
    }
    var chartYScaleDomain: ClosedRange<Double> {
        let min = lowestValue
        let max = highestValue
        let padding = (max - min) * 0.1 // Add 10% padding
        return (min - padding) ... (max + padding)
    }
    
    var body: some View {
        ZStack {
            if !hideWatermark {
                Image("polymarket")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.05)
                    .frame(maxWidth: 120)
                    .padding([.bottom, .trailing], 12)
                    .allowsHitTesting(false)
            }
            
            if data.isEmpty {
                Text("No data available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(data, id: \.t) { point in
                    LineMark(
                        x: .value("Time", point.t),
                        y: .value("PnL", point.p)
                    )
                    .interpolationMethod(.catmullRom)
                    
                    RuleMark(y: .value("Baseline", baseline))
                        .foregroundStyle(.secondary.opacity(0.1))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    
                    AreaMark(
                        x: .value("Time", point.t),
                        yStart: .value("Lowest Value", lowestValue),
                        yEnd: .value("PnL", point.p)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .accentColor.opacity(0.5), location: 0),
                                .init(color: .clear, location: 1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartXScale(domain: chartXScaleDomain)
                .chartYScale(domain: chartYScaleDomain)
                .chartXAxis {
                    if !hideXAxis {
                        AxisMarks {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                }
                .chartYAxis {
                    if !hideYAxis {
                        AxisMarks {
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                }
            }
        }
    }
}

extension ProfitLossChart: Equatable {
    static func == (lhs: ProfitLossChart, rhs: ProfitLossChart) -> Bool {
        lhs.data == rhs.data && lhs.range == rhs.range
    }
}

#Preview {
    ProfitLossChart(
        data: [
            .init(t: Date(timeIntervalSince1970: 1746144000), p: 356.80716),
            .init(t: Date(timeIntervalSince1970: 1746147600), p: 359.93216),
            .init(t: Date(timeIntervalSince1970: 1746151200), p: 357.70993),
            .init(t: Date(timeIntervalSince1970: 1746154800), p: 354.9987),
            .init(t: Date(timeIntervalSince1970: 1746158400), p: 364.3737),
            .init(t: Date(timeIntervalSince1970: 1746162000), p: 364.51956),
            .init(t: Date(timeIntervalSince1970: 1746165600), p: 364.51956),
            .init(t: Date(timeIntervalSince1970: 1746169200), p: 370.06534),
            .init(t: Date(timeIntervalSince1970: 1746172800), p: 375.63373),
            .init(t: Date(timeIntervalSince1970: 1746176400), p: 376.33795),
            .init(t: Date(timeIntervalSince1970: 1746180000), p: 381.90637),
            .init(t: Date(timeIntervalSince1970: 1746183600), p: 379.1951),
            .init(t: Date(timeIntervalSince1970: 1746187200), p: 379.1951),
            .init(t: Date(timeIntervalSince1970: 1746190800), p: 360.0255),
            .init(t: Date(timeIntervalSince1970: 1746194400), p: 372.0394),
            .init(t: Date(timeIntervalSince1970: 1746198000), p: 377.18808)
        ],
        range: .max,
    )
    .frame(
        width: 400,
        height: 240,
    )
    .padding()
}
