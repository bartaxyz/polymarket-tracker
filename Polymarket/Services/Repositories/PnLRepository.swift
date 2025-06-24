import Foundation

protocol PnLRepositoryProtocol {
    func getPnLData(userId: String, interval: PolymarketModels.PnLInterval, fidelity: PolymarketModels.PnLFidelity?) async -> [PolymarketModels.PnLDataPoint]
    func getTodaysPnLChange(userId: String) async -> Double?
    func getPnLChange(userId: String, range: PolymarketModels.PnLRange) async -> Double?
    func clearCache(userId: String)
}

@MainActor
class PnLRepository: PnLRepositoryProtocol {
    private let pnlService: PnLService
    
    nonisolated init(pnlService: PnLService = PnLService()) {
        self.pnlService = pnlService
    }
    
    func getPnLData(
        userId: String,
        interval: PolymarketModels.PnLInterval = .max,
        fidelity: PolymarketModels.PnLFidelity? = .oneHour
    ) async -> [PolymarketModels.PnLDataPoint] {
        return await pnlService.fetchPnL(userId: userId, interval: interval, fidelity: fidelity)
    }
    
    func getTodaysPnLChange(userId: String) async -> Double? {
        return await pnlService.getTodaysPnLChange(userId: userId)
    }
    
    func getPnLChange(userId: String, range: PolymarketModels.PnLRange) async -> Double? {
        return await pnlService.getPnLChange(userId: userId, range: range)
    }
    
    func clearCache(userId: String) {
        pnlService.clearCache(userId: userId)
    }
    
    // Convenience methods for getting current state
    var currentPnLData: [PolymarketModels.PnLDataPoint] {
        pnlService.pnlData
    }
    
    var isLoading: Bool {
        pnlService.isLoading
    }
    
    var error: Error? {
        pnlService.error
    }
    
    // Helper methods for common PnL calculations
    func getCurrentValue(from data: [PolymarketModels.PnLDataPoint]) -> Double? {
        return data.last?.p
    }
    
    func getInitialValue(from data: [PolymarketModels.PnLDataPoint]) -> Double? {
        return data.first?.p
    }
    
    func getTotalChange(from data: [PolymarketModels.PnLDataPoint]) -> Double? {
        guard let initial = getInitialValue(from: data),
              let current = getCurrentValue(from: data) else {
            return nil
        }
        return current - initial
    }
    
    func getPercentageChange(from data: [PolymarketModels.PnLDataPoint]) -> Double? {
        guard let initial = getInitialValue(from: data),
              let change = getTotalChange(from: data),
              initial != 0 else {
            return nil
        }
        return (change / initial) * 100
    }
    
    // Get data points within a specific time range
    func getDataPoints(from data: [PolymarketModels.PnLDataPoint], 
                      startDate: Date, 
                      endDate: Date) -> [PolymarketModels.PnLDataPoint] {
        return data.filter { dataPoint in
            dataPoint.t >= startDate && dataPoint.t <= endDate
        }
    }
    
    // Get maximum value in data set
    func getMaxValue(from data: [PolymarketModels.PnLDataPoint]) -> Double? {
        return data.map { $0.p }.max()
    }
    
    // Get minimum value in data set
    func getMinValue(from data: [PolymarketModels.PnLDataPoint]) -> Double? {
        return data.map { $0.p }.min()
    }
    
    // Get data formatted for chart display
    func getChartData(from data: [PolymarketModels.PnLDataPoint]) -> [(Date, Double)] {
        return data.map { ($0.t, $0.p) }
    }
}