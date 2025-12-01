import Foundation

protocol PortfolioRepositoryProtocol {
    func getPortfolioValue(userId: String) async -> Double?
    func getPositions(userId: String) async -> [PolymarketModels.Position]?
    func getCashBalance(userId: String) async -> Double?
    func refreshPortfolioData(userId: String) async
    func clearCache(userId: String)
    
    var currentPortfolioValue: Double? { get }
    var currentPositions: [PolymarketModels.Position]? { get }
    var currentCashBalance: Double? { get }
    var isLoading: Bool { get }
    var error: Error? { get }
}

@MainActor
class PortfolioRepository: PortfolioRepositoryProtocol {
    private let portfolioService: PortfolioService
    
    nonisolated init(portfolioService: PortfolioService = PortfolioService()) {
        self.portfolioService = portfolioService
    }
    
    func getPortfolioValue(userId: String) async -> Double? {
        return await portfolioService.fetchPortfolioValue(userId: userId)
    }
    
    func getPositions(userId: String) async -> [PolymarketModels.Position]? {
        return await portfolioService.fetchPositions(userId: userId)
    }
    
    func getCashBalance(userId: String) async -> Double? {
        return await portfolioService.fetchCashBalance(userId: userId)
    }
    
    func refreshPortfolioData(userId: String) async {
        await portfolioService.refreshAllData(userId: userId)
    }
    
    func clearCache(userId: String) {
        portfolioService.clearCache(userId: userId)
    }
    
    // Convenience methods for getting current state
    var currentPortfolioValue: Double? {
        portfolioService.portfolioValue
    }
    
    var currentPositions: [PolymarketModels.Position]? {
        portfolioService.positions
    }
    
    var currentCashBalance: Double? {
        portfolioService.cashBalance
    }
    
    var isLoading: Bool {
        portfolioService.isLoading
    }
    
    var error: Error? {
        portfolioService.error
    }
}