//
//  MarketIndicator.swift
//  Polymarket
//
//  Created by Claude on 6/8/25.
//

import SwiftUI

struct MarketIndicator: View {
    let event: PolymarketDataService.GammaEvent
    
    private var marketData: (shouldShow: Bool, isBinary: Bool, percentage: Double?, label: String?) {
        // Check if we have exactly one market (hide for multiple markets)
        guard event.markets.count == 1 else {
            return (false, false, nil, nil)
        }
        
        let firstMarket = event.markets.first!
        
        // Parse outcomes
        guard let outcomesString = firstMarket.outcomes,
              let outcomesData = outcomesString.data(using: .utf8),
              let outcomes = try? JSONDecoder().decode([String].self, from: outcomesData) else {
            return (false, false, nil, nil)
        }
        
        // Parse prices
        guard let outcomePricesString = firstMarket.outcomePrices,
              let pricesData = outcomePricesString.data(using: .utf8) else {
            return (false, false, nil, nil)
        }
        
        var prices: [Double] = []
        
        // Try parsing as array of strings first, then convert to doubles
        if let priceStrings = try? JSONDecoder().decode([String].self, from: pricesData) {
            prices = priceStrings.compactMap { Double($0) }
        } else if let doubleArray = try? JSONDecoder().decode([Double].self, from: pricesData) {
            prices = doubleArray
        }
        
        guard prices.count == outcomes.count, !prices.isEmpty else {
            return (false, false, nil, nil)
        }
        
        let isBinary = outcomes.count == 2
        
        if isBinary {
            // For binary markets, always show "Yes" percentage
            if let yesIndex = outcomes.firstIndex(where: { $0.lowercased() == "yes" }) {
                let yesPercentage = prices[yesIndex]
                return (true, true, yesPercentage, "Yes")
            } else {
                // Fallback to first option if no "Yes" found
                return (true, true, prices[0], outcomes[0])
            }
        } else {
            // For multi-outcome markets, show the leading option
            let maxIndex = prices.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
            let topPercentage = prices[maxIndex]
            let topOutcome = outcomes[maxIndex]
            return (true, false, topPercentage, topOutcome)
        }
    }
    
    private var gaugeColor: Color {
        guard let percentage = marketData.percentage else { return .gray }
        if percentage < 0.3 { return .red }
        else if percentage < 0.7 { return .orange }
        else { return .green }
    }
    
    private func formatPercentage(_ percentage: Double) -> String {
        let percent = percentage * 100
        let rounded = percent.rounded()
        
        if rounded <= 0 {
            return ">1"
        } else if rounded >= 100 {
            return ">99"
        } else {
            return "\(Int(rounded))"
        }
    }
    
    var body: some View {
        let data = marketData
        
        if data.shouldShow {
            VStack(spacing: 4) {
                if data.isBinary, let percentage = data.percentage {
                    // Binary market: show gauge for "Yes" probability
                    Gauge(value: percentage, in: 0...1) {
                        Image(systemName: "percent")
                    } currentValueLabel: {
                        Text(formatPercentage(percentage))
                            .font(.body)
                            .bold()
                    }
                    .gaugeStyle(.accessoryCircular)
                    .tint(gaugeColor)
                    .scaleEffect(0.8)
                    
                    /*Text("Chance")
                        .font(.caption2)
                        .foregroundColor(.secondary)*/
                } else if !data.isBinary, let percentage = data.percentage, let label = data.label {
                    // Multi-outcome market: show leading option
                    VStack(spacing: 2) {
                        Image(systemName: "trophy")
                            .font(.title2)
                            .foregroundColor(gaugeColor)
                        
                        Text(formatPercentage(percentage) + "%")
                            .font(.caption)
                            .bold()
                            .foregroundColor(gaugeColor)
                        
                        Text(label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(width: 60, height: 60)
                    
                    Text("Leading")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
