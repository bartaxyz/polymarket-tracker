//
//  Tag.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 8/6/25.
//

import SwiftUI

struct Tag: View {
    var label: String

    init (_ label: String) {
        self.label = label
    }
    
    var body: some View {
        Text(label)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.primary.opacity(0.1))
            .foregroundColor(.primary)
            .cornerRadius(4)
    }
}

#Preview {
    Tag("label")
        .padding()
}
