//
//  Portfolio.swift
//  Portfolio
//
//  Created by Ondřej Bárta on 1/5/25.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            polymarketAddress: nil,
            portfolioValue: nil,
            pnl: nil,
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            polymarketAddress: nil,
            portfolioValue: nil,
            pnl: nil,
            configuration: configuration
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        
        let descriptor = FetchDescriptor<WalletConnectModel>()
        
        let wallets: [WalletConnectModel]? = try? (await SharedModelContainer.container.mainContext.fetch(descriptor))
        
        let polymarketAddress = wallets?.first?.polymarketAddress ?? nil
        
        let portfolioValue: Double? = try? await PolymarketDataService.fetchPortfolio(userId: polymarketAddress ?? "")
        let pnl = try? await PolymarketDataService.fetchPnL(userId: polymarketAddress!)
        
        
        let entry = SimpleEntry(
            date: Date(),
            polymarketAddress: polymarketAddress,
            portfolioValue: portfolioValue,
            pnl: pnl,
            configuration: configuration
        )
        
        entries.append(entry)

        return Timeline(entries: entries, policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let polymarketAddress: String?
    let portfolioValue: Double?
    let pnl: [PolymarketDataService.PnLDataPoint]?
    let configuration: ConfigurationAppIntent
}

struct PortfolioEntryView : View {
    @Query var wallets: [WalletConnectModel]
    var entry: Provider.Entry

    var body: some View {
        Text(entry.polymarketAddress ?? "")
        HStack {
            HStack {
                Text("Portfolio:")
                Text("$\(entry.portfolioValue ?? 0.0)")
            }
            Spacer()
            HStack {
                Text("PnL:")
                Text("$\((entry.pnl?.last?.p ?? 0.0) - (entry.pnl?.first?.p ?? 0.0))")
            }
        }
        ProfitLossChart(data: entry.pnl ?? [])
    }
}

struct Portfolio: Widget {
    let kind: String = "Portfolio"
    
    var sharedModelContainer: ModelContainer = {
        return SharedModelContainer.container
    }()

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            PortfolioEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .modelContainer(sharedModelContainer)
        }
    }
}
