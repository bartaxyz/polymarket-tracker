//
//  ProfitLossChart.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 2/5/25.
//

import SwiftUI
import Charts

struct ProfitLossChart: View {
    var userId: String
    var hideXAxis: Bool = false
    var hideYAxis: Bool = false
    var hideWatermark: Bool = true
    var showHeader: Bool = false
    var showPicker: Bool = false

    @State var range: PolymarketDataService.PnLRange
    @State private var portfolioValue: Double = 0
    @State private var rawData: [PolymarketDataService.PnLDataPoint] = []
    @State private var isLoading: Bool = false
    @State private var selectedDataPoint: PolymarketDataService.PnLDataPoint?
    
    var isToday: Bool { range == .today }
    var todayStart: Date {
        return Calendar.current.startOfDay(for: .now)
    }
    var todayEnd: Date {
        return Calendar.current.startOfDay(for: .now.addingTimeInterval(60 * 60 * 24))
    }
    var chartXScaleDomain: ClosedRange<Date> {
        if isToday {
            return todayStart ... todayEnd
        }
        return (rawData.first?.t ?? Date()) ... (rawData.last?.t ?? Date())
    }
    
    var filteredData: [PolymarketDataService.PnLDataPoint] {
        if isToday {
            return rawData.filter { $0.t >= todayStart && $0.t < todayEnd }
        }
        return rawData
    }
    var baseline: Double { normalizedData.first?.p ?? 0 }
    var lowestValue: Double { normalizedData.min(by: { $0.p < $1.p })?.p ?? 0 }
    var highestValue: Double { normalizedData.max(by: { $0.p < $1.p })?.p ?? 0 }
    
    var first: Double { normalizedData.first?.p ?? 0 }
    var last: Double { normalizedData.last?.p ?? 0 }
    var absolutePnL: Double { last - first }
    var normalizedData: [PolymarketDataService.PnLDataPoint] {
        let lastP = filteredData.last?.p ?? 0.0
        return filteredData.map { point in
            PolymarketDataService.PnLDataPoint(
                t: point.t,
                p: point.p - lastP + portfolioValue
            )
        }
    }
    var deltaPnL: Double { (last - first) / first}
    
    var body: some View {
        VStack(spacing: 16) {
            if showHeader {
                HStack {
                    CurrencyText(amount: portfolioValue)
                        .font(.largeTitle)
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        CurrencyText(
                            amount: absolutePnL,
                            signature: .always
                        )
                        .font(.caption)
                        .fontWeight(.semibold)
                        Text(
                            deltaPnL,
                            format: .percent.precision(.fractionLength(2))
                        )
                        .font(.caption)
                        .fontWeight(.semibold)
                        .opacity(0.5)
                    }
                }
            }

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
                
                if filteredData.isEmpty && !isLoading {
                    Text("No data available")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Chart(normalizedData, id: \.t) {
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
                        
                        if let selectedPoint = selectedDataPoint {
                            PointMark(
                                x: .value("Time", selectedPoint.t),
                                y: .value("PnL", selectedPoint.p)
                            )
                            .symbolSize(12)
                        }
                    }
                    .chartXScale(domain: chartXScaleDomain)
                    .chartYScale(domain: lowestValue ... highestValue)
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
                    .opacity(isLoading ? 0.3 : 1.0)
                }
                
                if isLoading {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if showPicker {
                Picker(selection: $range, label: EmptyView()) {
                    ForEach(PolymarketDataService.PnLRange.allCases, id: \.self) { rangeOption in
                        Text(rangeOption.label).tag(rangeOption)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
        }
        .onChange(of: range) {
            refreshData()
        }
        .task {
            refreshData()
        }
    }
    
    func refreshData() {
        Task {
            isLoading = true
            do {
                rawData = try await PolymarketDataService.fetchPnL(
                    userId: userId,
                    interval: range.interval
                )
                
                portfolioValue = try await PolymarketDataService.fetchPortfolio(
                    userId: userId
                )
                
                isLoading = false
            } catch {
                print("Error fetching PnL data: \(error)")
                isLoading = false
            }
        }
    }
}

extension Color {
    static var background: Color {
        #if os(iOS)
        return Color(uiColor: .systemBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }
}

#Preview {
    ProfitLossChart(
        userId: "0x235A480a9CCB7aDA0Ad2DC11dAC3a11FB433Febd",
        showHeader: true,
        range: .today,
    )
    .frame(
        width: 400,
        height: 240,
    )
    .padding()
}
