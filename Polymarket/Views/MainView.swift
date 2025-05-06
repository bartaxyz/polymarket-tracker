//
//  MainView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 5/5/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WalletConnectModel.createdAt, order: .reverse) private var wallets: [WalletConnectModel]
    @State private var selectedWallet: WalletConnectModel?
    
    var body: some View {
        HomeView(
            wallet: selectedWallet
        )
        .onChange(of: wallets) { _, newWallets in
            selectedWallet = wallets.last
        }
        .task {
            selectedWallet = wallets.last
        }
    }
}

#Preview {
    MainView()
}
