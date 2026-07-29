import SwiftUI
import Combine

class CurrencyManager: ObservableObject {
    @Published var currencyCode: String {
        didSet {
            UserDefaults.standard.set(currencyCode, forKey: "currencyCode")
        }
    }
    
    init() {
        self.currencyCode = UserDefaults.standard.string(forKey: "currencyCode") ?? "PHP"
    }
    
    let availableCurrencies = [
        "USD", "EUR", "GBP", "JPY", "CNY", "CAD", "AUD", "CHF", "HKD", "SGD", "PHP"
    ]
    
    var currencySymbol: String {
        let locale = NSLocale(localeIdentifier: currencyCode)
        return locale.displayName(forKey: .currencySymbol, value: currencyCode) ?? currencyCode
    }
}
