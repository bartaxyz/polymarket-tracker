//
//  ProfitLossChart.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 2/5/25.
//

import SwiftUI
import Charts

struct PortfolioView: View {
    var hideXAxis: Bool = false
    var hideYAxis: Bool = false
    var hideWatermark: Bool = true
    var showHeader: Bool = false
    var showPicker: Bool = false

    @StateObject private var dataService = PolymarketDataService.shared
    @State private var range: PolymarketDataService.PnLRange = .today
    
    var isToday: Bool { range == .today }
    var todayStart: Date {
        return Calendar.current.startOfDay(for: .now)
    }
    var todayEnd: Date {
        return Calendar.current.startOfDay(for: .now.addingTimeInterval(60 * 60 * 24))
    }
    
    var filteredData: [PolymarketDataService.PnLDataPoint] {
        guard let pnlData = dataService.pnlData else { return [] }
        if isToday {
            return pnlData.filter { $0.t >= todayStart && $0.t < todayEnd }
        }
        return pnlData
    }
    
    var baseline: Double { normalizedData.first?.p ?? 0 }
    var lowestValue: Double { normalizedData.min(by: { $0.p < $1.p })?.p ?? 0 }
    var highestValue: Double { normalizedData.max(by: { $0.p < $1.p })?.p ?? 0 }
    
    var first: Double? { normalizedData.first?.p }
    var last: Double? { normalizedData.last?.p }
    var absolutePnL: Double? {
        guard let lastValue = last, let firstValue = first else { return nil }
        return lastValue - firstValue
    }
    var normalizedData: [PolymarketDataService.PnLDataPoint] {
        let lastP = filteredData.last?.p ?? 0.0
        let portfolioValue = dataService.portfolioValue ?? 0.0
        return filteredData.map { point in
            PolymarketDataService.PnLDataPoint(
                t: point.t,
                p: point.p - lastP + portfolioValue
            )
        }
    }
    var deltaPnL: Double? {
        guard let lastValue = last, let firstValue = first, firstValue != 0 else {
            return nil
        }
        return (lastValue - firstValue) / firstValue
    }
    
    var chartXScaleDomain: ClosedRange<Date> {
        if isToday {
            return todayStart ... todayEnd
        }
        return (filteredData.first?.t ?? Date()) ... (filteredData.last?.t ?? Date())
    }
    
    var chartYScaleDomain: ClosedRange<Double> {
        let min = lowestValue
        let max = highestValue
        let padding = (max - min) * 0.1 // Add 10% padding
        return (min - padding) ... (max + padding)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if showHeader {
                HStack {
                    CurrencyText(
                        amount: dataService.portfolioValue
                    )
                    .font(.largeTitle)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        CurrencyText(
                            amount: absolutePnL,
                            signature: .always
                        )
                        .font(.caption)
                        .fontWeight(.semibold)
                        PercentageText(
                            amount: deltaPnL,
                            signature: .always
                        )
                        .font(.caption)
                        .fontWeight(.semibold)
                    }
                }
            }

            ProfitLossChart(
                data: normalizedData,
                range: range,
            )
            .opacity(dataService.isLoading ? 0.3 : 1.0)
            
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
        .onChange(of: range) { oldValue, newValue in
            print("Range changed from \(oldValue) to \(newValue)")
            refreshData()
        }
        .task {
            print("Initial data load")
            refreshData()
        }
    }
    
    private func refreshData() {
        Task {
            await dataService.refreshAllData()
        }
    }
}

#Preview {
    PortfolioView(
        showHeader: true,
        showPicker: true,
    )
    .frame(
        width: 400,
        height: 240,
    )
    .padding()
}
