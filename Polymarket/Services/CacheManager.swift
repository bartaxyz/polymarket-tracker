import Foundation

protocol CacheManagerProtocol {
    func get<T: Codable>(_ key: String, type: T.Type) -> T?
    func set<T: Codable>(_ key: String, value: T, expiration: TimeInterval?)
    func remove(_ key: String)
    func clear()
    func isExpired(_ key: String) -> Bool
}

class CacheManager: CacheManagerProtocol {
    private let userDefaults: UserDefaults
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // In-memory cache for frequently accessed data
    private var memoryCache: [String: CachedItem] = [:]
    private let memoryCacheQueue = DispatchQueue(label: "cache.memory", attributes: .concurrent)
    
    // Cache expiration times
    static let portfolioExpiration: TimeInterval = 5 * 60 // 5 minutes
    static let eventsExpiration: TimeInterval = 60 * 60 // 1 hour
    static let searchExpiration: TimeInterval = 10 * 60 // 10 minutes
    static let pnlExpiration: TimeInterval = 30 * 60 // 30 minutes
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        // Set up cache directory in app group for widget sharing
        if let appGroupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.ondrejbarta.Polymarket") {
            self.cacheDirectory = appGroupURL.appendingPathComponent("Cache")
        } else {
            // Fallback to regular cache directory
            self.cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("PolymarketCache")
        }
        
        createCacheDirectoryIfNeeded()
        cleanupExpiredCache()
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func get<T: Codable>(_ key: String, type: T.Type) -> T? {
        // Check memory cache first
        if let memoryItem = getFromMemoryCache(key, type: type) {
            return memoryItem
        }
        
        // Check disk cache
        if let diskItem = getFromDiskCache(key, type: type) {
            // Store in memory cache for faster access
            setInMemoryCache(key, value: diskItem, expiration: nil)
            return diskItem
        }
        
        return nil
    }
    
    func set<T: Codable>(_ key: String, value: T, expiration: TimeInterval? = nil) {
        let expirationDate = expiration.map { Date().addingTimeInterval($0) }
        
        // Store in memory cache
        setInMemoryCache(key, value: value, expiration: expirationDate)
        
        // Store in disk cache for persistence
        setInDiskCache(key, value: value, expiration: expirationDate)
    }
    
    func remove(_ key: String) {
        // Remove from memory cache
        memoryCacheQueue.async(flags: .barrier) {
            self.memoryCache.removeValue(forKey: key)
        }
        
        // Remove from disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        try? fileManager.removeItem(at: fileURL)
        
        // Remove expiration info
        userDefaults.removeObject(forKey: "expiration_\(key)")
    }
    
    func clear() {
        // Clear memory cache
        memoryCacheQueue.async(flags: .barrier) {
            self.memoryCache.removeAll()
        }
        
        // Clear disk cache
        try? fileManager.removeItem(at: cacheDirectory)
        createCacheDirectoryIfNeeded()
        
        // Clear all expiration keys
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix("expiration_") {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    func isExpired(_ key: String) -> Bool {
        guard let expirationDate = userDefaults.object(forKey: "expiration_\(key)") as? Date else {
            return false // No expiration set
        }
        return Date() > expirationDate
    }
    
    // MARK: - Memory Cache
    
    private func getFromMemoryCache<T: Codable>(_ key: String, type: T.Type) -> T? {
        return memoryCacheQueue.sync {
            guard let item = memoryCache[key],
                  !item.isExpired,
                  let value = item.value as? T else {
                return nil
            }
            return value
        }
    }
    
    private func setInMemoryCache<T: Codable>(_ key: String, value: T, expiration: Date?) {
        memoryCacheQueue.async(flags: .barrier) {
            self.memoryCache[key] = CachedItem(value: value, expiration: expiration)
        }
    }
    
    // MARK: - Disk Cache
    
    private func getFromDiskCache<T: Codable>(_ key: String, type: T.Type) -> T? {
        guard !isExpired(key) else {
            remove(key)
            return nil
        }
        
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try? decoder.decode(T.self, from: data)
    }
    
    private func setInDiskCache<T: Codable>(_ key: String, value: T, expiration: Date?) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(value) else {
            return
        }
        
        try? data.write(to: fileURL)
        
        // Store expiration info
        if let expiration = expiration {
            userDefaults.set(expiration, forKey: "expiration_\(key)")
        }
    }
    
    // MARK: - Cleanup
    
    private func cleanupExpiredCache() {
        // Clean up expired memory cache items
        memoryCacheQueue.async(flags: .barrier) {
            self.memoryCache = self.memoryCache.filter { !$0.value.isExpired }
        }
        
        // Clean up expired disk cache items
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix("expiration_") {
                let cacheKey = String(key.dropFirst("expiration_".count))
                if isExpired(cacheKey) {
                    remove(cacheKey)
                }
            }
        }
    }
}

// MARK: - Cache Key Extensions

extension CacheManager {
    enum CacheKey {
        static func portfolioValue(userId: String) -> String {
            return "portfolio_value_\(userId)"
        }
        
        static func positions(userId: String) -> String {
            return "positions_\(userId)"
        }
        
        static func cashBalance(userId: String) -> String {
            return "cash_balance_\(userId)"
        }
        
        static func pnl(userId: String, interval: PolymarketModels.PnLInterval, fidelity: PolymarketModels.PnLFidelity?) -> String {
            let fidelityStr = fidelity?.rawValue ?? "nil"
            return "pnl_\(userId)_\(interval.rawValue)_\(fidelityStr)"
        }
        
        static func searchResults(query: String, category: String, page: Int) -> String {
            return "search_\(query)_\(category)_\(page)"
        }
        
        static func gammaEvents(page: Int, tags: [String]) -> String {
            let tagsStr = tags.joined(separator: ",")
            return "gamma_events_\(page)_\(tagsStr)"
        }
        
        static func tags() -> String {
            return "tags"
        }
    }
}

// MARK: - Supporting Types

private struct CachedItem {
    let value: Any
    let expiration: Date?
    
    var isExpired: Bool {
        guard let expiration = expiration else { return false }
        return Date() > expiration
    }
}