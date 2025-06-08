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
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(tag.label)
                .font(.subheadline)
                .fontWeight(.medium)
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
