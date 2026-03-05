//
//  PositionDetailView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 6/5/25.
//

import SwiftUI
import Charts

struct PositionDetailView: View {
    var position: PolymarketDataService.Position
    @ObservedObject private var dataService = PolymarketDataService.shared
    @State private var priceHistory: [PolymarketDataService.PnLDataPoint] = []
    @State private var isLoadingChart = false
    @State private var selectedRange: PolymarketDataService.PnLRange = .max
    
    private var intervalForRange: PolymarketDataService.PnLInterval {
        selectedRange.interval
    }
    
    private var fidelityForRange: Int {
        switch selectedRange {
        case .today, .day: return 60
        case .week: return 60
        case .month: return 60
        case .max: return 60
        }
    }
    
    var body: some View {
        List {
            // Price Chart
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    // Range selector
                    Picker("Range", selection: $selectedRange) {
                        ForEach(PolymarketDataService.PnLRange.allCases, id: \.self) { range in
                            Text(range.label).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedRange) {
                        Task { await loadPriceHistory() }
                    }
                    
                    if isLoadingChart {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if priceHistory.isEmpty {
                        Text("No chart data available")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        ProfitLossChart(
                            data: priceHistory,
                            range: selectedRange,
                            hideWatermark: true
                        )
                        .frame(height: 200)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Price History")
            }
            
            // Header with Title and Status
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(position.title)
                        .font(.title2)
                        .bold()
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 8) {
                        if position.redeemable {
                            StatusLabel(text: "Redeemable", systemImage: "checkmark.circle.fill", color: .green)
                        }
                        if position.mergeable {
                            StatusLabel(text: "Mergeable", systemImage: "arrow.triangle.merge", color: .blue)
                        }
                        if !position.redeemable && !position.mergeable {
                            StatusLabel(text: "Active", systemImage: "clock", color: .secondary)
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 8)
            }
            
            // Quick Stats
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current Value")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(position.currentValue, format: .currency(code: "USD"))
                            .font(.title3)
                            .bold()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("P&L")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(position.percentPnl / 100, format: .percent.precision(.fractionLength(2)))
                            .font(.title3)
                            .bold()
                            .foregroundStyle(position.percentPnl >= 0 ? .green : .red)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Position Details
            Section(header: Text("Position Details")) {
                LabeledContent("Outcome") {
                    Text(position.outcome)
                        .bold()
                }
                
                LabeledContent("Size") {
                    Text(position.size, format: .number.precision(.fractionLength(2)))
                        .bold()
                }
                
                LabeledContent("Average Price") {
                    Text(position.avgPrice, format: .currency(code: "USD"))
                        .bold()
                }
                
                LabeledContent("Current Price") {
                    Text(position.curPrice, format: .currency(code: "USD"))
                        .bold()
                }
                
                LabeledContent("End Date") {
                    Text(position.endDate)
                        .bold()
                }
            }
            
            // Performance Metrics
            Section(header: Text("Performance")) {
                LabeledContent("Initial Value") {
                    Text(position.initialValue, format: .currency(code: "USD"))
                        .bold()
                }
                
                LabeledContent("Cash P&L") {
                    Text(position.cashPnl, format: .currency(code: "USD"))
                        .bold()
                        .foregroundStyle(position.cashPnl >= 0 ? .green : .red)
                }
                
                LabeledContent("Realized P&L") {
                    Text(position.realizedPnl, format: .currency(code: "USD"))
                        .bold()
                        .foregroundStyle(position.realizedPnl >= 0 ? .green : .red)
                }
                
                LabeledContent("% Realized P&L") {
                    Text(position.percentRealizedPnl / 100, format: .percent.precision(.fractionLength(2)))
                        .bold()
                        .foregroundStyle(position.percentRealizedPnl >= 0 ? .green : .red)
                }
            }
            
            // Market Details
            Section(header: Text("Market Details")) {
                LabeledContent("Event") {
                    Text(position.eventSlug.capitalized)
                        .bold()
                }
                
                LabeledContent("Opposite Outcome") {
                    Text(position.oppositeOutcome)
                        .bold()
                }
            }
            
            // Web Link
            Section {
                Link(destination: URL(string: "https://polymarket.com/event/\(position.slug)")!) {
                    HStack {
                        Image(systemName: "globe")
                        Text("View on Polymarket.com")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Position Details")
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .task {
            await loadPriceHistory()
        }
    }
    
    private func loadPriceHistory() async {
        isLoadingChart = true
        do {
            priceHistory = try await dataService.fetchTokenPriceHistory(
                tokenId: position.asset,
                interval: intervalForRange,
                fidelity: fidelityForRange
            )
        } catch {
            priceHistory = []
        }
        isLoadingChart = false
    }
}

// Helper view for status labels
struct StatusLabel: View {
    let text: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.subheadline)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
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
