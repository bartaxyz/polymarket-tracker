//
//  DiscoveryView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 13/5/25.
//

import SwiftUI

struct DiscoveryView: View {
    // State
    @State private var tags: [PolymarketDataService.Tag] = []
    @State private var events: [PolymarketDataService.GammaEvent] = []
    @State private var selectedTag: String?
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var hasMoreEvents = false
    @State private var currentOffset = 0
    private let pageSize = 20
    
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // All tag
                            TagButton(
                                tag: PolymarketDataService.Tag(
                                    id: "all",
                                    label: "All",
                                    slug: "all",
                                    forceShow: nil,
                                    forceHide: nil,
                                    createdAt: nil,
                                    updatedAt: nil
                                ),
                                isSelected: selectedTag == nil,
                                action: {
                                    selectedTag = nil
                                    loadEvents()
                                }
                            )
                            
                            ForEach(tags, id: \.id) { tag in
                                TagButton(
                                    tag: tag,
                                    isSelected: selectedTag == tag.slug,
                                    action: {
                                        selectedTag = tag.slug
                                        loadEvents(withTagSlug: tag.slug)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if isLoading && events.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(events, id: \.id) { event in
                                EventCard(event: event)
                            }
                            
                            if isLoadingMore {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .gridCellColumns(columns.count)
                            } else if hasMoreEvents {
                                Button(action: {
                                    loadMoreEvents()
                                }) {
                                    Text("Load More")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                .gridCellColumns(columns.count)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Discover")
            .task {
                if tags.isEmpty {
                    await loadTags()
                }
                if events.isEmpty {
                    loadEvents(withTagSlug: selectedTag)
                }
            }
            .refreshable {
                await loadTags()
                loadEvents(withTagSlug: selectedTag)
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadTags() async {
        do {
            tags = try await PolymarketDataService.shared.fetchTags()
        } catch {
            if (error as NSError).code != NSURLErrorCancelled {
                print("Error fetching tags: \(error)")
            }
        }
    }
    
    private func loadEvents(withTagSlug tagSlug: String? = nil) {
        guard !isLoading else { return }
        
        Task { @MainActor in
            isLoading = true
            currentOffset = 0
            
            do {
                let response = try await PolymarketDataService.shared.fetchPaginatedEvents(
                    limit: pageSize,
                    offset: currentOffset,
                    tagSlug: tagSlug
                )
                
                events = response.data
                hasMoreEvents = response.pagination.hasMore
            } catch {
                if (error as NSError).code != NSURLErrorCancelled {
                    print("Error fetching events: \(error)")
                }
            }
            
            isLoading = false
        }
    }
    
    private func loadMoreEvents() {
        guard !isLoading && !isLoadingMore && hasMoreEvents else { return }
        
        Task { @MainActor in
            isLoadingMore = true
            let nextOffset = currentOffset + pageSize
            
            do {
                let response = try await PolymarketDataService.shared.fetchPaginatedEvents(
                    limit: pageSize,
                    offset: nextOffset,
                    tagSlug: selectedTag
                )
                
                events.append(contentsOf: response.data)
                hasMoreEvents = response.pagination.hasMore
                currentOffset = nextOffset
            } catch {
                if (error as NSError).code != NSURLErrorCancelled {
                    print("Error loading more events: \(error)")
                }
            }
            
            isLoadingMore = false
        }
    }
}

struct EventCard: View {
    let event: PolymarketDataService.GammaEvent
    
    private var primaryMarketChance: Double? {
        // Check if we have any markets
        guard !event.markets.isEmpty else {
            print("No markets for event: \(event.title)")
            return nil
        }
        
        let firstMarket = event.markets.first!
        print("Market question: \(firstMarket.question)")
        print("Outcome prices string: \(firstMarket.outcomePrices ?? "nil")")
        
        guard let outcomePricesString = firstMarket.outcomePrices,
              !outcomePricesString.isEmpty else {
            print("No outcome prices for market: \(firstMarket.question)")
            return nil
        }
        
        guard let data = outcomePricesString.data(using: .utf8),
              let prices = try? JSONDecoder().decode([Double].self, from: data),
              let firstPrice = prices.first else {
            print("Failed to parse outcome prices: \(outcomePricesString)")
            return nil
        }
        
        print("Parsed price: \(firstPrice)")
        return firstPrice
    }
    
    private var gaugeColor: Color {
        guard let chance = primaryMarketChance else { return .gray }
        if chance < 0.3 { return .red }
        else if chance < 0.7 { return .orange }
        else { return .green }
    }
    
    var body: some View {
        NavigationLink(destination: MarketDetailView(market: .gammaEvent(event))) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    // Event Image
                    if let imageUrl = event.image, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Title
                        Text(event.title)
                            .font(.headline)
                            .lineLimit(2)
                        
                        // Description
                        if let description = event.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    // Chance Gauge
                    VStack(spacing: 4) {
                        if let chance = primaryMarketChance {
                            Gauge(value: chance, in: 0...1) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                            } currentValueLabel: {
                                Text((chance * 100).formatted(.number.precision(.fractionLength(0))) + "%")
                                    .font(.caption2)
                                    .bold()
                            }
                            .gaugeStyle(.accessoryCircularCapacity)
                            .tint(gaugeColor)
                            .frame(width: 60, height: 60)
                            
                            Text("Chance")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            // Fallback: show a test gauge or placeholder
                            Gauge(value: 0.5, in: 0...1) {
                                Image(systemName: "questionmark")
                            } currentValueLabel: {
                                Text("--")
                                    .font(.caption2)
                                    .bold()
                            }
                            .gaugeStyle(.accessoryCircularCapacity)
                            .tint(.gray)
                            .frame(width: 60, height: 60)
                            
                            Text("No Data")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Stats
                HStack(spacing: 16) {
                    StatView(title: "Volume", value: formatNumber(event.volume ?? 0))
                    StatView(title: "Liquidity", value: formatNumber(event.liquidity ?? 0))
                    StatView(title: "Markets", value: "\(event.markets.count)")
                }
                
                // Tags
                if let tags = event.tags {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tags, id: \.id) { tag in
                                Tag(tag.label)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        if number >= 1_000_000 {
            return "\(formatter.string(from: NSNumber(value: number / 1_000_000)) ?? "")M"
        } else if number >= 1_000 {
            return "\(formatter.string(from: NSNumber(value: number / 1_000)) ?? "")K"
        } else {
            return formatter.string(from: NSNumber(value: number)) ?? "0"
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}


#Preview {
    DiscoveryView()
}
