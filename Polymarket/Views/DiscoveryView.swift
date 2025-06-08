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
                    
                    // Market Indicator
                    MarketIndicator(event: event)
                }
                
                // Stats
                HStack(spacing: 16) {
                    StatView(title: "Volume", value: formatNumber(event.volume ?? 0))
                    StatView(title: "Liquidity", value: formatNumber(event.liquidity ?? 0))
                    StatView(title: "Markets", value: "\(event.markets.count)")
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.secondary.opacity(0.3), lineWidth: 0.5)
            )
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
