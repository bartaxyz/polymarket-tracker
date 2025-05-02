//
//  SidebarPortfolioValueComponent.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import SwiftUI

struct PortfolioValueCaption: View {
    var polymarketAddress: String
    
    @State var value: Double? = nil
    
    var body: some View {
        Text(value ?? 0.0, format: .currency(code: "USD"))
            .font(.caption)
            .opacity(0.5)
            .task {
                await fetchValue()
            }
    }
    
    func fetchValue() async {
        value = try? await PolymarketDataService.fetchPortfolio(userId: polymarketAddress)
    }
}

#Preview {
    PortfolioValueCaption(
        polymarketAddress: "0x235A480a9CCB7aDA0Ad2DC11dAC3a11FB433Febd"
    )
    .padding()
}
