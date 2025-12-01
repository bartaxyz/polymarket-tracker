import Foundation

extension PolymarketModels {

struct SearchResponse: Codable {
    let events: [Event]
    let hasMore: Bool
}

struct SearchMarket: Codable {
    let slug: String
    let question: String?
    let groupItemTitle: String?
    let outcomes: [String]
    let outcomePrices: [String]
    let lastTradePrice: Double?
    let bestAsk: Double?
    let bestBid: Double?
    let spread: Double?
    let closed: Bool?
    let archived: Bool?
}

struct Event: Codable {
    let id: String
    let title: String
    let slug: String
    let description: String?
    let image: String?
    let endDate: String?
    let volume: Double?
    let liquidity: Double?
    let markets: [SearchMarket]
    
    // Convert Event to GammaEvent for UI consistency
    func toGammaEvent() -> GammaEvent {
        // Convert SearchMarket to GammaMarket
        let convertedMarkets = markets.map { searchMarket in
            GammaMarket(
                id: searchMarket.slug,
                question: searchMarket.question ?? "",
                conditionId: searchMarket.slug,
                slug: searchMarket.slug,
                resolutionSource: nil,
                endDate: endDate,
                liquidity: nil,
                startDate: nil,
                image: image,
                icon: nil,
                description: description,
                outcomes: try? String(data: JSONEncoder().encode(searchMarket.outcomes), encoding: .utf8),
                outcomePrices: try? String(data: JSONEncoder().encode(searchMarket.outcomePrices), encoding: .utf8),
                volume: nil,
                active: true,
                closed: searchMarket.closed,
                marketMakerAddress: nil,
                createdAt: nil,
                updatedAt: nil,
                new: nil,
                featured: nil,
                submittedBy: nil,
                archived: searchMarket.archived,
                resolvedBy: nil,
                restricted: nil,
                groupItemTitle: searchMarket.groupItemTitle,
                groupItemThreshold: nil,
                questionID: nil,
                enableOrderBook: nil,
                orderPriceMinTickSize: nil,
                orderMinSize: nil,
                volumeNum: volume,
                liquidityNum: liquidity,
                endDateIso: endDate,
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
                spread: searchMarket.spread,
                oneDayPriceChange: nil,
                oneHourPriceChange: nil,
                oneWeekPriceChange: nil,
                lastTradePrice: searchMarket.lastTradePrice,
                bestBid: searchMarket.bestBid,
                bestAsk: searchMarket.bestAsk,
                automaticallyActive: nil,
                clearBookOnStart: nil,
                manualActivation: nil,
                negRiskOther: nil,
                umaResolutionStatuses: nil,
                pendingDeployment: nil,
                deploying: nil
            )
        }
        
        return GammaEvent(
            id: id,
            ticker: slug,
            slug: slug,
            title: title,
            description: description,
            resolutionSource: nil,
            startDate: nil,
            creationDate: nil,
            endDate: endDate,
            image: image,
            icon: nil,
            active: true,
            closed: nil,
            archived: nil,
            new: nil,
            featured: nil,
            restricted: nil,
            liquidity: liquidity,
            volume: volume,
            openInterest: nil,
            sortBy: nil,
            createdAt: nil,
            updatedAt: nil,
            competitive: nil,
            volume24hr: nil,
            volume1wk: nil,
            volume1mo: nil,
            volume1yr: nil,
            enableOrderBook: nil,
            liquidityClob: nil,
            negRisk: nil,
            negRiskMarketID: nil,
            commentCount: nil,
            markets: convertedMarkets,
            series: nil,
            tags: nil,
            cyom: nil,
            showAllOutcomes: nil,
            showMarketImages: nil,
            enableNegRisk: nil,
            automaticallyActive: nil,
            seriesSlug: nil,
            negRiskAugmented: nil,
            pendingDeployment: nil,
            deploying: nil
        )
    }
}

} // End of PolymarketModels extension