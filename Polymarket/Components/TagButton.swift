//
//  TagButton.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 8/6/25.
//

import SwiftUI

struct TagButton: View {
    let tag: PolymarketDataService.Tag
    let isSelected: Bool
    let icon: String?
    let action: () -> Void
    
    @State private var isHovered = false
    
    init(tag: PolymarketDataService.Tag, isSelected: Bool, icon: String? = nil, action: @escaping () -> Void) {
        self.tag = tag
        self.isSelected = isSelected
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(tag.label)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .shadow(
            color: isSelected ? .accent.opacity(0.2) : .clear,
            radius: isSelected ? 8 : 0,
            x: 0,
            y: 4
        )
        .animation(.easeInOut(duration: 0.1), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .accent
        } else if isHovered {
            return .secondary.opacity(0.2)
        } else {
            return .secondary.opacity(0.1)
        }
    }
    
    private var foregroundColor: Color {
        return isSelected ? .white : .primary
    }
}
