//
//  CurrencySettingsView.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import SwiftUI

struct CurrencySettingsView: View {
    @EnvironmentObject var currencyManager: SharedCurrencyService
    
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
                .accessibilityIdentifier("currency_picker")
                .onChange(of: currencyManager.currencyCode) { _, newValue in
                    SharedAnalyticsService.instance.trackEvent("Currency Changed", properties: ["currency_code": newValue])
                }
            }
            
            Section {
                LabeledContent("Current Selection", value: currencyManager.currencyCode)
                    .accessibilityIdentifier("currency_current_selection")
                LabeledContent("Symbol", value: currencyManager.currencySymbol)
                    .accessibilityIdentifier("currency_symbol")
            }
        }
        .accessibilityIdentifier("currency_settings_form")
        .navigationTitle("Currency")
    }
}

#Preview {
    NavigationStack {
        CurrencySettingsView()
            .environmentObject(SharedCurrencyService())
    }
}

