//
//  MarketDetailView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 16/5/25.
//

import SwiftUI

struct MarketDetailView: View {
    enum Market {
        case event(PolymarketDataService.Event)
        case gammaEvent(PolymarketDataService.GammaEvent)
        
        var title: String {
            switch self {
            case .event(let event):
                return event.title
            case .gammaEvent(let event):
                return event.title
            }
        }
        
        var description: String? {
            switch self {
            case .event(let event):
                return event.description
            case .gammaEvent(let event):
                return event.description
            }
        }
        
        var imageUrl: String? {
            switch self {
            case .event(let event):
                return event.imageUrl
            case .gammaEvent(let event):
                return event.image
            }
        }
        
        var endDate: String? {
            switch self {
            case .event(let event):
                return event.endDate
            case .gammaEvent(let event):
                return event.endDate
            }
        }
        
        var volume: Double? {
            switch self {
            case .event(let event):
                return event.volume
            case .gammaEvent(let event):
                return event.volume
            }
        }
        
        var liquidity: Double? {
            switch self {
            case .event(let event):
                return event.liquidity
            case .gammaEvent(let event):
                return event.liquidity
            }
        }
        
        var id: String {
            switch self {
            case .event(let event):
                return event.id
            case .gammaEvent(let event):
                return event.id
            }
        }
        
        var slug: String {
            switch self {
            case .event(let event):
                return event.slug
            case .gammaEvent(let event):
                return event.slug
            }
        }
        
        var markets: [PolymarketDataService.GammaMarket]? {
            switch self {
            case .event:
                return nil
            case .gammaEvent(let event):
                return event.markets
            }
        }
        
        var tags: [PolymarketDataService.Tag]? {
            switch self {
            case .event:
                return nil
            case .gammaEvent(let event):
                return event.tags
            }
        }
    }
    
    let market: Market
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with image and title
                headerView
                
                // Market details
                detailsView
                
                // Markets/Outcomes section (if GammaEvent)
                if let markets = market.markets, !markets.isEmpty {
                    marketsView(markets: markets)
                }
                
