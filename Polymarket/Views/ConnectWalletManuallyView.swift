//
//  ConnectWalletManually.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import SwiftUI

struct ConnectWalletManuallyView: View {
    @Environment(\.modelContext) var context;
    @Environment(\.dismiss) var dismiss;
    @State var polymarketAddress: String = "";
    @State var error: Error? = nil;
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Copy & paste your polymarket address")
                Text("This is not your wallet address. You can find this in the Polymarket UI.")
                    .font(.caption)
                    .opacity(0.5)
            }
            .padding([.horizontal, .top])
            
            Form {
                TextField("Polymarket Address", text: $polymarketAddress)
                    .textFieldStyle(.roundedBorder)
                
                if error != nil {
                    Text("Invalid address format. The address should be in the format of 0x..., and have 36 characters.")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }
            .formStyle(.grouped)
            .frame(minHeight: 80)
            .toolbar() {
                ToolbarItem(placement: .destructiveAction) {
                    Button(action: cancel) {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: connectWallet) {
                        Text("Connect Wallet")
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private func cancel() {
        dismiss()
    }
    
    private func validateAddress() {
        
    }
    
    private func connectWallet() {
        let isValid =  WalletConnectModel.validatePolymarketAddress(polymarketAddress)
        
        if !isValid {
            error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid address"])
            return
        }
        
        let wallet = WalletConnectModel(
            walletAddress: nil,
            polymarketAddress: polymarketAddress
        )
        
        context.insert(wallet)
        try? context.save()
        
        dismiss()
    }
}

#Preview {
    ConnectWalletManuallyView()
}
