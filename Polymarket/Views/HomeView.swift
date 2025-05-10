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
    
    @State private var userData: PolymarketDataService.UserData?
    @State private var isConnectWalletPresented = false
    @State private var selectedPositionId: String?
    @State private var searchQuery: String = ""
    @State private var searchResults: [PolymarketDataService.Event] = []
    @State private var isSearching = false
    @State private var hasMoreSearchResults = false
    @State private var searchPage = 1
    
    var selectedPosition: PolymarketDataService.Position? {
        userData?.positions?.first { $0.conditionId == selectedPositionId }
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                if !searchResults.isEmpty {
                    SearchResultsSection(
                        results: searchResults,
                        hasMore: hasMoreSearchResults,
                        selectedId: selectedPositionId,
                        onSelect: { id in
                            selectedPositionId = id
                        },
                        onLoadMore: loadMoreSearchResults
                    )
                }
                
                if let userId = wallet?.polymarketAddress {
                    PortfolioSidebarSectionView(
                        userId: userId,
                        userData: userData
                    )
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
                
                DiscoverSection()
            }
            .searchable(text: $searchQuery, prompt: "Search markets...")
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchQuery) { _, newQuery in
                if newQuery.isEmpty {
                    searchResults = []
                    hasMoreSearchResults = false
                }
            }
            .refreshable {
                syncRefreshData()
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
            syncRefreshData()
        }
        .navigationTitle("")
        .task {
            await refreshData()
        }
    }
    
    private func syncRefreshData() {
        Task {
            await refreshData()
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
        guard let address = wallet?.polymarketAddress else { return }
        userData = await PolymarketDataService.fetchUserData(userId: address)
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            hasMoreSearchResults = false
            return
        }
        
        isSearching = true
        searchPage = 1
        
        Task {
            do {
                let response = try await PolymarketDataService.searchEvents(query: searchQuery, page: searchPage)
                searchResults = response.events
                hasMoreSearchResults = response.hasMore
            } catch {
                print("Search error: \(error)")
            }
            isSearching = false
        }
    }
    
    private func loadMoreSearchResults() {
        guard hasMoreSearchResults, !isSearching else { return }
        
        isSearching = true
        searchPage += 1
        
        Task {
            do {
                let response = try await PolymarketDataService.searchEvents(query: searchQuery, page: searchPage)
                searchResults.append(contentsOf: response.events)
                hasMoreSearchResults = response.hasMore
            } catch {
                print("Load more search results error: \(error)")
                searchPage -= 1
            }
            isSearching = false
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

#Preview {
    HomeView(wallet: WalletConnectModel(
        walletAddress: nil,
        polymarketAddress: "0x235A480a9CCB7aDA0Ad2DC11dAC3a11FB433Febd"
    ))
}
