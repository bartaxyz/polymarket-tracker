import Foundation

@MainActor
class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    // Core services
    private let _portfolioRepository: PortfolioRepositoryProtocol
    private let _eventRepository: EventRepositoryProtocol
    private let _pnlRepository: PnLRepositoryProtocol
    
    var portfolioRepository: PortfolioRepositoryProtocol {
        return _portfolioRepository
    }
    
    var eventRepository: EventRepositoryProtocol {
        return _eventRepository
    }
    
    var pnlRepository: PnLRepositoryProtocol {
        return _pnlRepository
    }
    
    private init() {
        // Initialize with default implementations
        self._portfolioRepository = PortfolioRepository()
        self._eventRepository = EventRepository()
        self._pnlRepository = PnLRepository()
    }
    
    // Convenience methods that delegate to the legacy PolymarketDataService
    // This allows widgets to work without major changes
    func fetchPortfolio(userId: String) async throws -> Double {
        guard let value = await portfolioRepository.getPortfolioValue(userId: userId) else {
            throw APIError.noData
        }
        return value
    }
    
    func fetchPnL(userId: String, interval: PolymarketModels.PnLInterval = .max, fidelity: PolymarketModels.PnLFidelity? = .oneHour) async throws -> [PolymarketModels.PnLDataPoint] {
        return await pnlRepository.getPnLData(userId: userId, interval: interval, fidelity: fidelity)
    }
    
    func fetchPositions(userId: String) async throws -> [PolymarketModels.Position] {
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
}