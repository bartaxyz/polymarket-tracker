import Foundation

protocol EventRepositoryProtocol {
    func searchEvents(query: String, category: String) async -> [PolymarketModels.GammaEvent]
    func loadMoreSearchResults() async -> [PolymarketModels.GammaEvent]
    func getDiscoveryEvents(tags: [String]) async -> [PolymarketModels.GammaEvent]
    func loadMoreDiscoveryEvents() async -> [PolymarketModels.GammaEvent]
    func refreshDiscoveryEvents(tags: [String]) async -> [PolymarketModels.GammaEvent]
    func getTags() async -> [PolymarketModels.Tag]
    func clearSearchResults()
    func clearCache()
    
    var hasMoreSearchResults: Bool { get }
}

@MainActor
class EventRepository: EventRepositoryProtocol {
    private let searchService: SearchService
    private let discoveryService: DiscoveryService
    
    nonisolated init(searchService: SearchService = SearchService(), 
                     discoveryService: DiscoveryService = DiscoveryService()) {
        self.searchService = searchService
        self.discoveryService = discoveryService
    }
    
    func searchEvents(query: String, category: String = "all") async -> [PolymarketModels.GammaEvent] {
        await searchService.searchEvents(query: query, category: category)
        return searchService.searchResults
    }
    
    func loadMoreSearchResults() async -> [PolymarketModels.GammaEvent] {
        await searchService.loadMoreSearchResults()
        return searchService.searchResults
    }
    
    func getDiscoveryEvents(tags: [String] = []) async -> [PolymarketModels.GammaEvent] {
        await discoveryService.fetchEvents(tags: tags)
        return discoveryService.events
    }
    
    func loadMoreDiscoveryEvents() async -> [PolymarketModels.GammaEvent] {
        await discoveryService.loadMoreEvents()
        return discoveryService.events
    }
    
    func refreshDiscoveryEvents(tags: [String] = []) async -> [PolymarketModels.GammaEvent] {
        await discoveryService.refreshEvents()
        return discoveryService.events
    }
    
    func getTags() async -> [PolymarketModels.Tag] {
        return await searchService.fetchTags()
    }
    
    func clearSearchResults() {
        searchService.clearSearchResults()
    }
    
    func clearCache() {
        searchService.clearSearchCache()
        discoveryService.clearCache()
    }
    
    // Convenience methods for getting current state
    var currentSearchResults: [PolymarketModels.GammaEvent] {
        searchService.searchResults
    }
    
    var hasMoreSearchResults: Bool {
        searchService.hasMoreSearchResults
    }
    
    var isSearching: Bool {
        searchService.isSearching
    }
    
    var currentDiscoveryEvents: [PolymarketModels.GammaEvent] {
        discoveryService.events
    }
    
    var hasMoreDiscoveryEvents: Bool {
        discoveryService.hasMoreEvents
    }
    
    var isLoadingDiscovery: Bool {
        discoveryService.isLoading
    }
    
    var selectedTags: [String] {
        discoveryService.selectedTags
    }
    
    // Event lookup methods
    func getEvent(byId id: String) -> PolymarketModels.GammaEvent? {
        // Check search results first
        if let event = searchService.searchResults.first(where: { $0.id == id }) {
            return event
        }
        
        // Check discovery events
        return discoveryService.getEvent(byId: id)
    }
    
    func getEvent(bySlug slug: String) -> PolymarketModels.GammaEvent? {
        // Check search results first
        if let event = searchService.searchResults.first(where: { $0.slug == slug }) {
            return event
        }
        
        // Check discovery events
        return discoveryService.getEvent(bySlug: slug)
    }
    
    // Filter methods
    func getFeaturedEvents() -> [PolymarketModels.GammaEvent] {
        return discoveryService.getFeaturedEvents()
    }
    
    func getNewEvents() -> [PolymarketModels.GammaEvent] {
        return discoveryService.getNewEvents()
    }
    
    func getEventsSortedByVolume() -> [PolymarketModels.GammaEvent] {
        return discoveryService.getEventsSortedByVolume()
    }
    
    func getEventsSortedByLiquidity() -> [PolymarketModels.GammaEvent] {
        return discoveryService.getEventsSortedByLiquidity()
    }
}