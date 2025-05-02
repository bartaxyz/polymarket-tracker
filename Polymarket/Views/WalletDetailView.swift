//
//  WalletDetailView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import SwiftUI

struct WalletDetailView: View {
    @Environment(\.modelContext) var context;
    @Environment(\.dismiss) var dismiss
    
    var wallet: WalletConnectModel
    
    @State private var data: [PolymarketDataService.PnLDataPoint] = []
    @State private var isDeleteConfirmationPresented = false
    
    var body: some View {
        VStack {
            Text(wallet.polymarketAddress!)
                .font(.title)
            PortfolioValueCaption(
                polymarketAddress: wallet.polymarketAddress!
            )
            ProfitLossChart(data: data)
        }
        .navigationTitle(wallet.compressedPolymarketAddress!)
        .toolbar {
            ToolbarItem {
                Button(action: showDeleteConfirmation) {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Are you sure you want to delete this wallet?", isPresented: $isDeleteConfirmationPresented) {
            Button("Delete", role: .destructive) {
                deleteWallet()
            }
            Button("Cancel", role: .cancel) { }
        }
        .task {
            await fetchPnl()
        }
    }
    
    private func showDeleteConfirmation() {
        isDeleteConfirmationPresented = true
    }
    
    private func deleteWallet() {
        context.delete(wallet)
        try? context.save()
        dismiss()
    }
    
    private func fetchPnl() async {
        let dataPoints = try? await PolymarketDataService.fetchPnL(userId: wallet.polymarketAddress!)
        data = dataPoints ?? []
        print(data)
    }
}

#Preview {
    WalletDetailView(
        wallet: WalletConnectModel(
            walletAddress: "0x235A480a9CCB7aDA0Ad2DC11dAC3a11FB433Febd",
            polymarketAddress: "0x235A480a9CCB7aDA0Ad2DC11dAC3a11FB433Febd",
        )
    )
}
