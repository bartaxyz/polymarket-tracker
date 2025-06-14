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
    @State private var isRefreshing: Bool = false
    
    var selectedPosition: PolymarketDataService.Position? {
        dataService.positions?.first { $0.conditionId == selectedPositionId }
    }
    
    var body: some View {
#if os(iOS)
        TabView {
            NavigationStack {
                PortfolioTabView(wallet: wallet)
            }
            .tabItem {
                Label("Portfolio", systemImage: "chart.pie")
            }
            
            DiscoveryView()
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
            DiscoveryView()
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HStack(spacing: 0) {
                    // Center content on larger screens
                    if geometry.size.width > 800 {
                        Spacer()
                    }
                    
                    VStack(spacing: 20) {
                        if let userId = wallet?.polymarketAddress {
                            PortfolioView(
                                showHeader: true,
                                showPicker: true
                            )
                            .frame(height: geometry.size.width > 800 ? 250 : 200)
                            
                            if let positions = dataService.positions, !positions.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Positions")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Spacer()
                                    }
                                    
                                    if geometry.size.width > 800 {
                                        // Grid layout for larger screens
                                        LazyVGrid(columns: [
                                            GridItem(.flexible()),
                                            GridItem(.flexible())
                                        ], spacing: 12) {
                                            ForEach(positions, id: \.conditionId) { position in
                                                NavigationLink(destination: PositionDetailView(position: position)) {
                                                    PositionRowView(position: position)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    } else {
                                        // List layout for smaller screens
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
                    .frame(maxWidth: geometry.size.width > 800 ? 700 : .infinity)
                    .padding()
                    
                    if geometry.size.width > 800 {
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Portfolio")
        .refreshable {
            if let address = wallet?.polymarketAddress {
                await dataService.refreshAllData()
            }
        }
        .toolbar {
            ToolbarItem() {
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
        .cornerRadius(8)
    }
}


#Preview {
    HomeView(wallet: WalletConnectModel(
        walletAddress: nil,
        polymarketAddress: "0x235A480a9CCB7aDA0Ad2DC11dAC3a11FB433Febd"
    ))
}
