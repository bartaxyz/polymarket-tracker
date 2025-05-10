//
//  PortfolioView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 5/5/25.
//

import SwiftUI

struct PortfolioSidebarSectionView: View {
    var userId: String
    var userData: PolymarketDataService.UserData?
    
    var body: some View {
        Section {
            ProfitLossChart(
                userId: userId,
                showHeader: true,
                showPicker: true,
                range: .today,
            )
            .frame(height: 200)
        } header: {
            Text("Portfolio")
        }
        
        if let positions = userData?.positions {
            Section {
                ForEach(positions, id: \.conditionId) { position in
                    NavigationLink(
                        destination: PositionDetailView(position: position)
                    ) {
                        VStack(alignment: .leading) {
                            Text(position.title)
                                .lineLimit(3)
                                .font(.callout)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(position.outcome)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        VStack(alignment: .trailing) {
                            Text(position.currentValue, format: .currency(code: "USD"))
                                .bold()
                            Text(position.percentPnl / 100, format: .percent.precision(.fractionLength(2)))
                                .foregroundColor(position.percentPnl >= 0 ? .green : .red)
                        }
                    }
                }
            } header: {
                Text("Positions")
            }
        }
    }
}

#Preview {
    PortfolioSidebarSectionView(
        userId: "0x235A480a9CCB7aDA0Ad2DC11dAC3a11FB433Febd"
    )
}
