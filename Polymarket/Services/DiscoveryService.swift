import Foundation
import Combine

@MainActor
class DiscoveryService: ObservableObject {
    @Published private(set) var events: [PolymarketModels.GammaEvent] = []
    @Published private(set) var hasMoreEvents: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    @Published private(set) var selectedTags: [String] = []
    
    private let gammaAPI: GammaAPIProtocol
    private let cacheManager: CacheManagerProtocol
    private var currentPage: Int = 1
    private let pageLimit: Int = 20
    
    nonisolated init(gammaAPI: GammaAPIProtocol = GammaAPI(), 
         cacheManager: CacheManagerProtocol = CacheManager()) {
        self.gammaAPI = gammaAPI
        self.cacheManager = cacheManager
    }
    
    func fetchEvents(tags: [String] = [], refresh: Bool = false) async {
        if refresh {
            events = []
            currentPage = 1
        }
        
        let cacheKey = CacheManager.CacheKey.gammaEvents(page: currentPage, tags: tags)
        
        // Check cache first (unless refreshing)
        if !refresh, let cachedResponse = cacheManager.get(cacheKey, type: PolymarketModels.GammaResponse.self) {
            if currentPage == 1 {
                self.events = cachedResponse.data
            } else {
                self.events.append(contentsOf: cachedResponse.data)
            }
            self.hasMoreEvents = cachedResponse.pagination.hasMore
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await gammaAPI.fetchEvents(page: currentPage, limit: pageLimit, tags: tags)
            
            if currentPage == 1 {
                self.events = response.data
            } else {
                self.events.append(contentsOf: response.data)
            }
            
            self.hasMoreEvents = response.pagination.hasMore
            self.selectedTags = tags
            
            // Cache the response
            cacheManager.set(cacheKey, value: response, expiration: CacheManager.eventsExpiration)
            
        } catch {
            self.error = error
            if currentPage == 1 {
                self.events = []
            }
            self.hasMoreEvents = false
        }
        
        isLoading = false
    }
    
    func loadMoreEvents() async {
        guard hasMoreEvents, !isLoading else { return }
        
        currentPage += 1
        await fetchEvents(tags: selectedTags)
    }
    
    func refreshEvents() async {
        await fetchEvents(tags: selectedTags, refresh: true)
    }
    
    func filterByTags(_ tags: [String]) async {
        self.selectedTags = tags
        self.currentPage = 1
        await fetchEvents(tags: tags, refresh: true)
    }
    
    func clearTagFilter() async {
        self.selectedTags = []
        self.currentPage = 1
        await fetchEvents(tags: [], refresh: true)
    }
    
    func clearCache() {
        // Clear cached events for all tag combinations
        // This is a simplified approach - in production you might want to track all cached keys
        for page in 1...10 { // Clear first 10 pages
            let cacheKey = CacheManager.CacheKey.gammaEvents(page: page, tags: selectedTags)
            cacheManager.remove(cacheKey)
        }
    }
    
    // Get event by ID from currently loaded events
    func getEvent(byId id: String) -> PolymarketModels.GammaEvent? {
        return events.first { $0.id == id }
    }
    
    // Get event by slug from currently loaded events
    func getEvent(bySlug slug: String) -> PolymarketModels.GammaEvent? {
        return events.first { $0.slug == slug }
    }
    
    // Get events by specific criteria
    func getEvents(matching predicate: (PolymarketModels.GammaEvent) -> Bool) -> [PolymarketModels.GammaEvent] {
        return events.filter(predicate)
    }
    
    // Get featured events
    func getFeaturedEvents() -> [PolymarketModels.GammaEvent] {
        return events.filter { $0.featured == true }
    }
    
    // Get new events
    func getNewEvents() -> [PolymarketModels.GammaEvent] {
        return events.filter { $0.new == true }
    }
    
    // Get events sorted by volume
    func getEventsSortedByVolume() -> [PolymarketModels.GammaEvent] {
        return events.sorted { (lhs, rhs) in
            let lhsVolume = lhs.volume ?? 0
            let rhsVolume = rhs.volume ?? 0
            return lhsVolume > rhsVolume
        }
    }
    
    // Get events sorted by liquidity 
    func getEventsSortedByLiquidity() -> [PolymarketModels.GammaEvent] {
        return events.sorted { (lhs, rhs) in
            let lhsLiquidity = lhs.liquidity ?? 0
            let rhsLiquidity = rhs.liquidity ?? 0
            return lhsLiquidity > rhsLiquidity
        }
    }
}