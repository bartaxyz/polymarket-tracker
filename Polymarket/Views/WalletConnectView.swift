//
//  WalletConnectView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import SwiftUI
import SwiftData

import ReownAppKit

struct WalletConnectView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var wallets: [WalletConnectModel]
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(wallets) { wallet in
                    NavigationLink {
                        Text("Item at \(wallet.createdAt, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(wallet.createdAt, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteWallets)
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    AppKitButton()
                }
                ToolbarItem {
                    Web3ModalNetworkButton()
                }
                ToolbarItem {
                    Button(action: connectWallet) {
                        Label("Connect Wallet", systemImage: "wallet.bifold")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
    
    private func connectWallet() {
        // TODO:
        // - WalletConnect
        // - Polymarket address lookup
        
        /*withAnimation {
            let newWallet = WalletConnectModel(
                walletAddress: nil,
                polymarketAddress: nil,
            )
            modelContext.insert(newWallet)
        }*/
    }
    
    private func deleteWallets(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(wallets[index])
            }
        }
    }
}

#Preview {
    WalletConnectView()
}
