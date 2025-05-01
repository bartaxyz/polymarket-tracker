//
//  ProfitLoss.swift
//  ProfitLoss
//
//  Created by Ondřej Bárta on 27/4/25.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        return entry
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
        VStack {
            Text("Profit & Loss")
                .bold()
                .padding(.bottom, 4)
            
            /*if let wallet = entry.configuration.wallet {
                Text("Wallet:")
                    .font(.caption)
                Text(wallet.displayAddress)
                    .font(.caption2)
            } else {
                Text("No wallet selected")
                    .font(.caption)
            }*/
        }
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
