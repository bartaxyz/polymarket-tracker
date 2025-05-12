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
    @State private var data: [PolymarketDataService.PnLDataPoint] = []
    @State private var range: PolymarketDataService.PnLRange = .today
    @State private var isLoading: Bool = false
    @State private var lastUpdated: Date = Date()

    var isToday: Bool { range == .today }
    var todayStart: Date {
        return Calendar.current.startOfDay(for: .now)
    }
    var todayEnd: Date {
        return Calendar.current.startOfDay(for: .now.addingTimeInterval(60 * 60 * 24))
    }

    var filteredData: [PolymarketDataService.PnLDataPoint] {
        if isToday {
            return data.filter { $0.t >= todayStart && $0.t < todayEnd }
        }
        return data
    }
    var first: Double? { filteredData.first?.p }
    var last: Double? { filteredData.last?.p }
    var absolutePnL: Double? {
        guard let lastValue = last, let firstValue = first else { return nil }
        return lastValue - firstValue
    }
    var normalizedData: [PolymarketDataService.PnLDataPoint] {
        return filteredData.map { point in
            PolymarketDataService.PnLDataPoint(
                t: point.t,
                p: point.p - first!
            )
        }
    }
    
    var baseline: Double { normalizedData.first?.p ?? 0 }
    var lowestValue: Double { normalizedData.min(by: { $0.p < $1.p })?.p ?? 0 }
    var highestValue: Double { normalizedData.max(by: { $0.p < $1.p })?.p ?? 0 }
    
    var deltaPnL: Double? {
        guard let lastValue = last, let firstValue = first, firstValue != 0 else {
            return nil
        }
        return (lastValue - firstValue) / firstValue
    }

    var chartId: String {
        return "\(lastUpdated.timeIntervalSince1970)"
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
                            signature: .never,
                            // hasBackground: true,
                            isDelta: true,
                            hasArrow: true
                        )

                        PercentageText(
                            amount: deltaPnL,
                            signature: .always
                        )
                        .font(.caption)
                        .opacity(0.5)
                    }
                }
            }
            
            if showPicker {
                Picker(selection: $range, label: EmptyView()) {
                    ForEach(PolymarketDataService.PnLRange.allCases, id: \.self) { rangeOption in
                        Text(rangeOption.label).tag(rangeOption)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .disabled(isLoading)
            }

            ProfitLossChart(
                data: normalizedData,
                range: range,
            )
            .id(chartId)
            .opacity(isLoading ? 0.3 : 1.0)
        }
        .onChange(of: range) { oldValue, newValue in
            Task { await fetchData() }
        }
        .task {
            await fetchData()
        }
    }

    func fetchData() async {
        guard !isLoading else { return }
        guard let userId = dataService.currentUserId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        guard let pnlData = try? await dataService.fetchPnL(
            userId: userId,
            interval: PolymarketDataService.PnLInterval(rawValue: range.rawValue) ?? .day
        ) else { return }
        
        data = pnlData
        lastUpdated = Date()
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
