//
//  DiscoveryView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 13/5/25.
//

import SwiftUI

struct DiscoveryView: View {
    @StateObject private var viewModel = DiscoveryViewModel()
    @State private var selectedTag: String?
    
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
                                    Task {
                                        await viewModel.fetchEvents()
                                    }
                                }
                            )
                            
                            ForEach(viewModel.tags, id: \.id) { tag in
                                TagButton(
                                    tag: tag,
                                    isSelected: selectedTag == tag.slug,
                                    action: {
                                        selectedTag = tag.slug
                                        Task {
                                            await viewModel.fetchEvents(withTag: tag.slug)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.events, id: \.id) { event in
                                EventCard(event: event)
                            }
                            
                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .gridCellColumns(columns.count)
                            } else if viewModel.hasMoreEvents {
                                Button(action: {
                                    Task {
                                        await viewModel.loadMoreEvents()
                                    }
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
                await viewModel.fetchTags()
                await viewModel.fetchEvents()
            }
            .refreshable {
                await viewModel.fetchTags()
                await viewModel.fetchEvents(withTag: selectedTag)
            }
        }
    }
}

struct TagButton: View {
    let tag: PolymarketDataService.Tag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag.label)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
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
                                Text(tag.label)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding(12)
            .cornerRadius(12)
            .shadow(radius: 2)
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

@MainActor
class DiscoveryViewModel: ObservableObject {
    @Published private(set) var tags: [PolymarketDataService.Tag] = []
    @Published private(set) var events: [PolymarketDataService.GammaEvent] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMoreEvents = false
    
    private var currentOffset = 0
    private let pageSize = 20
    private var currentTagSlug: String? = nil
    
    func fetchTags() async {
        do {
            tags = try await PolymarketDataService.shared.fetchTags()
        } catch {
            print("Error fetching tags: \(error)")
        }
    }
    
    func fetchEvents(withTag tagSlug: String? = nil) async {
        guard !isLoading else { return }
        
        isLoading = true
        currentOffset = 0
        currentTagSlug = tagSlug
        
        do {
            let response = try await PolymarketDataService.shared.fetchPaginatedEvents(
                limit: pageSize,
                offset: currentOffset,
                tagSlug: tagSlug
            )
            events = response.data
            hasMoreEvents = response.pagination.hasMore
        } catch {
            print("Error fetching events: \(error)")
        }
        
        isLoading = false
    }
    
    func loadMoreEvents() async {
        guard !isLoading && !isLoadingMore && hasMoreEvents else { return }
        
        isLoadingMore = true
        currentOffset += pageSize
        
        do {
            let response = try await PolymarketDataService.shared.fetchPaginatedEvents(
                limit: pageSize,
                offset: currentOffset,
                tagSlug: currentTagSlug
            )
            events.append(contentsOf: response.data)
            hasMoreEvents = response.pagination.hasMore
        } catch {
            print("Error loading more events: \(error)")
            currentOffset -= pageSize
        }
        
        isLoadingMore = false
    }
}

#Preview {
    DiscoveryView()
}
