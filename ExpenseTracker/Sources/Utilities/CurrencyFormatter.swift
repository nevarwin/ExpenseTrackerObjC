//
//  CurrencyFormatter.swift
//  ExpenseTracker
//
//  Created by raven on 10/7/25.
//

import Foundation

struct CurrencyFormatter {
    static let shared: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₱"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    static func format(_ amount: Decimal) -> String {
        return shared.string(from: NSDecimalNumber(decimal: amount)) ?? "₱0.00"
    }
    
    static func format(_ amount: NSDecimalNumber) -> String {
        return shared.string(from: amount) ?? "₱0.00"
    }
}

