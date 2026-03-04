//
//  MarketDetailView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 16/5/25.
//

import SwiftUI
import SwiftData
import Charts

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
                return event.image
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
        
        var volume24hr: Double? {
            switch self {
            case .event(let event): return event.volume
            case .gammaEvent(let event): return event.volume24hr
            }
        }
        
        var volume1wk: Double? {
            switch self {
            case .event: return nil
            case .gammaEvent(let event): return event.volume1wk
            }
        }
        
        var volume1mo: Double? {
            switch self {
            case .event: return nil
            case .gammaEvent(let event): return event.volume1mo
            }
        }
        
        var openInterest: Double? {
            switch self {
            case .event(let event): return nil
            case .gammaEvent(let event): return event.openInterest
            }
        }
        
        var commentCount: Int? {
            switch self {
            case .event: return nil
            case .gammaEvent(let event): return event.commentCount
            }
        }
        
        var competitive: Double? {
            switch self {
            case .event: return nil
            case .gammaEvent(let event): return event.competitive
            }
        }
        
        var resolutionSource: String? {
            switch self {
            case .event: return nil
            case .gammaEvent(let event): return event.resolutionSource
            }
        }
        
        var startDate: String? {
            switch self {
            case .event: return nil
            case .gammaEvent(let event): return event.startDate
            }
        }
    }
    
    let market: Market
    
    @Environment(\.modelContext) private var modelContext
    @Query private var watchlistItems: [WatchlistItem]
    @State private var priceHistory: [PolymarketDataService.PnLDataPoint] = []
    @State private var isLoadingChart = false
    @State private var selectedRange: PolymarketDataService.PnLRange = .max
    @ObservedObject private var dataService = PolymarketDataService.shared
    
    private var isWatchlisted: Bool {
        watchlistItems.contains { $0.eventId == market.id }
    }
    
    /// Extract the first CLOB token ID from the market's outcomes for price history
    private var firstTokenId: String? {
        guard let markets = market.markets, let first = markets.first,
              let clobTokenIds = first.clobTokenIds,
              let data = clobTokenIds.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data),
              let firstId = ids.first
        else { return nil }
        return firstId
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Price History Chart
                if firstTokenId != nil {
                    priceChartView
                }
                
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
        .task {
            await loadPriceHistory()
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    toggleWatchlist()
                } label: {
                    Image(systemName: isWatchlisted ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isWatchlisted ? .accentColor : .secondary)
                }
            }
        }
    }
    
    private var priceChartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Price History")
                .font(.headline)
                .padding(.bottom, 4)
            
            Picker("Range", selection: $selectedRange) {
                ForEach(PolymarketDataService.PnLRange.allCases, id: \.self) { range in
                    Text(range.label).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedRange) {
                Task { await loadPriceHistory() }
            }
            
            if isLoadingChart {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if priceHistory.isEmpty {
                Text("No chart data available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ProfitLossChart(
                    data: priceHistory,
                    range: selectedRange,
                    hideWatermark: true
                )
                .frame(height: 200)
            }
        }
    }
    
    private func loadPriceHistory() async {
        guard let tokenId = firstTokenId else { return }
        isLoadingChart = true
        do {
            priceHistory = try await dataService.fetchTokenPriceHistory(
                tokenId: tokenId,
                interval: selectedRange.interval,
                fidelity: 60
            )
        } catch {
            priceHistory = []
        }
        isLoadingChart = false
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Market Details")
                .font(.headline)
                .padding(.bottom, 4)
            
            // Row 1: Volume & Liquidity
            HStack(spacing: 16) {
                MarketStatView(title: "Total Volume", value: formatNumber(market.volume ?? 0))
                
                if let liquidity = market.liquidity {
                    MarketStatView(title: "Liquidity", value: formatNumber(liquidity))
                }
                
                if let oi = market.openInterest, oi > 0 {
                    MarketStatView(title: "Open Interest", value: formatNumber(oi))
                }
            }
            
            // Row 2: Volume breakdown
            if market.volume24hr != nil || market.volume1wk != nil || market.volume1mo != nil {
                HStack(spacing: 16) {
                    if let v24 = market.volume24hr {
                        MarketStatView(title: "24h Vol", value: formatNumber(v24))
                    }
                    if let v1w = market.volume1wk {
                        MarketStatView(title: "1W Vol", value: formatNumber(v1w))
                    }
                    if let v1m = market.volume1mo {
                        MarketStatView(title: "1M Vol", value: formatNumber(v1m))
                    }
                }
            }
            
            // Row 3: Dates & meta
            HStack(spacing: 16) {
                if let endDate = market.endDate {
                    MarketStatView(title: "End Date", value: formatDatePretty(endDate))
                }
                if let startDate = market.startDate {
                    MarketStatView(title: "Start Date", value: formatDatePretty(startDate))
                }
                if let comments = market.commentCount, comments > 0 {
                    MarketStatView(title: "Comments", value: "\(comments)")
                }
            }
            
            // Row 4: Competitive score & resolution
            if market.competitive != nil || (market.resolutionSource != nil && !market.resolutionSource!.isEmpty) {
                HStack(spacing: 16) {
                    if let comp = market.competitive {
                        MarketStatView(title: "Competitive", value: String(format: "%.1f%%", comp * 100))
                    }
                    if let res = market.resolutionSource, !res.isEmpty {
                        MarketStatView(title: "Resolution", value: res)
                    }
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
                    // Question / group title
                    Text(market.groupItemTitle ?? market.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    // Pricing row: Bid / Ask / Spread / Last (always show all fields)
                    HStack(spacing: 12) {
                        MiniStatView(title: "Bid", value: market.bestBid.map { formatPrice($0) } ?? "—", color: .green)
                        MiniStatView(title: "Ask", value: market.bestAsk.map { formatPrice($0) } ?? "—", color: .red)
                        MiniStatView(title: "Spread", value: market.spread.map { formatPrice($0) } ?? "—", color: .secondary)
                        MiniStatView(title: "Last", value: market.lastTradePrice.map { formatPrice($0) } ?? "—", color: .primary)
                    }
                    
                    // Price changes
                    let changes = [
                        ("1h", market.oneHourPriceChange),
                        ("1d", market.oneDayPriceChange),
                        ("1w", market.oneWeekPriceChange)
                    ].compactMap { label, val -> (String, Double)? in
                        guard let v = val else { return nil }
                        return (label, v)
                    }
                    if !changes.isEmpty {
                        HStack(spacing: 12) {
                            ForEach(changes, id: \.0) { label, change in
                                HStack(spacing: 2) {
                                    Text(label)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%+.1f¢", change * 100))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(change >= 0 ? .green : .red)
                                }
                            }
                        }
                    }
                    
                    // Liquidity per outcome (always show)
                    HStack(spacing: 4) {
                        Text("Liquidity:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(market.liquidityNum.map { $0 > 0 ? formatNumber($0) : "—" } ?? "—")
                            .font(.caption)
                            .fontWeight(.medium)
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
                        Tag(tag.label)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }
    
    private func outcomesList(outcomes: [String]) -> some View {
        HStack(spacing: 8) {
            Spacer()
            ForEach(Array(outcomes.enumerated()), id: \.element) { index, outcome in
                OutcomeBadge(
                    text: outcome,
                    number: index + 1,
                    isPositive: index == 0
                )
            }
        }
    }
    
    // Helper methods
    private func toggleWatchlist() {
        if let existing = watchlistItems.first(where: { $0.eventId == market.id }) {
            modelContext.delete(existing)
        } else {
            let item = WatchlistItem(
                eventId: market.id,
                eventSlug: market.slug,
                title: market.title,
                imageUrl: market.imageUrl
            )
            modelContext.insert(item)
        }
    }
    
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
    
    private func formatPrice(_ price: Double) -> String {
        // All prediction market prices are 0–1, show consistently in cents
        let cents = price * 100
        if cents == 0 {
            return "0¢"
        } else if cents < 1 {
            return String(format: "%.1f¢", cents)
        } else if cents == cents.rounded() {
            return String(format: "%.0f¢", cents)
        } else {
            return String(format: "%.1f¢", cents)
        }
    }
    
    private func formatDatePretty(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .none
            return df.string(from: date)
        }
        // Fallback: try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .none
            return df.string(from: date)
        }
        return dateString
    }
    
    private func formatDate(_ dateString: String) -> String {
        return formatDatePretty(dateString)
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

// Compact stat for per-outcome pricing
private struct MiniStatView: View {
    let title: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
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

// Helper view for outcome badges
private struct OutcomeBadge: View {
    let text: String
    let number: Int
    let isPositive: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .frame(width: 20, height: 20)
                .background(backgroundColor)
                .clipShape(Circle())
            
            Text(text)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundColor.opacity(0.15))
        .cornerRadius(20)
    }
    
    private var backgroundColor: Color {
        return isPositive ? Color("PositiveColor") : Color("NegativeColor")
    }
    
    private var textColor: Color {
        return isPositive ? Color("PositiveColor") : Color("NegativeColor")
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
