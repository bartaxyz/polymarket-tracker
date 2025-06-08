//
//  SearchView.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 16/5/25.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject private var dataService = PolymarketDataService.shared
    let searchQuery: String
    @State private var selectedEventId: String?
    
    init(initialQuery: String) {
        self.searchQuery = initialQuery
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                
                // Results
                if dataService.isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if dataService.searchResults.isEmpty && !searchQuery.isEmpty {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search term")
                    )
                } else {
                    List {
                        ForEach(dataService.searchResults, id: \.id) { event in
                            NavigationLink(destination: MarketDetailView(market: .event(event))) {
                                EventRowView(event: event)
                            }
                        }
                        
                        if dataService.hasMoreSearchResults {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .onAppear {
                                    loadMoreResults()
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Results for '\(searchQuery)'")
            .onAppear {
                // Automatically perform search when view appears
                performSearch()
            }
        }
    }
    
    private func performSearch() {
        Task {
            await dataService.searchEvents(query: searchQuery)
        }
    }
    
    private func loadMoreResults() {
        Task {
            await dataService.loadMoreSearchResults()
        }
    }
}

private struct EventRowView: View {
    let event: PolymarketDataService.Event
    
    var body: some View {
        HStack(spacing: 12) {
            if let imageUrl = event.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 40, height: 40)
                .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .lineLimit(2)
                    .font(.subheadline)
                
                if let volume = event.volume {
                    Text("Volume: $\(String(format: "%.2f", volume))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SearchView(initialQuery: "Bitcoin")
}
