import Foundation

protocol PortfolioAPIProtocol {
    func fetchPortfolioValue(userId: String) async throws -> Double
    func fetchPositions(userId: String, sizeThreshold: Double, limit: Int, offset: Int, sortBy: String, sortDirection: String) async throws -> [PolymarketModels.Position]
    func fetchCashBalance(userId: String) async throws -> Double
}

class PortfolioAPI: PortfolioAPIProtocol {
    private let apiClient: APIClientProtocol
    private let baseURL = "https://data-api.polymarket.com"
    private let polygonRPCURL = "https://polygon-rpc.com"
    
    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }
    
    func fetchPortfolioValue(userId: String) async throws -> Double {
        guard let url = URL(string: "\(baseURL)/value?user=\(userId)") else {
            throw APIError.invalidURL
        }
        
        let jsonArray: [[String: Any]] = try await apiClient.requestJSON(url: url, method: .GET, headers: [:], body: nil) as! [[String: Any]]
        return (jsonArray.first?["value"] as? Double) ?? 0.0
    }
    
    func fetchPositions(
        userId: String,
        sizeThreshold: Double = 0.1,
        limit: Int = 50,
        offset: Int = 0,
        sortBy: String = "CURRENT",
        sortDirection: String = "DESC"
    ) async throws -> [PolymarketModels.Position] {
        var components = URLComponents(string: "\(baseURL)/positions")!
        components.queryItems = [
            .init(name: "user", value: userId),
            .init(name: "sizeThreshold", value: String(sizeThreshold)),
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
            .init(name: "sortBy", value: sortBy),
            .init(name: "sortDirection", value: sortDirection)
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        return try await apiClient.request(url: url, method: .GET, headers: [:], body: nil)
    }
    
    func fetchCashBalance(userId: String) async throws -> Double {
        guard let url = URL(string: polygonRPCURL) else {
            throw APIError.invalidURL
        }
        
        let requestBody = [
            "jsonrpc": "2.0",
            "method": "eth_call",
            "params": [
                [
                    "to": "0x2791bca1f2de4661ed88a30c99a7a9449aa84174",
                    "data": "0x70a08231000000000000000000000000\(userId.dropFirst(2))"
                ],
                "latest"
            ],
            "id": 1
        ] as [String : Any]
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        let response: [String: Any] = try await apiClient.requestJSON(
            url: url,
            method: HTTPMethod.POST,
            headers: [:],
            body: bodyData
        ) as! [String: Any]
        
        guard let result = response["result"] as? String else {
            return 0.0
        }
        
        let hexString = String(result.dropFirst(2))
        guard let intValue = UInt64(hexString, radix: 16) else {
            return 0.0
        }
        
        return Double(intValue) / 1_000_000.0
    }
}