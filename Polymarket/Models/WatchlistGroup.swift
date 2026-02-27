//
//  WatchlistGroup.swift
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
