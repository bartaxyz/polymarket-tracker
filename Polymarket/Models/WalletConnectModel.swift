//
//  WalletConnectModel.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import Foundation
import SwiftData

@Model
final class WalletConnectModel {
    var walletAddress: String?;
    var createdAt: Date?;
    var polymarketAddress: String?;
    
    init(walletAddress: String?, polymarketAddress: String) {
        self.walletAddress = walletAddress?.lowercased()
        self.createdAt = Date()
        self.polymarketAddress = polymarketAddress.lowercased()
    }
    
    var compressedPolymarketAddress: String? {
        guard let polymarketAddress = polymarketAddress else { return nil }
        guard polymarketAddress.count > 10 else { return polymarketAddress }
        let prefix = polymarketAddress.prefix(6)
        let suffix = polymarketAddress.suffix(4)
        return "\(prefix)...\(suffix)"
    }
    
    static func validatePolymarketAddress(_ address: String) -> Bool {
        guard !address.isEmpty else { return false }
        return address.count >= 42
    }
}
