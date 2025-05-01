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
    var walletAddress: String;
    var createdAt: Date;
    var polymarketAddress: String;
    
    init(walletAddress: String, polymarketAddress: String) {
        self.walletAddress = walletAddress.lowercased()
        self.createdAt = Date()
        self.polymarketAddress = polymarketAddress
    }
}
