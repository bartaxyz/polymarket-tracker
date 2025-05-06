//
//  ConnectWalletManually.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import SwiftUI

struct ConnectWalletManuallyView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var context;
    @Environment(\.dismiss) var dismissNavigation;
    @State var polymarketAddress: String = "";
    @State var error: Error? = nil;
    
    var isCancellable = true;
    
    var body: some View {
        NavigationStack {
            Form {
                Section() {
                    Text("1. Visit [Polymarket website](https://polymarket.com), and connect your wallet")
                    
                    VStack(alignment: .leading) {
                        Text("2. Click on your profile icon in the top right & copy your Polymarket address")
                        
                        Image(colorScheme == .dark ? "CopyAddressDark" : "CopyAddressLight")
                            .resizable()
                            .scaledToFit()
                            .frame(idealWidth: 400, idealHeight: 200)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    TextField("3. Paste your address here:", text: $polymarketAddress)
                    
                    if error != nil {
                        Text("Invalid address format. The address should be in the format of 0x..., and have 36 characters.")
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Connect your Polymarket address")
                }
            }
            .formStyle(.grouped)
            .toolbar {
                if isCancellable {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: cancel) {
                            Text("Cancel")
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: connectWallet) {
                        Text("Connect Wallet")
                    }
                }
            }
        }
    }
    
    private func cancel() {
        dismiss()
    }
    
    private func dismiss() {
        if isCancellable {
            dismissNavigation()
        }
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
