//
//  PortfolioView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 5/5/25.
//

import SwiftUI

struct PortfolioView: View {
    var userData: PolymarketDataService.UserData?
    
    var body: some View {

        /*NavigationLink(
            destination: PortfolioDetailView(userData: userData)
        ) {
            VStack {
                if let portfolioValue = userData?.portfolioValue {
                    HStack {
                        Text(portfolioValue, format: .currency(code: "USD"))
                            .bold()
                        Spacer()
                        Text(portfolioValue, format: .currency(code: "USD"))
                            .bold()
                    }
                    .padding()
                }
                
                if let pnlData = userData?.pnlData {
                    ProfitLossChart(
                        data: pnlData,
                        // hideXAxis: true,
                        // hideYAxis: true
                    )
                    .frame(height: 80)
                }
            }
        }*/
                
        ForEach(userData?.positions ?? [], id: \.conditionId) { position in
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
    }
}

#Preview {
    PortfolioView()
}
