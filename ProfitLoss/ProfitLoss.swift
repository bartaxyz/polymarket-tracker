//
//  ProfitLoss.swift
//  ProfitLoss
//
//  Created by Ondřej Bárta on 27/4/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct ProfitLossEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text("Profit & Loss")
            .bold()
        Text("Wallet Address:")
        Text(entry.configuration.walletAddress ?? "No wallet connected")
    }
}

struct ProfitLoss: Widget {
    let kind: String = "ProfitLoss"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            ProfitLossEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var noWalletAddress: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        return intent
    }
    
    fileprivate static var withWalletAddress: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.walletAddress = "0x8Dc1Ec002D1D7071b4aA5e14dFf44cEc9cd60677"
        return intent
    }
}

#Preview(as: .systemSmall) {
    ProfitLoss()
} timeline: {
    SimpleEntry(date: .now, configuration: .noWalletAddress)
    SimpleEntry(date: .now, configuration: .withWalletAddress)
}
