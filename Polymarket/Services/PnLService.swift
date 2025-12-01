import Foundation
import Combine

@MainActor
class PnLService: ObservableObject {
    @Published private(set) var pnlData: [PolymarketModels.PnLDataPoint] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    
    private let pnlAPI: PnLAPIProtocol
    private let cacheManager: CacheManagerProtocol
    
    nonisolated init(pnlAPI: PnLAPIProtocol = PnLAPI(), 
         cacheManager: CacheManagerProtocol = CacheManager()) {
        self.pnlAPI = pnlAPI
        self.cacheManager = cacheManager
    }
    
    func fetchPnL(
        userId: String,
        interval: PolymarketModels.PnLInterval = .max,
        fidelity: PolymarketModels.PnLFidelity? = .oneHour,
        useCache: Bool = true
    ) async -> [PolymarketModels.PnLDataPoint] {
        let cacheKey = CacheManager.CacheKey.pnl(userId: userId, interval: interval, fidelity: fidelity)
        
        // Return cached value if available and not expired
        if useCache, let cached = cacheManager.get(cacheKey, type: [PolymarketModels.PnLDataPoint].self) {
            self.pnlData = cached
            return cached
        }
        
        isLoading = true
        error = nil
        
        do {
            let data = try await pnlAPI.fetchPnL(userId: userId, interval: interval, fidelity: fidelity)
            self.pnlData = data
            
            // Cache the result
            cacheManager.set(cacheKey, value: data, expiration: CacheManager.pnlExpiration)
            
            isLoading = false
            return data
        } catch {
            self.error = error
            self.pnlData = []
            isLoading = false
            return []
        }
    }
    
    func clearCache(userId: String) {
        // Clear all PnL cache entries for this user
        for interval in [PolymarketModels.PnLInterval.max, .month, .week, .day, .twelveHours, .sixHours] {
            for fidelity in [PolymarketModels.PnLFidelity.day, .eighteenHours, .twelveHours, .threeHours, .oneHour] {
                let cacheKey = CacheManager.CacheKey.pnl(userId: userId, interval: interval, fidelity: fidelity)
                cacheManager.remove(cacheKey)
            }
        }
    }
    
    // Helper method to get today's PnL change
    func getTodaysPnLChange(userId: String) async -> Double? {
        let data = await fetchPnL(userId: userId, interval: .day, fidelity: .oneHour)
        
        guard let firstPoint = data.first,
              let lastPoint = data.last else {
            return nil
        }
        
        return lastPoint.p - firstPoint.p
    }
    
    // Helper method to get PnL change for a specific range
    func getPnLChange(userId: String, range: PolymarketModels.PnLRange) async -> Double? {
        let data = await fetchPnL(userId: userId, interval: range.interval, fidelity: range.interval.defaultFidelity)
        
        guard let firstPoint = data.first,
              let lastPoint = data.last else {
            return nil
        }
        
        return lastPoint.p - firstPoint.p
    }
}