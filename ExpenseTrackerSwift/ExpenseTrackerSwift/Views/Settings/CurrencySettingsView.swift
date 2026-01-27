import SwiftUI

struct CurrencySettingsView: View {
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        Form {
            Section("Select Currency") {
                Picker("Currency", selection: $currencyManager.currencyCode) {
                    ForEach(currencyManager.availableCurrencies, id: \.self) { currency in
                        Text("\(currency) (\(NSLocale(localeIdentifier: currency).displayName(forKey: .currencySymbol, value: currency) ?? currency))")
                            .tag(currency)
                    }
                }
                .pickerStyle(.inline)
            }
            
            Section {
                LabeledContent("Current Selection", value: currencyManager.currencyCode)
                LabeledContent("Symbol", value: currencyManager.currencySymbol)
            }
        }
        .navigationTitle("Currency")
    }
}

#Preview {
    NavigationStack {
        CurrencySettingsView()
            .environmentObject(CurrencyManager())
    }
}
