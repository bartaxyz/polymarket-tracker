//
//  PositionDetailView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 6/5/25.
//

import SwiftUI

struct PositionDetailView: View {
    var position: PolymarketDataService.Position
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Market Title and Icon
                VStack(alignment: .leading, spacing: 8) {
                    if !position.icon.isEmpty {
                        AsyncImage(url: URL(string: position.icon)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                        } placeholder: {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text(position.title)
                        .font(.title2)
                        .bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Position Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Position Details")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                        GridRow {
                            Text("Outcome")
                                .foregroundStyle(.secondary)
                            Text(position.outcome)
                                .bold()
                        }
                        GridRow {
                            Text("Size")
                                .foregroundStyle(.secondary)
                            Text(position.size, format: .number.precision(.fractionLength(2)))
                                .bold()
                        }
                        GridRow {
                            Text("Average Price")
                                .foregroundStyle(.secondary)
                            Text(position.avgPrice, format: .currency(code: "USD"))
                                .bold()
                        }
                        GridRow {
                            Text("Current Price")
                                .foregroundStyle(.secondary)
                            Text(position.curPrice, format: .currency(code: "USD"))
                                .bold()
                        }
                        GridRow {
                            Text("End Date")
                                .foregroundStyle(.secondary)
                            Text(position.endDate)
                                .bold()
                        }
                    }
                }
                .padding()
                .background(.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Performance Metrics
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                        GridRow {
                            Text("Initial Value")
                                .foregroundStyle(.secondary)
                            Text(position.initialValue, format: .currency(code: "USD"))
                                .bold()
                        }
                        GridRow {
                            Text("Current Value")
                                .foregroundStyle(.secondary)
                            Text(position.currentValue, format: .currency(code: "USD"))
                                .bold()
                        }
                        GridRow {
                            Text("Cash P&L")
                                .foregroundStyle(.secondary)
                            Text(position.cashPnl, format: .currency(code: "USD"))
                                .bold()
                                .foregroundStyle(position.cashPnl >= 0 ? .green : .red)
                        }
                        GridRow {
                            Text("% P&L")
                                .foregroundStyle(.secondary)
                            Text(position.percentPnl / 100, format: .percent.precision(.fractionLength(2)))
                                .bold()
                                .foregroundStyle(position.percentPnl >= 0 ? .green : .red)
                        }
                        GridRow {
                            Text("Realized P&L")
                                .foregroundStyle(.secondary)
                            Text(position.realizedPnl, format: .currency(code: "USD"))
                                .bold()
                                .foregroundStyle(position.realizedPnl >= 0 ? .green : .red)
                        }
                        GridRow {
                            Text("% Realized P&L")
                                .foregroundStyle(.secondary)
                            Text(position.percentRealizedPnl / 100, format: .percent.precision(.fractionLength(2)))
                                .bold()
                                .foregroundStyle(position.percentRealizedPnl >= 0 ? .green : .red)
                        }
                    }
                }
                .padding()
                .background(.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Market Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Market Details")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                        GridRow {
                            Text("Event")
                                .foregroundStyle(.secondary)
                            Text(position.eventSlug.capitalized)
                                .bold()
                        }
                        GridRow {
                            Text("Opposite Outcome")
                                .foregroundStyle(.secondary)
                            Text(position.oppositeOutcome)
                                .bold()
                        }
                        GridRow {
                            Text("Status")
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                if position.redeemable {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Redeemable")
                                        .bold()
                                        .foregroundStyle(.green)
                                }
                                if position.mergeable {
                                    Image(systemName: "arrow.triangle.merge")
                                        .foregroundStyle(.blue)
                                    Text("Mergeable")
                                        .bold()
                                        .foregroundStyle(.blue)
                                }
                                if !position.redeemable && !position.mergeable {
                                    Image(systemName: "clock")
                                        .foregroundStyle(.secondary)
                                    Text("Active")
                                        .bold()
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle("Position Details")
    }
}

#Preview {
    NavigationStack {
        PositionDetailView(position: PolymarketDataService.Position(
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
            realizedPnl: 10,
            percentRealizedPnl: 12.5,
            curPrice: 1.0,
            redeemable: true,
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
        ))
    }
}
