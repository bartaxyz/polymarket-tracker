//
//  PolymarketDataService.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import Foundation

@MainActor
class PolymarketDataService: ObservableObject {
    static let shared = PolymarketDataService()
    
    // MARK: - API Endpoints
    
    private enum API {
        static let dataAPI = "https://data-api.polymarket.com"
        static let pnlAPI = "https://user-pnl-api.polymarket.com"
        static let gammaAPI = "https://gamma-api.polymarket.com"
        static let searchAPI = "https://polymarket.com/api"
        static let polygonRPC = "https://polygon-bor-rpc.publicnode.com"
        /// USDC on Polygon (Polymarket collateral)
        static let usdcContract = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
    }
    
    private let session = URLSession.shared
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    // Published properties for observable state
    @Published private(set) var portfolioValue: Double?
    @Published private(set) var positions: [Position]?
    @Published private(set) var cashBalance: Double?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    
    // Search state
    @Published private(set) var searchResults: [GammaEvent] = []
    @Published private(set) var hasMoreSearchResults: Bool = false
    @Published private(set) var isSearching: Bool = false
    
    private(set) var currentUserId: String?
    private var searchPage: Int = 1
    private var searchQuery: String = ""
    
    private init() {}
    
    // Helper method to make HTTP requests without caching
    private func makeRequest(
        url: URL,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, url: url)
        }
        return data
    }
    
    // MARK: - Public Methods
    
    func setUser(_ userId: String) {
        guard currentUserId != userId else { return }
        currentUserId = userId
        Task {
            await refreshAllData()
        }
    }
    
    func refreshAllData() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        error = nil

        // Run all three fetches concurrently
        async let portfolioTask: Double? = try? fetchPortfolio(userId: userId)
        async let positionsTask: [Position]? = try? fetchAllPositions(userId: userId)
        async let cashTask: Double? = try? fetchCashBalance(userId: userId)

        let (portfolio, positions, cash) = await (portfolioTask, positionsTask, cashTask)

        self.portfolioValue = portfolio
        self.positions = positions
        self.cashBalance = cash

        // Flag error if all fetches failed
        if portfolio == nil && positions == nil && cash == nil {
            self.error = URLError(.badServerResponse)
        }
        isLoading = false
    }

    /// Fetches all positions with automatic pagination
    func fetchAllPositions(userId: String, sizeThreshold: Double = 0.1) async throws -> [Position] {
        let pageSize = 50
        var allPositions: [Position] = []
        var offset = 0

        while true {
            let batch = try await fetchPositions(
                userId: userId,
                sizeThreshold: sizeThreshold,
                limit: pageSize,
                offset: offset
            )
            allPositions.append(contentsOf: batch)

            if batch.count < pageSize {
                break
            }
            offset += pageSize
        }

        return allPositions
    }
    
    func searchEvents(query: String, category: String = "all") async {
        guard !query.isEmpty else {
            searchResults = []
            hasMoreSearchResults = false
            return
        }
        
        isSearching = true
        searchPage = 1
        searchQuery = query
        
        do {
            let response = try await performSearch(query: query, category: category, page: searchPage)
            print("🔍 Search response: \(response.events.count) events, hasMore: \(response.hasMore)")
            searchResults = response.events.map { $0.toGammaEvent() }
            hasMoreSearchResults = response.hasMore
            print("🔍 Converted to GammaEvents: \(searchResults.count)")
        } catch {
            print("🔍 Search error: \(error)")
            self.error = error
        }
        
        isSearching = false
    }
    
    func loadMoreSearchResults() async {
        guard hasMoreSearchResults, !isSearching else { return }
        
        isSearching = true
        searchPage += 1
        
        do {
            let response = try await performSearch(query: searchQuery, page: searchPage)
            searchResults.append(contentsOf: response.events.map { $0.toGammaEvent() })
            hasMoreSearchResults = response.hasMore
        } catch {
            self.error = error
            searchPage -= 1
        }
        
        isSearching = false
    }

    func clearSearchResults() {
        searchResults = []
        hasMoreSearchResults = false
    }
    
    // MARK: - Fetch Methods
    
    func fetchPortfolio(userId: String) async throws -> Double {
        let url = URL(string: "\(API.dataAPI)/value?user=\(userId)")!
        let data = try await makeRequest(url: url)
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
              let first = json.first,
              let value = first["value"] as? Double else {
            throw URLError(.cannotParseResponse)
        }
        return value
    }
    
    func fetchPnL(userId: String, interval: PnLInterval = .max, fidelity: PnLFidelity? = .oneHour) async throws -> [PnLDataPoint] {
        let effectiveFidelity = fidelity ?? interval.defaultFidelity
        let url = URL(string: "\(API.pnlAPI)/user-pnl?user_address=\(userId)&interval=\(interval.rawValue)&fidelity=\(effectiveFidelity.rawValue)")!
        let data = try await makeRequest(url: url)
        
        guard let raw = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }
        
        return raw.compactMap { dict in
            guard let t = dict["t"] as? Int else { return nil }
            
            let p: Double
            if let num = dict["p"] as? Double {
                p = num
            } else if let str = dict["p"] as? String, let num = Double(str) {
                p = num
            } else {
                return nil
            }
            
            return PnLDataPoint(
                t: Date(timeIntervalSince1970: TimeInterval(t)),
                p: p
            )
        }
    }
    
    func fetchPositions(userId: String, sizeThreshold: Double = 0.1, limit: Int = 50, offset: Int = 0, sortBy: String = "CURRENT", sortDirection: String = "DESC") async throws -> [Position] {
        var components = URLComponents(string: "\(API.dataAPI)/positions")!
        components.queryItems = [
            .init(name: "user", value: userId),
            .init(name: "sizeThreshold", value: String(sizeThreshold)),
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
            .init(name: "sortBy", value: sortBy),
            .init(name: "sortDirection", value: sortDirection)
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let data = try await makeRequest(url: url)
        return try jsonDecoder.decode([Position].self, from: data)
    }
    
    func fetchCashBalance(userId: String) async throws -> Double {
        let url = URL(string: API.polygonRPC)!
        let contractAddress = API.usdcContract
        let methodId = "0x70a08231" // balanceOf(address)
        // ABI-encode: strip 0x prefix, left-pad address to 32 bytes (64 hex chars)
        let addressHex = userId.lowercased().hasPrefix("0x")
            ? String(userId.dropFirst(2))
            : userId
        let addressPadded = String(repeating: "0", count: max(0, 64 - addressHex.count)) + addressHex
        
        let callData = methodId + addressPadded
        
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_call",
            "params": [[
                "to": contractAddress,
                "data": callData
            ], "latest"]
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let responseData = try await makeRequest(url: url, method: "POST", body: bodyData)
        
        guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let resultHex = json["result"] as? String,
              resultHex.count > 2,
              let balance = UInt64(resultHex.dropFirst(2), radix: 16) else {
            throw URLError(.cannotParseResponse)
        }
        
        return Double(balance) / 1_000_000 // USDC has 6 decimals
    }
    
    func performSearch(query: String, category: String = "all", page: Int = 1) async throws -> SearchResponse {
        var components = URLComponents(string: "\(API.gammaAPI)/public-search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "events_status", value: "active"),
            URLQueryItem(name: "limit_per_type", value: "20"),
            URLQueryItem(name: "page", value: String(page))
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let data = try await makeRequest(url: url)
        let response = try jsonDecoder.decode(PublicSearchResponse.self, from: data)
        return SearchResponse(events: response.events, hasMore: response.pagination?.hasMore ?? false)
    }
    
    private struct PublicSearchResponse: Decodable {
        let events: [Event]
        let pagination: Pagination?
        
        struct Pagination: Decodable {
            let hasMore: Bool?
            let totalResults: Int?
        }
    }
    
    func fetchTags() async throws -> [Tag] {
        let url = URL(string: "\(API.searchAPI)/tags/filteredBySlug?tag=all&status=active")!
        let data = try await makeRequest(url: url)
        return try jsonDecoder.decode([Tag].self, from: data)
    }
    
    func fetchPaginatedEvents(
        limit: Int = 20,
        active: Bool = true,
        archived: Bool = false,
        closed: Bool = false,
        order: String = "volume24hr",
        ascending: Bool = false,
        offset: Int = 0,
        tagSlug: String? = nil
    ) async throws -> PaginatedEventsResponse {
        var components = URLComponents(string: "\(API.gammaAPI)/events/pagination")!
        var queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "active", value: String(active)),
            URLQueryItem(name: "archived", value: String(archived)),
            URLQueryItem(name: "closed", value: String(closed)),
            URLQueryItem(name: "order", value: order),
            URLQueryItem(name: "ascending", value: String(ascending)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        
        if let tagSlug = tagSlug, tagSlug != "all" {
            queryItems.append(URLQueryItem(name: "tag_slug", value: tagSlug))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let data = try await makeRequest(url: url)
        return try jsonDecoder.decode(PaginatedEventsResponse.self, from: data)
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case httpError(statusCode: Int, url: URL)
    
    var errorDescription: String? {
        switch self {
        case .httpError(let statusCode, let url):
            return "HTTP \(statusCode) from \(url.host ?? url.absoluteString)"
        }
    }
}

// MARK: - Supporting Types

extension PolymarketDataService {
    enum PnLInterval: String {
        case max = "max"
        case month = "1m"
        case week = "1w"
        case day = "1d"
        case twelveHours = "12h"
        case sixHours = "6h"
        
        var defaultFidelity: PnLFidelity {
            switch self {
            case .max: return .twelveHours
            case .month: return .threeHours
            case .week: return .threeHours
            case .day, .twelveHours, .sixHours: return .oneHour
            }
        }
    }
    
    enum PnLFidelity: String {
        case day = "1d"
        case eighteenHours = "18h"
        case twelveHours = "12h"
        case threeHours = "3h"
        case oneHour = "1h"
    }
    
    enum PnLRange: String, CaseIterable {
        case today = "today"
        case day = "1d"
        case week = "1w"
        case month = "1m"
        case max = "max"
        
        var interval: PnLInterval {
            switch self {
            case .max: return .max
            case .month: return .month
            case .week: return .week
            case .day: return .day
            case .today: return .day
            }
        }
        
        var label: String {
            switch self {
            case .max: return "All"
            case .month: return "1M"
            case .week: return "1W"
            case .day: return "1D"
            case .today: return "Today"
            }
        }
    }
    
    struct PnLDataPoint: Decodable, Equatable {
        var t: Date
        var p: Double
    }
    
    struct Position: Decodable {
        let proxyWallet: String
        let asset: String
        let conditionId: String
        let size: Double
        let avgPrice: Double
        let initialValue: Double
        let currentValue: Double
        let cashPnl: Double
        let percentPnl: Double
        let totalBought: Double
        let realizedPnl: Double
        let percentRealizedPnl: Double
        let curPrice: Double
        let redeemable: Bool
        let mergeable: Bool
        let title: String
        let slug: String
        let icon: String
        let eventSlug: String
        let outcome: String
        let outcomeIndex: Int
        let oppositeOutcome: String
        let oppositeAsset: String
        let endDate: String
        let negativeRisk: Bool
    }
    
    struct SearchResponse {
        let events: [Event]
        let hasMore: Bool
    }
    
    struct SearchMarket: Decodable {
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
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            slug = try container.decode(String.self, forKey: .slug)
            question = try container.decodeIfPresent(String.self, forKey: .question)
            groupItemTitle = try container.decodeIfPresent(String.self, forKey: .groupItemTitle)
            lastTradePrice = try container.decodeIfPresent(Double.self, forKey: .lastTradePrice)
            bestAsk = try container.decodeIfPresent(Double.self, forKey: .bestAsk)
            bestBid = try container.decodeIfPresent(Double.self, forKey: .bestBid)
            spread = try container.decodeIfPresent(Double.self, forKey: .spread)
            closed = try container.decodeIfPresent(Bool.self, forKey: .closed)
            archived = try container.decodeIfPresent(Bool.self, forKey: .archived)
            
            // Gamma API returns outcomes/outcomePrices as JSON strings, not arrays
            if let arr = try? container.decode([String].self, forKey: .outcomes) {
                outcomes = arr
            } else {
                let str = try container.decode(String.self, forKey: .outcomes)
                outcomes = (try? JSONDecoder().decode([String].self, from: Data(str.utf8))) ?? []
            }
            if let arr = try? container.decode([String].self, forKey: .outcomePrices) {
                outcomePrices = arr
            } else if let str = try? container.decode(String.self, forKey: .outcomePrices) {
                outcomePrices = (try? JSONDecoder().decode([String].self, from: Data(str.utf8))) ?? []
            } else {
                outcomePrices = []
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            case slug, question, groupItemTitle, outcomes, outcomePrices
            case lastTradePrice, bestAsk, bestBid, spread, closed, archived
        }
    }
    
    struct Event: Decodable {
        let id: String
        let title: String
        let slug: String
        let description: String?
        let image: String?
        let endDate: String?
        let volume: Double?
        let liquidity: Double?
        let markets: [SearchMarket]
        
        /// Convert search Event to GammaEvent for UI consistency
        func toGammaEvent() -> GammaEvent {
            let convertedMarkets = markets.map { market in
                GammaMarket(
                    id: market.slug,
                    question: market.question ?? "",
                    conditionId: market.slug,
                    slug: market.slug,
                    endDate: endDate,
                    image: image,
                    description: description,
                    outcomes: (try? String(data: JSONEncoder().encode(market.outcomes), encoding: .utf8)),
                    outcomePrices: (try? String(data: JSONEncoder().encode(market.outcomePrices), encoding: .utf8)),
                    active: true,
                    closed: market.closed,
                    archived: market.archived,
                    groupItemTitle: market.groupItemTitle,
                    spread: market.spread,
                    lastTradePrice: market.lastTradePrice,
                    bestBid: market.bestBid,
                    bestAsk: market.bestAsk
                )
            }

            return GammaEvent(
                id: id,
                ticker: slug,
                slug: slug,
                title: title,
                description: description,
                endDate: endDate,
                image: image,
                active: true,
                liquidity: liquidity,
                volume: volume,
                markets: convertedMarkets
            )
        }
    }
    
    struct Tag: Decodable {
        let id: String
        let label: String
        let slug: String
        let forceShow: Bool?
        let forceHide: Bool?
        let createdAt: String?
        let updatedAt: String?
    }
    
    struct PaginatedEventsResponse: Decodable {
        let data: [GammaEvent]
        let pagination: Pagination
    }
    
    struct Pagination: Decodable {
        let hasMore: Bool
    }
    
    struct GammaEvent: Decodable {
        var id: String
        var ticker: String
        var slug: String
        var title: String
        var description: String? = nil
        var resolutionSource: String? = nil
        var startDate: String? = nil
        var creationDate: String? = nil
        var endDate: String? = nil
        var image: String? = nil
        var icon: String? = nil
        var active: Bool? = nil
        var closed: Bool? = nil
        var archived: Bool? = nil
        var new: Bool? = nil
        var featured: Bool? = nil
        var restricted: Bool? = nil
        var liquidity: Double? = nil
        var volume: Double? = nil
        var openInterest: Double? = nil
        var sortBy: String? = nil
        var createdAt: String? = nil
        var updatedAt: String? = nil
        var competitive: Double? = nil
        var volume24hr: Double? = nil
        var volume1wk: Double? = nil
        var volume1mo: Double? = nil
        var volume1yr: Double? = nil
        var enableOrderBook: Bool? = nil
        var liquidityClob: Double? = nil
        var negRisk: Bool? = nil
        var negRiskMarketID: String? = nil
        var commentCount: Int? = nil
        var markets: [GammaMarket] = []
        var series: [GammaSeries]? = nil
        var tags: [Tag]? = nil
        var cyom: Bool? = nil
        var showAllOutcomes: Bool? = nil
        var showMarketImages: Bool? = nil
        var enableNegRisk: Bool? = nil
        var automaticallyActive: Bool? = nil
        var seriesSlug: String? = nil
        var negRiskAugmented: Bool? = nil
        var pendingDeployment: Bool? = nil
        var deploying: Bool? = nil
    }
    
    struct GammaMarket: Decodable {
        var id: String
        var question: String
        var conditionId: String
        var slug: String
        var resolutionSource: String? = nil
        var endDate: String? = nil
        var liquidity: String? = nil
        var startDate: String? = nil
        var image: String? = nil
        var icon: String? = nil
        var description: String? = nil
        var outcomes: String? = nil
        var outcomePrices: String? = nil
        var volume: String? = nil
        var active: Bool? = nil
        var closed: Bool? = nil
        var marketMakerAddress: String? = nil
        var createdAt: String? = nil
        var updatedAt: String? = nil
        var new: Bool? = nil
        var featured: Bool? = nil
        var submittedBy: String? = nil
        var archived: Bool? = nil
        var resolvedBy: String? = nil
        var restricted: Bool? = nil
        var groupItemTitle: String? = nil
        var groupItemThreshold: String? = nil
        var questionID: String? = nil
        var enableOrderBook: Bool? = nil
        var orderPriceMinTickSize: Double? = nil
        var orderMinSize: Double? = nil
        var volumeNum: Double? = nil
        var liquidityNum: Double? = nil
        var endDateIso: String? = nil
        var startDateIso: String? = nil
        var hasReviewedDates: Bool? = nil
        var volume1wk: Double? = nil
        var volume1mo: Double? = nil
        var volume1yr: Double? = nil
        var clobTokenIds: String? = nil
        var umaBond: String? = nil
        var umaReward: String? = nil
        var volume1wkClob: Double? = nil
        var volume1moClob: Double? = nil
        var volume1yrClob: Double? = nil
        var volumeClob: Double? = nil
        var liquidityClob: Double? = nil
        var acceptingOrders: Bool? = nil
        var negRisk: Bool? = nil
        var negRiskMarketID: String? = nil
        var negRiskRequestID: String? = nil
        var ready: Bool? = nil
        var funded: Bool? = nil
        var acceptingOrdersTimestamp: String? = nil
        var cyom: Bool? = nil
        var competitive: Double? = nil
        var pagerDutyNotificationEnabled: Bool? = nil
        var approved: Bool? = nil
        var clobRewards: [ClobReward]? = nil
        var rewardsMinSize: Double? = nil
        var rewardsMaxSpread: Double? = nil
        var spread: Double? = nil
        var oneDayPriceChange: Double? = nil
        var oneHourPriceChange: Double? = nil
        var oneWeekPriceChange: Double? = nil
        var lastTradePrice: Double? = nil
        var bestBid: Double? = nil
        var bestAsk: Double? = nil
        var automaticallyActive: Bool? = nil
        var clearBookOnStart: Bool? = nil
        var manualActivation: Bool? = nil
        var negRiskOther: Bool? = nil
        var umaResolutionStatuses: String? = nil
        var pendingDeployment: Bool? = nil
        var deploying: Bool? = nil
    }
    
    struct GammaSeries: Decodable {
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
    
    struct ClobReward: Decodable {
        let id: String?
        let conditionId: String?
        let assetAddress: String?
        let rewardsAmount: Double?
        let rewardsDailyRate: Double?
        let startDate: String?
        let endDate: String?
    }
}
