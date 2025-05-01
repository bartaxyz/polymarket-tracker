//
//  AppIntent.swift
//  ProfitLoss
//
//  Created by Ondřej Bárta on 27/4/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Profit & Loss" }
    static var description: IntentDescription { "Real-time Polymarket P&L for your wallet" }
    
    /*
     @Parameter(
        title: "Polymarket Wallet",
        default: nil
    )
    public var wallet: WalletEntity?
     */
}
