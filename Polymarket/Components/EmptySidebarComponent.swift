//
//  EmptySidebarComponent.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import SwiftUI

struct EmptySidebarComponent: View {
    @State var action: () -> Void = { }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "wallet.bifold")
                
                Text("Connect your Polymarket wallet")
                    .multilineTextAlignment(.center)
            }
            
            Button(action: action) {
                Image(systemName: "plus")
                Text("Connect Wallet")
            }
        }
    }
}

#Preview {
    EmptySidebarComponent()
}
