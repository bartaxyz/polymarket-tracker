import Foundation
import Combine

@MainActor
class SearchService: ObservableObject {
    @Published private(set) var searchResults: [PolymarketModels.GammaEvent] = []
    @Published private(set) var hasMoreSearchResults: Bool = false
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var error: Error?
    
    private let searchAPI: SearchAPIProtocol
    private let cacheManager: CacheManagerProtocol
    private var searchPage: Int = 1
    private var searchQuery: String = ""
    private var searchCategory: String = "all"
    
    nonisolated init(searchAPI: SearchAPIProtocol = SearchAPI(), 
         cacheManager: CacheManagerProtocol = CacheManager()) {
        self.searchAPI = searchAPI
        self.cacheManager = cacheManager
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
        searchCategory = category
        
        let cacheKey = CacheManager.CacheKey.searchResults(query: query, category: category, page: searchPage)
        
        // Check cache first
        if let cachedResponse = cacheManager.get(cacheKey, type: PolymarketModels.SearchResponse.self) {
            self.searchResults = cachedResponse.events.map { $0.toGammaEvent() }
            self.hasMoreSearchResults = cachedResponse.hasMore
            isSearching = false
            print("🔍 Loaded from cache: \(searchResults.count) events")
            return
        }
        
        do {
            let response = try await searchAPI.searchEvents(query: query, category: category, page: searchPage)
            print("🔍 Search response: \(response.events.count) events, hasMore: \(response.hasMore)")
            
            self.searchResults = response.events.map { $0.toGammaEvent() }
            self.hasMoreSearchResults = response.hasMore
            
            // Cache the response
            cacheManager.set(cacheKey, value: response, expiration: CacheManager.searchExpiration)
            
            print("🔍 Converted to PolymarketModels.GammaEvents: \(searchResults.count)")
        } catch {
            print("🔍 Search error: \(error)")
            self.error = error
            self.searchResults = []
            self.hasMoreSearchResults = false
        }
        
        isSearching = false
    }
    
    func loadMoreSearchResults() async {
        guard hasMoreSearchResults, !isSearching, !searchQuery.isEmpty else { return }
        
        isSearching = true
        searchPage += 1
        
        let cacheKey = CacheManager.CacheKey.searchResults(query: searchQuery, category: searchCategory, page: searchPage)
        
        // Check cache first
        if let cachedResponse = cacheManager.get(cacheKey, type: PolymarketModels.SearchResponse.self) {
            self.searchResults.append(contentsOf: cachedResponse.events.map { $0.toGammaEvent() })
            self.hasMoreSearchResults = cachedResponse.hasMore
            isSearching = false
            return
        }
        
        do {
            let response = try await searchAPI.searchEvents(query: searchQuery, category: searchCategory, page: searchPage)
            self.searchResults.append(contentsOf: response.events.map { $0.toGammaEvent() })
            self.hasMoreSearchResults = response.hasMore
            
            // Cache the response
            cacheManager.set(cacheKey, value: response, expiration: CacheManager.searchExpiration)
        } catch {
            self.error = error
            searchPage -= 1 // Revert page increment on error
        }
        
        isSearching = false
    }
    
    func clearSearchResults() {
        searchResults = []
        hasMoreSearchResults = false
        searchQuery = ""
        searchCategory = "all"
        searchPage = 1
    }
    
    func clearSearchCache() {
        // This would require knowing all cached search keys, which is complex
        // For now, we'll implement a simple approach
        // In a production app, you might want to track cached keys
    }
    
    // Fetch tags for search categories
    func fetchTags() async -> [PolymarketModels.Tag] {
        let cacheKey = CacheManager.CacheKey.tags()
        
        // Check cache first
        if let cached = cacheManager.get(cacheKey, type: [PolymarketModels.Tag].self) {
            return cached
        }
        
        do {
            let tagsData = try await searchAPI.fetchTags()
            
            // Parse the tags data (this might need adjustment based on actual API response)
            if let tagsArray = tagsData as? [[String: Any]] {
                let tags = tagsArray.compactMap { dict -> PolymarketModels.Tag? in
                    guard let id = dict["id"] as? String,
                          let label = dict["label"] as? String,
                          let slug = dict["slug"] as? String else {
                        return nil
                    }
                    
                    return PolymarketModels.Tag(
                        id: id,
                        label: label,
                        slug: slug,
                        forceShow: dict["forceShow"] as? Bool,
                        forceHide: dict["forceHide"] as? Bool,
                        createdAt: dict["createdAt"] as? String,
                        updatedAt: dict["updatedAt"] as? String
                    )
                }
                
                // Cache for 1 hour
                cacheManager.set(cacheKey, value: tags, expiration: 60 * 60)
                return tags
            }
        } catch {
            self.error = error
        }
        
        return []
    }
}