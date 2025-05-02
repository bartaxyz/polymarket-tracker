//
//  Portfolio.swift
//  Portfolio
//
//  Created by Ondřej Bárta on 1/5/25.
//

import Foundation
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
    @Environment(\.widgetFamily) private var widgetFamily
    @Query var wallets: [WalletConnectModel]
    var entry: Provider.Entry

    var body: some View {
        let todayPnLRaw = (entry.pnl?.last?.p ?? 0.0) - (entry.pnl?.first?.p ?? 0.0)
        let todayPnL = todayPnLRaw.formatted(
            .number
                .precision(.fractionLength(2))
                .sign(strategy: .always())
        )
        
        let portfolioValue = "$\u{202F}" + (entry.portfolioValue ?? 0.0)
            .formatted(.number.precision(.fractionLength(2)))
#if os(macOS)
        let titleFont = Font.largeTitle;
#else
        let titleFont = Font.title;
#endif
        
        // Normalize PnL: subtract the last PnL point, then add the portfolio value
        let data: [PolymarketDataService.PnLDataPoint] = {
            let raw = entry.pnl ?? []
            let lastP = raw.last?.p ?? 0.0
            let base  = entry.portfolioValue ?? 0.0
            return raw.map { point in
                PolymarketDataService.PnLDataPoint(
                    t: point.t,
                    p: point.p - lastP + base
                )
            }
        }()
        
        switch widgetFamily {
        case .accessoryRectangular:
            HStack {
                Text(portfolioValue)
                Spacer()
                Text(todayPnL)
            }
            ProfitLossChart(
                data: data,
                hideXAxis: true,
                hideYAxis: true
            )
        case .systemSmall:
            VStack(alignment: .leading) {
                Text("Portfolio")
                    .font(.caption)
                    .opacity(0.5)
                HStack {
                    Text("Profit / Loss")
                    Spacer()
                    Text(todayPnL)
                }
                ProfitLossChart(
                    data: data,
                    hideXAxis: true,
                    hideYAxis: true
                )
                HStack {
                    Spacer()
                    Text(portfolioValue)
                        .font(titleFont)
                }
            }
        default:
            HStack {
                VStack(alignment: .leading) {
                    Text("Portfolio")
                        .font(.caption)
                        .opacity(0.5)
                    Text(portfolioValue)
                        .font(titleFont)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Profit / Loss")
                        .font(.caption)
                        .opacity(0.5)
                    Text(todayPnL)
                        .font(titleFont)
                }
            }
            ProfitLossChart(data: data)
        }
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
#if os(macOS)
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
        ])
#else
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular
        ])
#endif
    }
}
