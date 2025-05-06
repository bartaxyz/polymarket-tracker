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
    
    var selectedPosition: PolymarketDataService.Position? {
        userData?.positions?.first { $0.conditionId == selectedPositionId }
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                if wallet != nil {
                    VStack {
                        if let portfolioValue = userData?.portfolioValue {
                            HStack {
                                Text(portfolioValue, format: .currency(code: "USD"))
                                    .bold()
                                Spacer()
                                Text(portfolioValue, format: .currency(code: "USD"))
                                    .bold()
                            }
                            .padding()
                        }
                        
                        if let pnlData = userData?.pnlData {
                            ProfitLossChart(
                                data: pnlData,
                                // hideXAxis: true,
                                // hideYAxis: true
                            )
                            .frame(height: 80)
                        }
                    }
                }
                
                if wallet != nil {
                    Section {
                        PortfolioView(
                            userData: userData
                        )
                    } header: {
                        Text("Portfolio")
                    }
                } else {
                    Section {
                        NavigationLink(destination: ConnectWalletManuallyView()) {
                            Image(systemName: "wallet.bifold")
                            Text("Connect Wallet")
                        }
                    } header: {
                        Text("Connect Wallet")
                    }
                }
                
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
            .refreshable {
                syncRefreshData()
            }
        } detail: {
            Text("TODO")
        }
        .toolbar {
            if let compressedPolymarketAddress = wallet?.compressedPolymarketAddress {
                ToolbarItem {
                    Menu {
                        Button("Connect a different wallet") {
                            connectWallet()
                        }
                        Button("Disconnect wallet") {
                            disconnectWallet()
                        }
                    } label: {
                        Image(systemName: "wallet.bifold")
                        Text(compressedPolymarketAddress)
                    }
                }
            }
        }
        .sheet(isPresented: $isConnectWalletPresented) {
            ConnectWalletManuallyView()
        }
        .onChange(of: wallet) { _, wallet in
            syncRefreshData()
        }
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
}

#Preview {
    HomeView(wallet: WalletConnectModel(
        walletAddress: nil,
        polymarketAddress: "0x1234567890123456789012345678901234567890"
    ))
}
