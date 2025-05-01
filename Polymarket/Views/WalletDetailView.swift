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
    
    @State private var isDeleteConfirmationPresented = false
    
    var body: some View {
        VStack {
            Text(wallet.polymarketAddress!)
                .font(.title)
            Text("$1 000 000")
                .font(.caption)
                .opacity(0.5)
        }
        .navigationTitle(wallet.compressedPolymarketAddress!)
        .toolbar {
            ToolbarItem {
                Button(action: showDeleteConfirmation) {
                    Image(systemName: "trash")
                }
            }
        }.confirmationDialog("Are you sure you want to delete this wallet?", isPresented: $isDeleteConfirmationPresented) {
            Button("Delete", role: .destructive) {
                deleteWallet()
            }
            Button("Cancel", role: .cancel) { }
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
}

#Preview {
    WalletDetailView(
        wallet: WalletConnectModel(
            walletAddress: "0x...",
            polymarketAddress: "0x...",
        )
    )
}
