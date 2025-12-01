import Foundation

protocol PnLAPIProtocol {
    func fetchPnL(userId: String, interval: PolymarketModels.PnLInterval, fidelity: PolymarketModels.PnLFidelity?) async throws -> [PolymarketModels.PnLDataPoint]
}

class PnLAPI: PnLAPIProtocol {
    private let apiClient: APIClientProtocol
    private let baseURL = "https://user-pnl-api.polymarket.com"
    
    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }
    
    func fetchPnL(userId: String, interval: PolymarketModels.PnLInterval = .max, fidelity: PolymarketModels.PnLFidelity? = .oneHour) async throws -> [PolymarketModels.PnLDataPoint] {
        let effectiveFidelity = fidelity ?? interval.defaultFidelity
        
        guard let url = URL(string: "\(baseURL)/user-pnl?user_address=\(userId)&interval=\(interval.rawValue)&fidelity=\(effectiveFidelity.rawValue)") else {
            throw APIError.invalidURL
        }
        
        let jsonArray: [[String: Any]] = try await apiClient.requestJSON(url: url, method: .GET, headers: [:], body: nil) as! [[String: Any]]
        
        return jsonArray.compactMap { dict in
            guard let t = dict["t"] as? Int else { return nil }
            
            let p: Double
            if let num = dict["p"] as? Double {
                p = num
            } else if let str = dict["p"] as? String, let num = Double(str) {
                p = num
            } else {
                return nil
            }
            
            return PolymarketModels.PnLDataPoint(
                t: Date(timeIntervalSince1970: TimeInterval(t)),
                p: p
            )
        }
    }
}