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
    @State private var searchQuery = ""
    @ObservedObject private var dataService = PolymarketDataService.shared
    private let pageSize = 20
    
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            Group {
                if !searchQuery.isEmpty {
                    searchResultsView
                } else {
                    discoveryContentView
                }
            }
            .navigationTitle(searchQuery.isEmpty ? "Discover" : "Search Results")
            .searchable(text: $searchQuery, prompt: "Search markets...")
            .onSubmit(of: .search) {
                if !searchQuery.isEmpty {
                    Task {
                        await dataService.searchEvents(query: searchQuery)
                    }
                }
            }
            .onChange(of: searchQuery) { _, newValue in
                if newValue.isEmpty {
                    dataService.clearSearchResults()
                } else {
                    Task {
                        await dataService.searchEvents(query: newValue)
                    }
                }
            }
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
    
    private var searchResultsView: some View {
        Group {
            if dataService.isSearching {
                ProgressView("Searching...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if dataService.searchResults.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search term")
                )
            } else {
                List {
                    ForEach(dataService.searchResults, id: \.id) { event in
                        NavigationLink(destination: MarketDetailView(market: .gammaEvent(event))) {
                            SearchResultRowView(event: event)
                        }
                    }
                    
                    if dataService.hasMoreSearchResults {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .onAppear {
                                Task {
                                    await dataService.loadMoreSearchResults()
                                }
                            }
                    }
                }
            }
        }
    }
    
    private var discoveryContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TagBar(
                    tags: tags,
                    selectedTag: $selectedTag,
                    onTagSelected: { tagSlug in
                        loadEvents(withTagSlug: tagSlug)
                    }
                )
                
                if isLoading && events.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    LazyVGrid(columns: columns) {
                        ForEach(events, id: \.id) { event in
                            EventCard(event: event)
                                .padding(.bottom, 8)
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
                }
            }
            .padding()
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



struct SearchResultRowView: View {
    let event: PolymarketDataService.GammaEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Event Image
            Group {
                if let imageUrl = event.image, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            Color.gray.opacity(0.2)
                        case .empty:
                            Color.gray.opacity(0.2)
                        @unknown default:
                            Color.gray.opacity(0.2)
                        }
                    }
                } else {
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 16) {
                    if let volume = event.volume {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Volume")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formatSearchVolume(volume))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if let liquidity = event.liquidity {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Liquidity")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formatSearchVolume(liquidity))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // Market Indicator with gauge
            VStack(alignment: .center) {
                MarketIndicator(event: event)
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
    
    private func formatSearchVolume(_ number: Double) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", number / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", number / 1_000)
        } else {
            return String(format: "%.0f", number)
        }
    }
}

#Preview {
    DiscoveryView()
}
