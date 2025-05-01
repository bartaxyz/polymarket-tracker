//
//  WalletListSidebarComponent.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import SwiftUI

struct WalletListSidebarComponent: View {
    var wallets: [WalletConnectModel]
    var deleteWallets: (IndexSet) -> Void
    
    var body: some View {
        List {
            Section(header: Text("Polymarket Wallets")) {
                ForEach(wallets) { wallet in
                    NavigationLink {
                        WalletDetailView(wallet: wallet)
                    } label: {
                        Image(systemName: "wallet.bifold")
                        VStack(alignment: .leading) {
                            Text(wallet.compressedPolymarketAddress)
                            Text("$1 000 000")
                                .font(.caption)
                                .opacity(0.5)
                        }
                    }
                }
                .onDelete(perform: deleteWallets)
            }
        }
    }
}
