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
                        .padding(.vertical, 8)
                    }
                    .scrollClipDisabled()
                    
                    if isLoading && events.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
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



#Preview {
    DiscoveryView()
}
