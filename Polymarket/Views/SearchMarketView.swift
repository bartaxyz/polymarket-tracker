//
//  SearchMarketView.swift
//  Polymarket
//

import SwiftUI

struct SearchMarketView: View {
    @ObservedObject private var dataService = PolymarketDataService.shared
    @State private var searchQuery = ""

    var body: some View {
        Group {
            if dataService.isSearching && dataService.searchResults.isEmpty {
                ProgressView("Searching...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !searchQuery.isEmpty && dataService.searchResults.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search term")
                )
            } else if dataService.searchResults.isEmpty {
                ContentUnavailableView(
                    "Search Markets",
                    systemImage: "magnifyingglass",
                    description: Text("Find prediction markets on politics, tech, crypto, and more")
                )
            } else {
                List {
                    ForEach(dataService.searchResults, id: \.id) { event in
                        NavigationLink(destination: MarketDetailView(market: .gammaEvent(event))) {
                            SearchEventRow(event: event)
                        }
                    }
                    if dataService.hasMoreSearchResults {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .onAppear {
                                Task { await dataService.loadMoreSearchResults() }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Search")
        .searchable(text: $searchQuery, prompt: "Search markets...")
        .onSubmit(of: .search) {
            Task { await dataService.searchEvents(query: searchQuery) }
        }
        .onChange(of: searchQuery) { _, newValue in
            if newValue.isEmpty {
                dataService.clearSearchResults()
            } else {
                Task { await dataService.searchEvents(query: newValue) }
            }
        }
    }
}
