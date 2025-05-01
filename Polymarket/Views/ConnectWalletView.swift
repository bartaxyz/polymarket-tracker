//
//  ConnectWalletView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import SwiftUI

struct ConnectWalletView: View {
    @Environment(\.dismiss) private var dismiss
    @State var isConnectWalletManuallyPresented: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    destination: ConnectWalletManuallyView(),
                ) {
                    Image(systemName: "square.on.square")
                    Text("Polygon Address")
                }
                
                NavigationLink(
                    destination: ConnectWalletManuallyView(),
                ) {
                    Image(systemName: "square.on.square")
                    Text("Wallet Address (unavailable)")
                }
                .disabled(true)
                .opacity(0.5)
                
                NavigationLink(
                    destination: ConnectWalletManuallyView(),
                ) {
                    Image(systemName: "square.on.square")
                    Text("Wallet Connect / Reown (unavailable)")
                }
                .disabled(true)
                .opacity(0.5)
            }
            .navigationTitle(Text("Connect Polymarket Address"))
        }
        .frame(minHeight: 320)
        .toolbar() {
            ToolbarItem(placement: .destructiveAction) {
                Button("Dismiss") {
                    dismiss()
                }
            }
        }
    }
    
    private func connectManually() {
        
    }
}

#Preview {
    ConnectWalletView()
}
