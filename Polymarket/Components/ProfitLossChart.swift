//
//  ProfitLossChart.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 2/5/25.
//

import SwiftUI
import Charts

struct ProfitLossChart: View {
    var data: [PolymarketDataService.PnLDataPoint]
    var hideXAxis: Bool = false
    var hideYAxis: Bool = false
    var hideWatermark: Bool = true
    
    var body: some View {
        let todayStart = Calendar.current.startOfDay(for: .now)
        let oneDay: TimeInterval = 60 * 60 * 24
        let todayEnd = Calendar.current.startOfDay(for: .now.addingTimeInterval(oneDay))
        
        let filteredData = data.filter { $0.t >= todayStart && $0.t < todayEnd }
        let baseline = filteredData.first?.p ?? 0
        
        let lowestValue = filteredData.min(by: { $0.p < $1.p })?.p ?? 0
        
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

            // The chart itself
            Chart(filteredData, id: \.t) {
                LineMark(
                    x: .value("Time", $0.t),
                    y: .value("PnL", $0.p)
                )
                .interpolationMethod(.catmullRom)
                
                RuleMark(y: .value("Baseline", baseline))
                    .foregroundStyle(.secondary.opacity(0.1))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
                
                AreaMark(
                    x: .value("Time", $0.t),
                    yStart: .value("Lowest Value", lowestValue),
                    yEnd: .value("PnL", $0.p)
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
            .chartXScale(domain: todayStart ... todayEnd)
            .chartYScale(domain: .automatic(includesZero: false))
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

#Preview {
    ProfitLossChart(
        data: [
            PolymarketDataService.PnLDataPoint(
                t: Date(timeIntervalSinceNow: TimeInterval(-50)),
                p: 100
            ),
            PolymarketDataService.PnLDataPoint(
                t: Date(timeIntervalSinceNow: TimeInterval(-40)),
                p: 50
            ),
            PolymarketDataService.PnLDataPoint(
                t: Date(timeIntervalSinceNow: TimeInterval(-30)),
                p: 70
            ),
            PolymarketDataService.PnLDataPoint(
                t: Date(timeIntervalSinceNow: TimeInterval(-20)),
                p: 120
            ),
            PolymarketDataService.PnLDataPoint(
                t: Date(timeIntervalSinceNow: TimeInterval(-10)),
                p: 24
            ),
            PolymarketDataService.PnLDataPoint(
                t: Date(),
                p: 0
            ),
        ]
    )
}
