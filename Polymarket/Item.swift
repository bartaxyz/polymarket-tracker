//
//  Item.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 27/4/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