                // Tags section (if GammaEvent)
                if let tags = market.tags, !tags.isEmpty {
                    tagsView(tags: tags)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Market Details")
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Image
            if let imageUrl = market.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Title
            Text(market.title)
                .font(.title)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
            
            // Description
            if let description = market.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Market Details")
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack(spacing: 16) {
                MarketStatView(title: "Volume", value: formatNumber(market.volume ?? 0))
                
                if let liquidity = market.liquidity {
                    MarketStatView(title: "Liquidity", value: formatNumber(liquidity))
                }
                
                if let endDate = market.endDate {
                    MarketStatView(title: "End Date", value: formatDate(endDate))
                }
            }
            
            Divider()
                .padding(.vertical, 8)
        }
    }
    
    private func marketsView(markets: [PolymarketDataService.GammaMarket]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Outcomes")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(markets, id: \.id) { market in
                VStack(alignment: .leading, spacing: 8) {
                    Text(market.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let outcomes = market.outcomes, !outcomes.isEmpty {
                        outcomesList(outcomes: decodeOutcomes(outcomes))
                    }
                    
                    Divider()
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func tagsView(tags: [PolymarketDataService.Tag]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)
                .padding(.bottom, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.id) { tag in
                        Text(tag.label)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    private func outcomesList(outcomes: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(outcomes, id: \.self) { outcome in
                Text("• \(outcome)")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Helper methods
    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        if number >= 1_000_000 {
            return "\(formatter.string(from: NSNumber(value: number / 1_000_000)) ?? "")M"
        } else if number >= 1_000 {
            return "\(formatter.string(from: NSNumber(value: number / 1_000)) ?? "")K"
        } else {
            return formatter.string(from: NSNumber(value: number)) ?? "0"
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Simple formatting for now - this could be enhanced
        // with proper date parsing and formatting
        return dateString
    }
    
    private func decodeOutcomes(_ outcomesString: String) -> [String] {
        // Try to decode JSON array of outcomes
        if let data = outcomesString.data(using: .utf8),
           let outcomes = try? JSONDecoder().decode([String].self, from: data) {
            return outcomes
        }
        
        // Fallback to comma-separated values if not JSON
        return outcomesString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }
}

// Helper view for displaying stats
private struct MarketStatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        MarketDetailView(market: .gammaEvent(PolymarketDataService.GammaEvent(
            id: "123",
            ticker: "BTCUSD",
            slug: "bitcoin-price",
            title: "Bitcoin Price End of Year",
            description: "What will be the price of Bitcoin at the end of 2025?",
            resolutionSource: "CoinMarketCap",
            startDate: "2025-01-01",
            creationDate: "2025-01-01",
            endDate: "2025-12-31",
            image: "https://example.com/btc.png",
            icon: "https://example.com/btc-icon.png",
            active: true,
            closed: false,
            archived: false,
            new: false,
            featured: true,
            restricted: false,
            liquidity: 1500000,
            volume: 3500000,
            openInterest: 2000000,
            sortBy: nil,
            createdAt: nil,
            updatedAt: nil,
            competitive: nil,
            volume24hr: 250000,
            volume1wk: 1200000,
            volume1mo: 3000000,
            volume1yr: nil,
            enableOrderBook: true,
            liquidityClob: nil,
            negRisk: false,
            negRiskMarketID: nil,
            commentCount: 25,
            markets: [
                PolymarketDataService.GammaMarket(
                    id: "m1",
                    question: "Will Bitcoin be above $100,000?",
                    conditionId: "cond1",
                    slug: "btc-above-100k",
                    resolutionSource: nil,
                    endDate: nil,
                    liquidity: nil,
                    startDate: nil,
                    image: nil,
                    icon: nil,
                    description: nil,
                    outcomes: "[\"Yes\", \"No\"]",
                    outcomePrices: "[0.65, 0.35]",
                    volume: nil,
                    active: nil,
                    closed: nil,
                    marketMakerAddress: nil,
                    createdAt: nil,
                    updatedAt: nil,
                    new: nil,
                    featured: nil,
                    submittedBy: nil,
                    archived: nil,
                    resolvedBy: nil,
                    restricted: nil,
                    groupItemTitle: nil,
                    groupItemThreshold: nil,
                    questionID: nil,
                    enableOrderBook: nil,
                    orderPriceMinTickSize: nil,
                    orderMinSize: nil,
                    volumeNum: nil,
                    liquidityNum: nil,
                    endDateIso: nil,
                    startDateIso: nil,
                    hasReviewedDates: nil,
                    volume1wk: nil,
                    volume1mo: nil,
                    volume1yr: nil,
                    clobTokenIds: nil,
                    umaBond: nil,
                    umaReward: nil,
                    volume1wkClob: nil,
                    volume1moClob: nil,
                    volume1yrClob: nil,
                    volumeClob: nil,
                    liquidityClob: nil,
                    acceptingOrders: nil,
                    negRisk: nil,
                    negRiskMarketID: nil,
                    negRiskRequestID: nil,
                    ready: nil,
                    funded: nil,
                    acceptingOrdersTimestamp: nil,
                    cyom: nil,
                    competitive: nil,
                    pagerDutyNotificationEnabled: nil,
                    approved: nil,
                    clobRewards: nil,
                    rewardsMinSize: nil,
                    rewardsMaxSpread: nil,
                    spread: nil,
                    oneDayPriceChange: nil,
                    oneHourPriceChange: nil,
                    oneWeekPriceChange: nil,
                    lastTradePrice: nil,
                    bestBid: nil,
                    bestAsk: nil,
                    automaticallyActive: nil,
                    clearBookOnStart: nil,
                    manualActivation: nil,
                    negRiskOther: nil,
                    umaResolutionStatuses: nil,
                    pendingDeployment: nil,
                    deploying: nil
                )
            ],
            series: nil,
            tags: [
                PolymarketDataService.Tag(
                    id: "t1",
                    label: "Crypto",
                    slug: "crypto",
                    forceShow: nil,
                    forceHide: nil,
                    createdAt: nil,
                    updatedAt: nil
                ),
                PolymarketDataService.Tag(
                    id: "t2",
                    label: "Bitcoin",
                    slug: "bitcoin",
                    forceShow: nil,
                    forceHide: nil,
                    createdAt: nil,
                    updatedAt: nil
                )
            ],
            cyom: nil,
            showAllOutcomes: nil,
            showMarketImages: nil,
            enableNegRisk: nil,
            automaticallyActive: nil,
            seriesSlug: nil,
            negRiskAugmented: nil,
            pendingDeployment: nil,
            deploying: nil
        )))
    }
}