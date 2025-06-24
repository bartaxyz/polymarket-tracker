//
//  EventCard.swift
//  Polymarket
//
//  Created by Claude on 6/8/25.
//

import SwiftUI

struct EventCard: View {
    let event: PolymarketModels.GammaEvent
    
    @State private var isHovered = false
    
    private var topMarkets: [(market: PolymarketModels.GammaMarket, topOutcome: String, percentage: Double)] {
        var allMarketData: [(market: PolymarketModels.GammaMarket, topOutcome: String, percentage: Double, isResolved: Bool)] = []
        
        for market in event.markets {
            // Check if market is resolved (closed)
            let isResolved = market.closed ?? false
            
            // Parse outcomes
            guard let outcomesString = market.outcomes,
                  let outcomesData = outcomesString.data(using: .utf8),
                  let outcomes = try? JSONDecoder().decode([String].self, from: outcomesData) else {
                continue
            }
            
            // Parse prices
            guard let outcomePricesString = market.outcomePrices,
                  let pricesData = outcomePricesString.data(using: .utf8) else {
                continue
            }
            
            var prices: [Double] = []
            
            // Try parsing as array of strings first, then convert to doubles
            if let priceStrings = try? JSONDecoder().decode([String].self, from: pricesData) {
                prices = priceStrings.compactMap { Double($0) }
            } else if let doubleArray = try? JSONDecoder().decode([Double].self, from: pricesData) {
                prices = doubleArray
            }
            
            guard prices.count == outcomes.count, !prices.isEmpty else {
                continue
            }
            
            // Check if this is a Yes/No market
            let isYesNo = outcomes.count == 2 && 
                         outcomes.contains(where: { $0.lowercased() == "yes" }) && 
                         outcomes.contains(where: { $0.lowercased() == "no" })
            
            let displayPercentage: Double
            let displayOutcome: String
            
            if isYesNo {
                // For Yes/No markets, always show "Yes" percentage for sorting but don't show the outcome label
                if let yesIndex = outcomes.firstIndex(where: { $0.lowercased() == "yes" }) {
                    displayPercentage = prices[yesIndex]
                    displayOutcome = "" // Don't show "Yes" label for Yes/No markets
                } else {
                    // Fallback if we can't find "Yes"
                    let maxIndex = prices.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
                    displayPercentage = prices[maxIndex]
                    displayOutcome = outcomes[maxIndex]
                }
            } else {
                // For non-Yes/No markets, show the highest probability outcome
                let maxIndex = prices.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
                displayPercentage = prices[maxIndex]
                displayOutcome = outcomes[maxIndex]
            }
            
            allMarketData.append((market: market, topOutcome: displayOutcome, percentage: displayPercentage, isResolved: isResolved))
        }
        
        // Filter out resolved markets unless all are resolved
        let unresolvedMarkets = allMarketData.filter { !$0.isResolved }
        let marketsToShow = unresolvedMarkets.isEmpty ? allMarketData : unresolvedMarkets
        
        // Sort by percentage descending and take top 2
        let sortedMarkets = marketsToShow.sorted { $0.percentage > $1.percentage }
        return Array(sortedMarkets.prefix(2).map { (market: $0.market, topOutcome: $0.topOutcome, percentage: $0.percentage) })
    }
    
    var body: some View {
        NavigationLink(destination: MarketDetailView(market: .gammaEvent(event))) {
            cardContent
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerSection
            
            if event.markets.count > 1 {
                multiMarketSection
            }
            
            if event.markets.count == 1 {
                statsSection
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? .cardBackgroundHover : .cardBackground)
                .shadow(
                    color: .black.opacity(isHovered ? 0.1 : 0),
                    radius: isHovered ? 8 : 2,
                    x: 0,
                    y: isHovered ? 4 : 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            eventImage
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            VStack(alignment: .center) {
                MarketIndicator(event: event)
                Spacer(minLength: 0)
            }
        }
    }
    
    @ViewBuilder
    private var eventImage: some View {
        if let imageUrl = event.image, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var multiMarketSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(topMarkets.enumerated()), id: \.offset) { index, marketData in
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(marketData.market.groupItemTitle ?? marketData.market.question ?? "Market \(index + 1)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(2)
                        
                        if !marketData.topOutcome.isEmpty {
                            Text(marketData.topOutcome)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(Int(marketData.percentage * 100))%")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            
            if event.markets.count > 2 {
                Text("+\(event.markets.count - 2) more markets")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 8)
    }
    
    private var statsSection: some View {
        HStack {
            StatView(title: "Volume", value: formatNumber(event.volume ?? 0))
            Spacer()
            StatView(title: "Liquidity", value: formatNumber(event.liquidity ?? 0))
            Spacer()
            StatView(title: "24h Volume", value: formatNumber(event.volume24hr ?? 0))
            Spacer()
        }
    }
    
    private func colorForPercentage(_ percentage: Double) -> Color {
        if percentage < 0.3 { return .red }
        else if percentage < 0.7 { return .orange }
        else { return .green }
    }
    
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    private func formatNumber(_ number: Double) -> String {
        if number >= 1_000_000 {
            return "\(Self.numberFormatter.string(from: NSNumber(value: number / 1_000_000)) ?? "")M"
        } else if number >= 1_000 {
            return "\(Self.numberFormatter.string(from: NSNumber(value: number / 1_000)) ?? "")K"
        } else {
            return Self.numberFormatter.string(from: NSNumber(value: number)) ?? "0"
        }
    }
}
