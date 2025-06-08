//
//  PortfolioView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 5/5/25.
//

import SwiftUI

struct PortfolioSidebarSectionView: View {
    @ObservedObject private var dataService = PolymarketDataService.shared
    
    var body: some View {
        Section {
            PortfolioView(
                showHeader: true,
                showPicker: true,
            )
            .frame(height: 200)
        } header: {
            Text("Portfolio")
        }
        
        if let positions = dataService.positions {
            Section {
                ForEach(positions, id: \.conditionId) { position in
                    NavigationLink(
                        destination: PositionDetailView(position: position)
                    ) {
                        Label {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(position.title)
                                        .lineLimit(2)
                                        .font(.callout)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(position.outcome)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                VStack(alignment: .trailing, spacing: 2) {
                                    CurrencyText(amount: position.currentValue)

                                    PercentageText(
                                        amount: position.percentPnl / 100,
                                        signature: .never,
                                        isDelta: true,
                                        hasArrow: true,
                                    )
                                    .font(.caption)
                                }
                            }
                        } icon: {
                            Image(systemName: "smallcircle.filled.circle")
                            // Image(systemName: position.cashPnl >= 0 ? "arrow.up" : "arrow.down")
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
    PortfolioSidebarSectionView()
        .frame(width: 320, height: 480)
    .padding()
}
