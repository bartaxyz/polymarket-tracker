//
//  WalletConnectView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import SwiftUI
import SwiftData

#if os(iOS)
/*
import ReownAppKit
*/
#endif

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    var wallet: WalletConnectModel?
    
    @ObservedObject private var dataService = PolymarketDataService.shared
    @State private var isConnectWalletPresented = false
    @State private var selectedPositionId: String?
    @State private var searchQuery: String = ""
    @State private var isSearchPresented: Bool = false
    
    var selectedPosition: PolymarketDataService.Position? {
        dataService.positions?.first { $0.conditionId == selectedPositionId }
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                if let userId = wallet?.polymarketAddress {
                    PortfolioSidebarSectionView()
                }
                
                if wallet == nil {
                    Section {
                        VStack(spacing: 4) {
                            Image(systemName: "wallet.bifold")
                            Text("Connect Wallet")
                            Text("Connect your wallet to see your portfolio")
                                .lineLimit(nil)
                                .multilineTextAlignment(.center)
                                .opacity(0.5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        
                        NavigationLink(destination: ConnectWalletManuallyView()) {
                            Label("Connect Wallet", systemImage: "wallet.bifold")
                        }
                    } header: {
                        Text("Portfolio")
                    }
                }
                
                Section {
                    NavigationLink(destination: DiscoveryView()) {
                        Label("Discover", systemImage: "sparkles")
                    }
                } header: {
                    Text("Explore")
                }
            }
            .searchable(text: $searchQuery, prompt: "Search markets...")
            .onSubmit(of: .search) {
                if !searchQuery.isEmpty {
                    // Clear previous search results before showing search view
                    dataService.clearSearchResults()
                    isSearchPresented = true
                }
            }
            .refreshable {
                await refreshData()
            }
            .toolbar {
    #if os(iOS)
                let placement: ToolbarItemPlacement = .navigationBarTrailing
    #else
                let placement: ToolbarItemPlacement = .automatic
    #endif
            
                ToolbarItem {
                    Spacer()
                }
            
                if let compressedPolymarketAddress = wallet?.compressedPolymarketAddress {
                    ToolbarItem(placement: placement) {
                        Menu {
                            Button("Connect a different wallet") {
                                connectWallet()
                            }
                            Button("Disconnect wallet") {
                                disconnectWallet()
                            }
                        } label: {
                            Label(compressedPolymarketAddress, systemImage: "wallet.bifold")
                        }
                    }
                } else {
                    ToolbarItem(placement: placement) {
                        NavigationLink(destination: ConnectWalletManuallyView()) {
                            Label("Connect Wallet", systemImage: "wallet.bifold")
                        }
                    }
                }
            }
        } detail: {
            ZStack {
                DiscoveryView()
                
                NavigationLink(
                    destination: SearchView(initialQuery: searchQuery),
                    isActive: $isSearchPresented,
                    label: { EmptyView() }
                )
                .onChange(of: isSearchPresented) { _, isActive in
                    // Reset search query when returning from search view
                    if !isActive {
                        searchQuery = ""
                    }
                }
                .hidden()
            }
        }
        .sheet(isPresented: $isConnectWalletPresented) {
            ConnectWalletManuallyView()
        }
        .onChange(of: wallet) { _, wallet in
            if let address = wallet?.polymarketAddress {
                dataService.setUser(address)
            }
        }
        .navigationTitle("")
        .task {
            if let address = wallet?.polymarketAddress {
                dataService.setUser(address)
            }
        }
    }
    
    private func connectWallet() {
        isConnectWalletPresented.toggle()
    }
    
    private func disconnectWallet() {
        Task {
            try? await WalletConnectModel.disconnectAllWallets(modelContext)
        }
    }
    
    private func refreshData() async {
        if let address = wallet?.polymarketAddress {
            await dataService.refreshAllData()
        }
    }
}


#Preview {
    HomeView(wallet: WalletConnectModel(
        walletAddress: nil,
        polymarketAddress: "0x235A480a9CCB7aDA0Ad2DC11dAC3a11FB433Febd"
    ))
}
