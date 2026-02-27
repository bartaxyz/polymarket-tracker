//
//  WatchlistItem.swift
//  Polymarket
//
//  Created by Alt on 27/2/26.
//

import Foundation
import SwiftData

@Model
final class WatchlistGroup {
    var name: String?
    var icon: String?
    var createdAt: Date?
    var sortOrder: Int?
    
    @Relationship(deleteRule: .cascade, inverse: \WatchlistItem.group)
    var items: [WatchlistItem]?
    
    init(name: String, icon: String? = nil) {
        self.name = name
        self.icon = icon
        self.createdAt = Date()
        self.sortOrder = 0
        self.items = []
    }
}

@Model
final class WatchlistItem {
    var eventId: String?
    var eventSlug: String?
    var title: String?
    var imageUrl: String?
    var addedAt: Date?
    var group: WatchlistGroup?

    init(eventId: String, eventSlug: String, title: String, imageUrl: String? = nil, group: WatchlistGroup? = nil) {
        self.eventId = eventId
        self.eventSlug = eventSlug
        self.title = title
        self.imageUrl = imageUrl
        self.addedAt = Date()
        self.group = group
    }
}
