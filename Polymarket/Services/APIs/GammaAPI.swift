import Foundation

protocol GammaAPIProtocol {
    func fetchEvents(page: Int, limit: Int, tags: [String]) async throws -> PolymarketModels.GammaResponse
}

class GammaAPI: GammaAPIProtocol {
    private let apiClient: APIClientProtocol
    private let baseURL = "https://gamma-api.polymarket.com"
    
    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }
    
    func fetchEvents(page: Int = 1, limit: Int = 20, tags: [String] = []) async throws -> PolymarketModels.GammaResponse {
        var components = URLComponents(string: "\(baseURL)/events/pagination")!
        
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        for tag in tags {
            queryItems.append(URLQueryItem(name: "tags", value: tag))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        return try await apiClient.request(url: url, method: .GET, headers: [:], body: nil)
    }
}