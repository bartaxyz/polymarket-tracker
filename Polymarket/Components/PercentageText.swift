//
//  PercentageText.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 10/5/25.
//

import SwiftUI

struct PercentageText: View {
    enum SignatureStrategy {
        case automatic
        case always
        case never
    }
    
    var amount: Double?
    var signature: SignatureStrategy = .automatic
    
    private var formattedAmount: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percent
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        
        if signature == .always {
            numberFormatter.positivePrefix = "+"
        }
        
        if signature == .never {
            numberFormatter.negativePrefix = ""
        }
        
        guard let amount = amount else { return "- --.-- %" }
        return numberFormatter.string(from: NSNumber(value: amount)) ?? "-"
    }
    
    var body: some View {
        Text(formattedAmount)
            .foregroundColor(amount == nil ? .clear : textColor)
            .background(
                amount == nil ? 
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    : nil
            )
    }
    
    private var textColor: Color? {
        guard signature == .always else { return nil }
        guard let amount = amount else { return nil }
        return amount >= 0 ? .green : .red
    }
}

#Preview {
    VStack(spacing: 10) {
        PercentageText(amount: nil)
        PercentageText(amount: 1.2345)
        PercentageText(amount: -0.6789)
        PercentageText(amount: 0.42, signature: .always)
        PercentageText(amount: -0.42, signature: .always)
        PercentageText(amount: 0.42, signature: .never)
        PercentageText(amount: -0.42, signature: .never)
    }
}
