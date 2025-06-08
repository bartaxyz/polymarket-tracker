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
    @State private var isRefreshing: Bool = false
    
    var selectedPosition: PolymarketDataService.Position? {
        dataService.positions?.first { $0.conditionId == selectedPositionId }
    }
    
    var body: some View {
        #if os(iOS)
        TabView {
            // Portfolio Tab (Default)
            NavigationStack {
                PortfolioTabView(wallet: wallet)
            }
            .tabItem {
                Label("Portfolio", systemImage: "chart.pie")
            }
            
            // Discover Tab (with integrated search)
            DiscoveryWithSearchView()
            .tabItem {
                Label("Discover", systemImage: "sparkles")
            }
        }
        .onChange(of: wallet) { _, wallet in
            if let address = wallet?.polymarketAddress {
                dataService.setUser(address)
            }
        }
        .task {
            if let address = wallet?.polymarketAddress {
                dataService.setUser(address)
            }
        }
        #else
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
                
    #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        Task {
                            isRefreshing = true
                            await refreshData()
                            isRefreshing = false
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .symbolEffect(.rotate, isActive: isRefreshing)
                    }
                    .disabled(isRefreshing)
                }
    #endif
            
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
        #endif
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

// MARK: - Tab Views for iOS

struct PortfolioTabView: View {
    let wallet: WalletConnectModel?
    @ObservedObject private var dataService = PolymarketDataService.shared
    @State private var isConnectWalletPresented = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let userId = wallet?.polymarketAddress {
                    PortfolioView(
                        showHeader: true,
                        showPicker: true
                    )
                    .frame(height: 200)
                    
                    if let positions = dataService.positions, !positions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Positions")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            
                            LazyVStack(spacing: 8) {
                                ForEach(positions, id: \.conditionId) { position in
                                    NavigationLink(destination: PositionDetailView(position: position)) {
                                        PositionRowView(position: position)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "wallet.bifold")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("Connect Your Wallet")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Connect your wallet to view your portfolio and track your positions")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Connect Wallet") {
                            isConnectWalletPresented = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 60)
                }
            }
            .padding()
        }
        .navigationTitle("Portfolio")
        .refreshable {
            if let address = wallet?.polymarketAddress {
                await dataService.refreshAllData()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let compressedAddress = wallet?.compressedPolymarketAddress {
                    Menu {
                        Button("Connect Different Wallet") {
                            isConnectWalletPresented = true
                        }
                        Button("Disconnect Wallet", role: .destructive) {
                            disconnectWallet()
                        }
                    } label: {
                        Label(compressedAddress, systemImage: "wallet.bifold")
                    }
                } else {
                    Button("Connect Wallet") {
                        isConnectWalletPresented = true
                    }
                }
            }
        }
        .sheet(isPresented: $isConnectWalletPresented) {
            ConnectWalletManuallyView()
        }
    }
    
    private func disconnectWallet() {
        Task {
            try? await WalletConnectModel.disconnectAllWallets(modelContext)
        }
    }
}

struct DiscoveryWithSearchView: View {
    @State private var searchQuery = ""
    @ObservedObject private var dataService = PolymarketDataService.shared
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            Group {
                if !searchQuery.isEmpty {
                    // Search Results
                    if dataService.isSearching {
                        ProgressView("Searching...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if dataService.searchResults.isEmpty {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "magnifyingglass",
                            description: Text("Try a different search term")
                        )
                    } else {
                        List {
                            ForEach(dataService.searchResults, id: \.id) { event in
                                NavigationLink(destination: MarketDetailView(market: .event(event))) {
                                    SearchResultRowView(event: event)
                                }
                            }
                            
                            if dataService.hasMoreSearchResults {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .onAppear {
                                        Task {
                                            await dataService.loadMoreSearchResults()
                                        }
                                    }
                            }
                        }
                    }
                } else {
                    // Discovery Content - but we need to remove its internal NavigationStack
                    DiscoveryContentView()
                }
            }
            .navigationTitle(searchQuery.isEmpty ? "Discover" : "Search Results")
            .searchable(text: $searchQuery, prompt: "Search markets...")
            .onSubmit(of: .search) {
                if !searchQuery.isEmpty {
                    Task {
                        await dataService.searchEvents(query: searchQuery)
                    }
                }
            }
            .onChange(of: searchQuery) { _, newValue in
                if newValue.isEmpty {
                    dataService.clearSearchResults()
                } else {
                    Task {
                        await dataService.searchEvents(query: newValue)
                    }
                }
            }
        }
    }
}

