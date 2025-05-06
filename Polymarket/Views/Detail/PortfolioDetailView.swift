//
//  PortfolioDetailView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 6/5/25.
//

import SwiftUI

struct PortfolioDetailView: View {
    var userData: PolymarketDataService.UserData?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Portfolio Value Card
                if let portfolioValue = userData?.portfolioValue {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Portfolio Value")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(portfolioValue, format: .currency(code: "USD"))
                            .font(.title)
                            .bold()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // PnL Chart Card
                if let pnlData = userData?.pnlData {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today's Performance")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if let firstValue = pnlData.first?.p,
                           let lastValue = pnlData.last?.p {
                            let change = lastValue - firstValue
                            let percentChange = (change / firstValue) * 100
                            
                            HStack {
                                Text(change, format: .currency(code: "USD"))
                                    .font(.title2)
                                    .bold()
                                    .foregroundStyle(change >= 0 ? .green : .red)
                                Text("(\(percentChange, format: .number.precision(.fractionLength(2)))%)")
                                    .font(.title3)
                                    .foregroundStyle(change >= 0 ? .green : .red)
                            }
                        }
                        
                        ProfitLossChart(data: pnlData)
                            .frame(height: 200)
                    }
                    .padding()
                    .background(.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Positions List
                if let positions = userData?.positions {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Positions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        ForEach(positions, id: \.conditionId) { position in
                            VStack {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(position.title)
                                            .font(.headline)
                                            .lineLimit(2)
                                        Text(position.outcome)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(position.currentValue, format: .currency(code: "USD"))
                                            .font(.headline)
                                        Text(position.percentPnl / 100, format: .percent.precision(.fractionLength(2)))
                                            .foregroundStyle(position.percentPnl >= 0 ? .green : .red)
                                    }
                                }
                                
                                Divider()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Portfolio")
    }
}

#Preview {
    NavigationStack {
        PortfolioDetailView(userData: PolymarketDataService.UserData(
            portfolioValue: 1234.56,
            pnlData: [
                .init(t: Calendar.current.date(byAdding: .hour, value: -6, to: .now)!, p: 1200),
                .init(t: Calendar.current.date(byAdding: .hour, value: -4, to: .now)!, p: 1300),
                .init(t: Calendar.current.date(byAdding: .hour, value: -2, to: .now)!, p: 1250),
                .init(t: .now, p: 1234.56)
            ],
            positions: [
                .init(
                    proxyWallet: "0x123",
                    asset: "0xabc",
                    conditionId: "1",
                    size: 100,
                    avgPrice: 0.8,
                    initialValue: 80,
                    currentValue: 100,
                    cashPnl: 20,
                    percentPnl: 25,
                    totalBought: 80,
                    realizedPnl: 0,
                    percentRealizedPnl: 0,
                    curPrice: 1.0,
                    redeemable: false,
                    mergeable: false,
                    title: "Will BTC reach $100k by end of 2024?",
                    slug: "btc-100k-2024",
                    icon: "",
                    eventSlug: "crypto",
                    outcome: "Yes",
                    outcomeIndex: 0,
                    oppositeOutcome: "No",
                    oppositeAsset: "0xdef",
                    endDate: "2024-12-31",
                    negativeRisk: false
                )
            ]
        ))
    }
}
