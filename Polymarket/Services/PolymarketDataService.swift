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
    
    // New architecture services
    private let portfolioRepository: PortfolioRepositoryProtocol
    private let eventRepository: EventRepositoryProtocol
    private let pnlRepository: PnLRepositoryProtocol
    
    // Published properties for observable state
    @Published private(set) var portfolioValue: Double?
    @Published private(set) var positions: [PolymarketModels.Position]?
    @Published private(set) var cashBalance: Double?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    
    // Search state
    @Published private(set) var searchResults: [PolymarketModels.GammaEvent] = []
    @Published private(set) var hasMoreSearchResults: Bool = false
    @Published private(set) var isSearching: Bool = false
    
    private(set) var currentUserId: String?
    private var searchPage: Int = 1
    private var searchQuery: String = ""
    
    nonisolated private init(portfolioRepository: PortfolioRepositoryProtocol = PortfolioRepository(),
                             eventRepository: EventRepositoryProtocol = EventRepository(),
                             pnlRepository: PnLRepositoryProtocol = PnLRepository()) {
        self.portfolioRepository = portfolioRepository
        self.eventRepository = eventRepository
        self.pnlRepository = pnlRepository
    }
    
    // MARK: - Legacy HTTP method kept for any remaining direct usage
    private func makeRequest(
        url: URL,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> Data {
        let apiClient = APIClient()
        return try await apiClient.requestData(
            url: url,
            method: HTTPMethod(rawValue: method) ?? .GET,
            headers: headers,
            body: body
        )
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

        // Use the new repository to refresh data
        await portfolioRepository.refreshPortfolioData(userId: userId)
        
        // Update published properties from repository
        self.portfolioValue = portfolioRepository.currentPortfolioValue
        self.positions = portfolioRepository.currentPositions
        self.cashBalance = portfolioRepository.currentCashBalance
        self.error = portfolioRepository.error
        
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
        
        // Use the new repository for search
        searchResults = await eventRepository.searchEvents(query: query, category: category)
        hasMoreSearchResults = eventRepository.hasMoreSearchResults
        
        print("🔍 Search completed: \(searchResults.count) events, hasMore: \(hasMoreSearchResults)")
        
        isSearching = false
    }
    
    func loadMoreSearchResults() async {
        guard hasMoreSearchResults, !isSearching else { return }
        
        isSearching = true
        searchPage += 1
        
        // Use the new repository for loading more results
        searchResults = await eventRepository.loadMoreSearchResults()
        hasMoreSearchResults = eventRepository.hasMoreSearchResults
        
        isSearching = false
    }

    func clearSearchResults() {
        eventRepository.clearSearchResults()
        searchResults = []
        hasMoreSearchResults = false
    }
    
    // MARK: - Fetch Methods
    
    func fetchPortfolio(userId: String) async throws -> Double {
        guard let value = await portfolioRepository.getPortfolioValue(userId: userId) else {
            throw APIError.noData
        }
        return value
    }
    
    func fetchPnL(userId: String, interval: PolymarketModels.PnLInterval = .max, fidelity: PolymarketModels.PnLFidelity? = .oneHour) async throws -> [PolymarketModels.PnLDataPoint] {
        return await pnlRepository.getPnLData(userId: userId, interval: interval, fidelity: fidelity)
    }
    
    func fetchPositions(userId: String, sizeThreshold: Double = 0.1, limit: Int = 50, offset: Int = 0, sortBy: String = "CURRENT", sortDirection: String = "DESC") async throws -> [PolymarketModels.Position] {
        guard let positions = await portfolioRepository.getPositions(userId: userId) else {
            throw APIError.noData
        }
        return positions
    }
    
    func fetchCashBalance(userId: String) async throws -> Double {
        guard let balance = await portfolioRepository.getCashBalance(userId: userId) else {
            throw APIError.noData
        }
        return balance
    }
    
    func performSearch(query: String, category: String = "all", page: Int = 1) async throws -> PolymarketModels.SearchResponse {
        // This method is kept for legacy compatibility
        let searchAPI = SearchAPI()
        return try await searchAPI.searchEvents(query: query, category: category, page: page)
    }
    
    func fetchTags() async throws -> [PolymarketModels.Tag] {
        // This method is kept for legacy compatibility
        return await eventRepository.getTags()
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
    ) async throws -> PolymarketModels.GammaResponse {
        // This method is kept for legacy compatibility
        let tags = tagSlug.map { [$0] } ?? []
        let page = (offset / limit) + 1
        let gammaAPI = GammaAPI()
        return try await gammaAPI.fetchEvents(page: page, limit: limit, tags: tags)
    }
}

