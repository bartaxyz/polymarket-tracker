//
//  WatchlistItem.swift
//  Polymarket
//
//  Created by Alt on 27/2/26.
//

import Foundation
import SwiftData

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
