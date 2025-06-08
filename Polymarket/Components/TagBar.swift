//
//  TagBar.swift
//  Polymarket
//
//  Created by Claude on 6/8/25.
//

import SwiftUI

struct TagBar: View {
    let tags: [PolymarketDataService.Tag]
    @Binding var selectedTag: String?
    let onTagSelected: (String?) -> Void
    
    var body: some View {
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
                        onTagSelected(nil)
                    }
                )
                
                ForEach(tags, id: \.id) { tag in
                    TagButton(
                        tag: tag,
                        isSelected: selectedTag == tag.slug,
                        action: {
                            selectedTag = tag.slug
                            onTagSelected(tag.slug)
                        }
                    )
                }
            }
        }
        .scrollClipDisabled()
    }
}
