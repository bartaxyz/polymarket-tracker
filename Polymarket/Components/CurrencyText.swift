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
    
    var amount: Double
    var signature: SignatureStrategy = .automatic
    
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
        
        return numberFormatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var body: some View {
        Text(formattedAmount)
            .foregroundColor(textColor)
    }
    
    private var textColor: Color? {
        guard signature == .always else { return nil }
        return amount >= 0 ? .green : .red
    }
}

#Preview {
    VStack(spacing: 10) {
        CurrencyText(amount: 123.45)
        CurrencyText(amount: -67.89)
        CurrencyText(amount: 42, signature: .always)
        CurrencyText(amount: -42, signature: .always)
        CurrencyText(amount: 42, signature: .never)
        CurrencyText(amount: -42, signature: .never)
    }
}
