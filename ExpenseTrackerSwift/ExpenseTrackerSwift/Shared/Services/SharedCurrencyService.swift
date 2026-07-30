//
//  SharedCurrencyService.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 7/30/26.
//

import SwiftUI
import Combine

// MARK: - Protocol

protocol CurrencyServiceProtocol: AnyObject {
    var currencyCode: String { get set }
    var availableCurrencies: [String] { get }
    var currencySymbol: String { get }
}

// MARK: - Service

final class SharedCurrencyService: CurrencyServiceProtocol, ObservableObject {

    private static var _instance: SharedCurrencyService?

    static var instance: SharedCurrencyService {
        guard let instance = _instance else {
            fatalError("Please configure SharedCurrencyService first.")
        }
        return instance
    }

    static func configure() {
        guard _instance == nil else { return }
        _instance = SharedCurrencyService()
    }

    @Published var currencyCode: String {
        didSet {
            UserDefaults.standard.set(currencyCode, forKey: "currencyCode")
        }
    }

    let availableCurrencies = [
        "USD", "EUR", "GBP", "JPY", "CNY", "CAD", "AUD", "CHF", "HKD", "SGD", "PHP"
    ]

    var currencySymbol: String {
        let locale = NSLocale(localeIdentifier: currencyCode)
        return locale.displayName(forKey: .currencySymbol, value: currencyCode) ?? currencyCode
    }

    init() {
        self.currencyCode = UserDefaults.standard.string(forKey: "currencyCode") ?? "PHP"
    }
}
