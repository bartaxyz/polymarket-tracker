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
                        VStack(alignment: .trailing, spacing: 2) {
                            CurrencyText(
                                amount: position.cashPnl,
                                signature: .always,
                                isDelta: true,
                                // hasBackground: true
                            )
                            .fontWeight(.semibold)
                            .font(.caption)
                            PercentageText(
                                amount: position.percentPnl / 100,
                                signature: .never,
                                hasArrow: true
                            )
                            .font(.caption)
                            .opacity(0.5)
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
    .frame(width: 320)
    .padding()
}
