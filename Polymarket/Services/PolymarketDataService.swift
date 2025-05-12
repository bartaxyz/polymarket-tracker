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
    private let cache = NSCache<NSString, CacheEntry>()
    private static let cacheDuration: TimeInterval = 300 // 5 minutes
    
    // Published properties for observable state
    @Published private(set) var portfolioValue: Double?
    @Published private(set) var pnlData: [PnLDataPoint]?
    @Published private(set) var positions: [Position]?
    @Published private(set) var cashBalance: Double?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    
    // Search state
    @Published private(set) var searchResults: [Event] = []
    @Published private(set) var hasMoreSearchResults: Bool = false
    @Published private(set) var isSearching: Bool = false
    
    private var currentUserId: String?
    private var searchPage: Int = 1
    private var searchQuery: String = ""
    
    private init() {}
    
    class CacheEntry {
        let data: Data
        let timestamp: Date
        
        init(data: Data) {
            self.data = data
            self.timestamp = Date()
        }
        
        var isValid: Bool {
            return Date().timeIntervalSince(timestamp) < PolymarketDataService.cacheDuration
        }
    }
    
    // Method to invalidate all cached data
    func invalidateCache() {
        cache.removeAllObjects()
    }
    
    // Helper method to make HTTP requests with caching
    private func makeRequest(
        url: URL,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> Data {
        let cacheKey = url.absoluteString as NSString
        
        // Only check cache for GET requests
        if method == "GET" {
            if let cachedEntry = cache.object(forKey: cacheKey), cachedEntry.isValid {
                return cachedEntry.data
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        // Add default headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add custom headers
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // Only cache GET requests
        if method == "GET" {
            let cacheEntry = CacheEntry(data: data)
            cache.setObject(cacheEntry, forKey: cacheKey)
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
        
        do {
            async let portfolioTask = fetchPortfolio(userId: userId)
            async let pnlTask = fetchPnL(userId: userId)
            async let positionsTask = fetchPositions(userId: userId)
            async let cashBalanceTask = fetchCashBalance(userId: userId)
            
            let (portfolio, pnl, positions, cash) = try await (portfolioTask, pnlTask, positionsTask, cashBalanceTask)
            
            self.portfolioValue = portfolio
            self.pnlData = pnl
            self.positions = positions
            self.cashBalance = cash
        } catch {
            self.error = error
        }
        
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
    
    func fetchPnL(userId: String, interval: PnLInterval = .day, fidelity: PnLFidelity? = nil) async throws -> [PnLDataPoint] {
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
            URLQueryItem(name: "user", value: userId),
            URLQueryItem(name: "sizeThreshold", value: String(sizeThreshold)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "sortBy", value: sortBy),
            URLQueryItem(name: "sortDirection", value: sortDirection)
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
}
