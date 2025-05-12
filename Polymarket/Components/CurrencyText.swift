//
//  CurrencyText.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 8/5/25.
//

import SwiftUI

struct CurrencyText: View {
    enum SignatureStrategy {
        case automatic
        case always
        case never
    }
    
    var amount: Double?
    var signature: SignatureStrategy = .automatic
    var hasBackground: Bool = false
    var isDelta: Bool = false
    var hasArrow: Bool = false
    
    private var formattedAmount: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencySymbol = "$"
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        
        if signature == .always {
            numberFormatter.positivePrefix = "+"
        }
        
        if signature == .never {
            numberFormatter.negativePrefix = ""
        }
        
        guard let amount = amount else { return "- --.-- $" }
        return numberFormatter.string(from: NSNumber(value: amount)) ?? "-"
    }
    
    private var arrow: String {
        guard hasArrow, let amount = amount else { return "" }
        return amount >= 0 ? "↑" : "↓"
    }
    
    var body: some View {
        HStack(spacing: 2) {
            if hasArrow {
                Text(arrow)
                    .font(.system(size: 12))
            }
            Text(formattedAmount)
        }
        .foregroundColor(amount == nil ? .clear : (hasBackground ? .white : textColor))
        .background(
            Group {
                if amount == nil {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                } else if hasBackground {
                    Rectangle()
                        .fill(backgroundColor ?? .clear)
                        .cornerRadius(4)
                        .padding(.horizontal, -3)
                        .padding(.vertical, -2)
                }
            }
        )
    }
    
    private var textColor: Color? {
        guard isDelta else { return nil }
        guard let amount = amount else { return nil }
        return amount >= 0 ? .positive : .negative
    }
    
    private var backgroundColor: Color? {
        guard let amount = amount else { return nil }
        return amount >= 0 ? .positive : .negative
    }
}

#Preview {
    VStack(spacing: 10) {
        CurrencyText(amount: nil)
        CurrencyText(amount: 123.45)
        CurrencyText(amount: -67.89)
        CurrencyText(amount: 42, signature: .always)
        CurrencyText(amount: -42, signature: .always)
        CurrencyText(amount: 42, signature: .never)
        CurrencyText(amount: -42, signature: .never)
        CurrencyText(amount: 42, hasBackground: true)
        CurrencyText(amount: -42, hasBackground: true)
        CurrencyText(amount: 42, isDelta: true)
        CurrencyText(amount: -42, isDelta: true)
        CurrencyText(amount: 42, hasArrow: true)
        CurrencyText(amount: -42, hasArrow: true)
    }
    .padding()
}
