import Foundation
import Combine

@MainActor
class PortfolioService: ObservableObject {
    @Published private(set) var portfolioValue: Double?
    @Published private(set) var positions: [PolymarketModels.Position]?
    @Published private(set) var cashBalance: Double?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    
    private let portfolioAPI: PortfolioAPIProtocol
    private let cacheManager: CacheManagerProtocol
    
    nonisolated init(portfolioAPI: PortfolioAPIProtocol = PortfolioAPI(), 
         cacheManager: CacheManagerProtocol = CacheManager()) {
        self.portfolioAPI = portfolioAPI
        self.cacheManager = cacheManager
    }
    
    func fetchPortfolioValue(userId: String, useCache: Bool = true) async -> Double? {
        let cacheKey = CacheManager.CacheKey.portfolioValue(userId: userId)
        
        // Return cached value if available and not expired
        if useCache, let cached = cacheManager.get(cacheKey, type: Double.self) {
            self.portfolioValue = cached
            return cached
        }
        
        do {
            let value = try await portfolioAPI.fetchPortfolioValue(userId: userId)
            self.portfolioValue = value
            
            // Cache the result
            cacheManager.set(cacheKey, value: value, expiration: CacheManager.portfolioExpiration)
            
            return value
        } catch {
            self.error = error
            self.portfolioValue = nil
            return nil
        }
    }
    
    func fetchPositions(userId: String, useCache: Bool = true) async -> [PolymarketModels.Position]? {
        let cacheKey = CacheManager.CacheKey.positions(userId: userId)
        
        // Return cached value if available and not expired
        if useCache, let cached = cacheManager.get(cacheKey, type: [PolymarketModels.Position].self) {
            self.positions = cached
            return cached
        }
        
        do {
            let positions = try await portfolioAPI.fetchPositions(
                userId: userId,
                sizeThreshold: 0.1,
                limit: 50,
                offset: 0,
                sortBy: "CURRENT",
                sortDirection: "DESC"
            )
            self.positions = positions
            
            // Cache the result
            cacheManager.set(cacheKey, value: positions, expiration: CacheManager.portfolioExpiration)
            
            return positions
        } catch {
            self.error = error
            self.positions = nil
            return nil
        }
    }
    
    func fetchCashBalance(userId: String, useCache: Bool = true) async -> Double? {
        let cacheKey = CacheManager.CacheKey.cashBalance(userId: userId)
        
        // Return cached value if available and not expired
        if useCache, let cached = cacheManager.get(cacheKey, type: Double.self) {
            self.cashBalance = cached
            return cached
        }
        
        do {
            let balance = try await portfolioAPI.fetchCashBalance(userId: userId)
            self.cashBalance = balance
            
            // Cache the result
            cacheManager.set(cacheKey, value: balance, expiration: CacheManager.portfolioExpiration)
            
            return balance
        } catch {
            self.error = error
            self.cashBalance = nil
            return nil
        }
    }
    
    func refreshAllData(userId: String) async {
        isLoading = true
        error = nil
        
        var firstError: Error?
        
        // Fetch portfolio value
        if await fetchPortfolioValue(userId: userId, useCache: false) == nil {
            if let apiError = error, firstError == nil {
                firstError = apiError
            }
        }
        
        // Fetch positions
        if await fetchPositions(userId: userId, useCache: false) == nil {
            if let apiError = error, firstError == nil {
                firstError = apiError
            }
        }
        
        // Fetch cash balance
        if await fetchCashBalance(userId: userId, useCache: false) == nil {
            if let apiError = error, firstError == nil {
                firstError = apiError
            }
        }
        
        self.error = firstError
        isLoading = false
    }
    
    func clearCache(userId: String) {
        cacheManager.remove(CacheManager.CacheKey.portfolioValue(userId: userId))
        cacheManager.remove(CacheManager.CacheKey.positions(userId: userId))
        cacheManager.remove(CacheManager.CacheKey.cashBalance(userId: userId))
    }
}