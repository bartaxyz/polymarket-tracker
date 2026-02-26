//
//  SearchMarketView.swift
//  Polymarket
//

import SwiftUI

struct SearchMarketView: View {
    @ObservedObject private var dataService = PolymarketDataService.shared
    @State private var searchQuery = ""
    @State private var isSearchActive = false
    @State private var debounceTask: Task<Void, Never>?

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
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Search")
        .searchable(text: $searchQuery, isPresented: $isSearchActive, prompt: "Search markets...")
        .onSubmit(of: .search) {
            Task { await dataService.searchEvents(query: searchQuery) }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchActive = true
            }
        }
        .onChange(of: searchQuery) { _, newValue in
            debounceTask?.cancel()
            if newValue.isEmpty {
                dataService.clearSearchResults()
            } else {
                let query = newValue
                debounceTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    // Launch search in a non-cancellable detached task
                    // so cancelling the next debounce won't kill this request
                    Task.detached {
                        await dataService.searchEvents(query: query)
                    }
                }
            }
        }
    }
}
