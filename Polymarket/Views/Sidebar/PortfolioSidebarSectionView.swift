//
//  PortfolioView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 5/5/25.
//

import SwiftUI

struct PortfolioSidebarSectionView: View {
    @StateObject private var dataService = PolymarketDataService.shared
    
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
    PortfolioSidebarSectionView()
    .frame(width: 320)
    .padding()
}
