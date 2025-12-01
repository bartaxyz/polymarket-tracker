import Foundation

// Namespace for Polymarket models to avoid conflicts with SwiftUI types
enum PolymarketModels {
    
struct Tag: Codable {
    let id: String
    let label: String
    let slug: String
    let forceShow: Bool?
    let forceHide: Bool?
    let createdAt: String?
    let updatedAt: String?
}

struct PaginatedEventsResponse: Codable {
    let data: [GammaEvent]
    let pagination: Pagination
}

struct Pagination: Codable {
    let hasMore: Bool
}

typealias GammaResponse = PaginatedEventsResponse

struct GammaEvent: Codable {
    let id: String
    let ticker: String
    let slug: String
    let title: String
    let description: String?
    let resolutionSource: String?
    let startDate: String?
    let creationDate: String?
    let endDate: String?
    let image: String?
    let icon: String?
    let active: Bool?
    let closed: Bool?
    let archived: Bool?
    let new: Bool?
    let featured: Bool?
    let restricted: Bool?
    let liquidity: Double?
    let volume: Double?
    let openInterest: Double?
    let sortBy: String?
    let createdAt: String?
    let updatedAt: String?
    let competitive: Double?
    let volume24hr: Double?
    let volume1wk: Double?
    let volume1mo: Double?
    let volume1yr: Double?
    let enableOrderBook: Bool?
    let liquidityClob: Double?
    let negRisk: Bool?
    let negRiskMarketID: String?
    let commentCount: Int?
    let markets: [GammaMarket]
    let series: [GammaSeries]?
    let tags: [Tag]?
    let cyom: Bool?
    let showAllOutcomes: Bool?
    let showMarketImages: Bool?
    let enableNegRisk: Bool?
    let automaticallyActive: Bool?
    let seriesSlug: String?
    let negRiskAugmented: Bool?
    let pendingDeployment: Bool?
    let deploying: Bool?
}

struct GammaMarket: Codable {
    let id: String
    let question: String
    let conditionId: String
    let slug: String
    let resolutionSource: String?
    let endDate: String?
    let liquidity: String?
    let startDate: String?
    let image: String?
    let icon: String?
    let description: String?
    let outcomes: String?
    let outcomePrices: String?
    let volume: String?
    let active: Bool?
    let closed: Bool?
    let marketMakerAddress: String?
    let createdAt: String?
    let updatedAt: String?
    let new: Bool?
    let featured: Bool?
    let submittedBy: String?
    let archived: Bool?
    let resolvedBy: String?
    let restricted: Bool?
    let groupItemTitle: String?
    let groupItemThreshold: String?
    let questionID: String?
    let enableOrderBook: Bool?
    let orderPriceMinTickSize: Double?
    let orderMinSize: Double?
    let volumeNum: Double?
    let liquidityNum: Double?
    let endDateIso: String?
    let startDateIso: String?
    let hasReviewedDates: Bool?
    let volume1wk: Double?
    let volume1mo: Double?
    let volume1yr: Double?
    let clobTokenIds: String?
    let umaBond: String?
    let umaReward: String?
    let volume1wkClob: Double?
    let volume1moClob: Double?
    let volume1yrClob: Double?
    let volumeClob: Double?
    let liquidityClob: Double?
    let acceptingOrders: Bool?
    let negRisk: Bool?
    let negRiskMarketID: String?
    let negRiskRequestID: String?
    let ready: Bool?
    let funded: Bool?
    let acceptingOrdersTimestamp: String?
    let cyom: Bool?
    let competitive: Double?
    let pagerDutyNotificationEnabled: Bool?
    let approved: Bool?
    let clobRewards: [ClobReward]?
    let rewardsMinSize: Double?
    let rewardsMaxSpread: Double?
    let spread: Double?
    let oneDayPriceChange: Double?
    let oneHourPriceChange: Double?
    let oneWeekPriceChange: Double?
    let lastTradePrice: Double?
    let bestBid: Double?
    let bestAsk: Double?
    let automaticallyActive: Bool?
    let clearBookOnStart: Bool?
    let manualActivation: Bool?
    let negRiskOther: Bool?
    let umaResolutionStatuses: String?
    let pendingDeployment: Bool?
    let deploying: Bool?
}

struct GammaSeries: Codable {
    let id: String
    let ticker: String?
    let slug: String
    let title: String?
    let seriesType: String?
    let recurrence: String?
    let image: String?
    let icon: String?
    let active: Bool?
    let closed: Bool?
    let archived: Bool?
    let featured: Bool?
    let restricted: Bool?
    let createdAt: String?
    let updatedAt: String?
    let volume: Double?
    let liquidity: Double?
    let commentCount: Int?
}

struct ClobReward: Codable {
    let id: String?
    let conditionId: String?
    let assetAddress: String?
    let rewardsAmount: Double?
    let rewardsDailyRate: Double?
    let startDate: String?
    let endDate: String?
}

} // End of PolymarketModels namespace