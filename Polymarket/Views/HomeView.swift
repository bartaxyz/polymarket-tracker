//
//  WalletConnectView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import SwiftUI
import SwiftData

#if os(iOS)
import ReownAppKit
#endif

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var wallets: [WalletConnectModel]
    
    @State var isConnectWalletPresented: Bool = false
    
    var body: some View {
        NavigationSplitView {
            VStack {
                if !wallets.isEmpty {
                    WalletListSidebarComponent(
                        wallets: wallets,
                        deleteWallets: deleteWallets
                    )
                } else {
                    EmptySidebarComponent(action: connectWallet)
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar(removing: .sidebarToggle)
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    AppKitButton()
                }
#endif
                if !wallets.isEmpty {
                    ToolbarItem {
                        Spacer()
                    }
                    
                    ToolbarItem {
                        Button(action: connectWallet) {
                            Label("Connect Wallet", systemImage: "plus")
                        }
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
        .navigationTitle("Polymarket Widgets")
        .sheet(isPresented: $isConnectWalletPresented) {
            ConnectWalletManuallyView()
        }
    }
    
    private func connectWallet() {
        isConnectWalletPresented.toggle()
        
        // TODO:
        // - WalletConnect
        // - Polymarket address lookup
        
        // AppKit.present()
        
        /*withAnimation {
            let newWallet = WalletConnectModel(
                walletAddress: nil,
                polymarketAddress: nil,
            )
            modelContext.insert(newWallet)
        }*/
    }
    
    private func disconnectWallet() {
        // try! await AppKit.instance.disconnect(topic: "manual")
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
    HomeView()
}
