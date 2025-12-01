import Foundation

protocol SearchAPIProtocol {
    func searchEvents(query: String, category: String, page: Int) async throws -> PolymarketModels.SearchResponse
    func fetchTags() async throws -> Any
}

class SearchAPI: SearchAPIProtocol {
    private let apiClient: APIClientProtocol
    private let baseURL = "https://polymarket.com/api"
    
    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }
    
    func searchEvents(query: String, category: String = "all", page: Int = 1) async throws -> PolymarketModels.SearchResponse {
        var components = URLComponents(string: "\(baseURL)/events/search")!
        components.queryItems = [
            .init(name: "query", value: query),
            .init(name: "category", value: category),
            .init(name: "page", value: String(page)),
            .init(name: "limit", value: "20")
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        return try await apiClient.request(url: url, method: .GET, headers: [:], body: nil)
    }
    
    func fetchTags() async throws -> Any {
        guard let url = URL(string: "\(baseURL)/tags/filteredBySlug?tag=all&status=active") else {
            throw APIError.invalidURL
        }
        
        return try await apiClient.requestJSON(url: url, method: .GET, headers: [:], body: nil)
    }
}