struct DiscoveryContentView: View {
    // State
    @State private var tags: [PolymarketDataService.Tag] = []
    @State private var events: [PolymarketDataService.GammaEvent] = []
    @State private var selectedTag: String?
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var hasMoreEvents = false
    @State private var currentOffset = 0
    private let pageSize = 20
    
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // All tag
                        TagButton(
                            tag: PolymarketDataService.Tag(
                                id: "all",
                                label: "All",
                                slug: "all",
                                forceShow: nil,
                                forceHide: nil,
                                createdAt: nil,
                                updatedAt: nil
                            ),
                            isSelected: selectedTag == nil,
                            action: {
                                selectedTag = nil
                                loadEvents()
                            }
                        )
                        
                        ForEach(tags, id: \.id) { tag in
                            TagButton(
                                tag: tag,
                                isSelected: selectedTag == tag.slug,
                                action: {
                                    selectedTag = tag.slug
                                    loadEvents(withTagSlug: tag.slug)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                if isLoading && events.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(events, id: \.id) { event in
                            EventCard(event: event)
                        }
                        
                        if isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .gridCellColumns(columns.count)
                        } else if hasMoreEvents {
                            Button(action: {
                                loadMoreEvents()
                            }) {
                                Text("Load More")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(10)
                            }
                            .gridCellColumns(columns.count)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .task {
            if tags.isEmpty {
                await loadTags()
            }
            if events.isEmpty {
                loadEvents(withTagSlug: selectedTag)
            }
        }
        .refreshable {
            await loadTags()
            loadEvents(withTagSlug: selectedTag)
        }
    }
    
    // MARK: - Data Loading (copied from DiscoveryView)
    
    private func loadTags() async {
        do {
            tags = try await PolymarketDataService.shared.fetchTags()
        } catch {
            if (error as NSError).code != NSURLErrorCancelled {
                print("Error fetching tags: \(error)")
            }
        }
    }
    
    private func loadEvents(withTagSlug tagSlug: String? = nil) {
        guard !isLoading else { return }
        
        Task { @MainActor in
            isLoading = true
            currentOffset = 0
            
            do {
                let response = try await PolymarketDataService.shared.fetchPaginatedEvents(
                    limit: pageSize,
                    offset: currentOffset,
                    tagSlug: tagSlug
                )
                
                events = response.data
                hasMoreEvents = response.pagination.hasMore
            } catch {
                if (error as NSError).code != NSURLErrorCancelled {
                    print("Error fetching events: \(error)")
                }
            }
            
            isLoading = false
        }
    }
    
    private func loadMoreEvents() {
        guard !isLoading && !isLoadingMore && hasMoreEvents else { return }
        
        Task { @MainActor in
            isLoadingMore = true
            let nextOffset = currentOffset + pageSize
            
            do {
                let response = try await PolymarketDataService.shared.fetchPaginatedEvents(
                    limit: pageSize,
                    offset: nextOffset,
                    tagSlug: selectedTag
                )
                
                events.append(contentsOf: response.data)
                hasMoreEvents = response.pagination.hasMore
                currentOffset = nextOffset
            } catch {
                if (error as NSError).code != NSURLErrorCancelled {
                    print("Error loading more events: \(error)")
                }
            }
            
            isLoadingMore = false
        }
    }
}

struct PositionRowView: View {
    let position: PolymarketDataService.Position
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(position.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(position.outcome)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                CurrencyText(amount: position.currentValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                PercentageText(
                    amount: position.percentPnl / 100,
                    signature: .always,
                    isDelta: true,
                    hasArrow: true
                )
                .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct SearchResultRowView: View {
    let event: PolymarketDataService.Event
    
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
                    Text("Volume: \(volume, format: .currency(code: "USD"))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView(wallet: WalletConnectModel(
        walletAddress: nil,
        polymarketAddress: "0x235A480a9CCB7aDA0Ad2DC11dAC3a11FB433Febd"
    ))
}
