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
    
    var selectedPosition: PolymarketDataService.Position? {
        dataService.positions?.first { $0.conditionId == selectedPositionId }
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                if !dataService.searchResults.isEmpty {
                    SearchResultsSection(
                        results: dataService.searchResults,
                        hasMore: dataService.hasMoreSearchResults,
                        selectedId: selectedPositionId,
                        onSelect: { id in
                            selectedPositionId = id
                        },
                        onLoadMore: {
                            Task {
                                await dataService.loadMoreSearchResults()
                            }
                        }
                    )
                }
                
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
                
                // DiscoverSection()
            }
            .searchable(text: $searchQuery, prompt: "Search markets...")
            .onSubmit(of: .search) {
                Task {
                    await dataService.searchEvents(query: searchQuery)
                }
            }
            .onChange(of: searchQuery) { _, newQuery in
                if newQuery.isEmpty {
                    dataService.clearSearchResults()
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
            Text("TODO")
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

private struct SearchResultsSection: View {
    let results: [PolymarketDataService.Event]
    let hasMore: Bool
    let selectedId: String?
    let onSelect: (String) -> Void
    let onLoadMore: () -> Void
    
    var body: some View {
        Section("Search Results") {
            ForEach(results, id: \.id) { event in
                EventRowView(event: event, isSelected: selectedId == event.id)
                    .onTapGesture {
                        onSelect(event.id)
                    }
            }
            
            if hasMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .onAppear(perform: onLoadMore)
            }
        }
    }
}

private struct DiscoverSection: View {
    var body: some View {
        Section {
            NavigationLink(destination: Text("Trending")) {
                Label("Trending", systemImage: "chart.line.uptrend.xyaxis")
            }
            NavigationLink(destination: Text("New")) {
                Label("New", systemImage: "sparkles")
            }
            NavigationLink(destination: Text("Politics")) {
                Label("Politics", systemImage: "building.columns")
            }
            NavigationLink(destination: Text("Sports")) {
                Label("Sports", systemImage: "soccerball")
            }
            NavigationLink(destination: Text("Crypto")) {
                Label("Crypto", systemImage: "bitcoinsign")
            }
        } header: {
            Text("Discover")
        }
    }
}

private struct EventRowView: View {
    let event: PolymarketDataService.Event
    let isSelected: Bool
    
    var body: some View {
        NavigationLink(destination: EmptyView()) {
            HStack(spacing: 12) {
                if let imageUrl = event.imageUrl,
                let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .lineLimit(2)
                        .font(.subheadline)
                    
                    if let volume = event.volume {
                        Text("Volume: $\(String(format: "%.2f", volume))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView(wallet: WalletConnectModel(
        walletAddress: nil,
        polymarketAddress: "0x235A480a9CCB7aDA0Ad2DC11dAC3a11FB433Febd"
    ))
}
