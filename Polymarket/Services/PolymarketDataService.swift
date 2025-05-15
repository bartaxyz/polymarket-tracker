//
//  PolymarketDataService.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import Foundation
import Combine

@MainActor
class PolymarketDataService: ObservableObject {
    static let shared = PolymarketDataService()
    
    private let session = URLSession.shared
    
    // Published properties for observable state
    @Published private(set) var portfolioValue: Double?
    @Published private(set) var positions: [Position]?
    @Published private(set) var cashBalance: Double?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    
    // Search state
    @Published private(set) var searchResults: [Event] = []
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
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            return data
        } catch {
            // Handle task cancellation gracefully
            if let urlError = error as? URLError, urlError.code == .cancelled {
                print("Request cancelled: \(url.absoluteString)")
            }
            throw error
        }
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

        var firstError: Error? = nil

        do {
            self.portfolioValue = try await fetchPortfolio(userId: userId)
        } catch {
            if firstError == nil { firstError = error }
            self.portfolioValue = nil
        }

        do {
            self.positions = try await fetchPositions(userId: userId)
        } catch {
            if firstError == nil { firstError = error }
            self.positions = nil
        }

        do {
            self.cashBalance = try await fetchCashBalance(userId: userId)
        } catch {
            if firstError == nil { firstError = error }
            self.cashBalance = nil
        }

        self.error = firstError
        isLoading = false
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
            searchResults = response.events
            hasMoreSearchResults = response.hasMore
        } catch {
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
            searchResults.append(contentsOf: response.events)
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
        let url = URL(string: "https://data-api.polymarket.com/value?user=\(userId)")!
        let data = try await makeRequest(url: url)
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]
        return (json.first?["value"] as? Double) ?? 0.0
    }
    
    func fetchPnL(userId: String, interval: PnLInterval = .max, fidelity: PnLFidelity? = .oneHour) async throws -> [PnLDataPoint] {
        let effectiveFidelity = fidelity ?? interval.defaultFidelity
        let url = URL(string: "https://user-pnl-api.polymarket.com/user-pnl?user_address=\(userId)&interval=\(interval.rawValue)&fidelity=\(effectiveFidelity.rawValue)")!
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
        var components = URLComponents(string: "https://data-api.polymarket.com/positions")!
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
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([Position].self, from: data)
    }
    
    func fetchCashBalance(userId: String) async throws -> Double {
        let url = URL(string: "https://polygon-rpc.com")!
        let contractAddress = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
        let methodId = "0x70a08231" // balanceOf(address)
        let addressPadded = userId // .lowercased().replacingOccurrences(of: "0x", with: "").leftPadding(toLength: 64, withPad: "0")
        
        let data = methodId + addressPadded
        
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_call",
            "params": [[
                "to": contractAddress,
                "data": data
            ], "latest"]
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let responseData = try await makeRequest(url: url, method: "POST", body: bodyData)
        
        let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
        guard let resultHex = json?["result"] as? String,
              let balance = UInt64(resultHex.dropFirst(2), radix: 16) else {
            throw URLError(.badServerResponse)
        }
        
        return Double(balance) / 1_000_000 // USDC has 6 decimals
    }
    
    func performSearch(query: String, category: String = "all", page: Int = 1) async throws -> SearchResponse {
        var components = URLComponents(string: "https://polymarket.com/api/events/search")!
        components.queryItems = [
            URLQueryItem(name: "_c", value: category),
            URLQueryItem(name: "_q", value: query),
            URLQueryItem(name: "_p", value: String(page))
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let data = try await makeRequest(url: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(SearchResponse.self, from: data)
    }
    
    func fetchTags() async throws -> [Tag] {
        let url = URL(string: "https://polymarket.com/api/tags/filteredBySlug?tag=all&status=active")!
        let data = try await makeRequest(url: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([Tag].self, from: data)
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
        var components = URLComponents(string: "https://gamma-api.polymarket.com/events/pagination")!
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
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PaginatedEventsResponse.self, from: data)
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
    
    struct SearchResponse: Decodable {
        let events: [Event]
        let hasMore: Bool
    }
    
    struct Event: Decodable {
        let id: String
        let title: String
        let slug: String
        let description: String?
        let imageUrl: String?
        let endDate: String?
        let volume: Double?
        let liquidity: Double?
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
    
    struct GammaMarket: Decodable {
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
