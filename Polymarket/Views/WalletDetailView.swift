//
//  WalletDetailView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import SwiftUI

struct WalletDetailView: View {
    let wallet: WalletConnectModel
    @State private var userData: PolymarketDataService.UserData?
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let error = error {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("Retry") {
                        Task {
                            await refreshData()
                        }
                    }
                }
            } else if let userData = userData {
                ScrollView {
                    VStack(spacing: 20) {
                        if let portfolioValue = userData.portfolioValue {
                            VStack(alignment: .leading) {
                                Text("Portfolio Value")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(portfolioValue, format: .currency(code: "USD"))
                                    .font(.title)
                                    .bold()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        if let pnlData = userData.pnlData {
                            VStack(alignment: .leading) {
                                Text("Profit & Loss")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                ProfitLossChart(data: pnlData)
                                    .frame(height: 200)
                            }
                            .padding()
                            .background(.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await refreshData()
                }
            }
        }
        .navigationTitle(wallet.compressedPolymarketAddress ?? "Wallet")
        .task {
            await refreshData()
        }
    }
    
    private func refreshData() async {
        guard let address = wallet.polymarketAddress else { return }
        
        isLoading = true
        error = nil
        
        do {
            userData = await PolymarketDataService.fetchUserData(userId: address)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        WalletDetailView(wallet: WalletConnectModel(
            walletAddress: nil,
            polymarketAddress: "0x1234567890123456789012345678901234567890"
        ))
    }
}
