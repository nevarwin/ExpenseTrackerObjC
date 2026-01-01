//
//  PickerViews.swift
//  ExpenseTracker
//
//  Created by raven on 9/29/25.
//

import SwiftUI

struct MonthPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedMonth: Int
    let onSelect: (Int) -> Void
    
    private let months = ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Month", selection: Binding(
                    get: { selectedMonth - 1 },
                    set: { onSelect($0 + 1) }
                )) {
                    ForEach(0..<12) { index in
                        Text(months[index]).tag(index)
                    }
                }
                .pickerStyle(.wheel)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

struct YearPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedYear: Int
    let onSelect: (Int) -> Void
    
    private let startYear = 2000
    private let range = 50
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Year", selection: Binding(
                    get: { selectedYear - startYear },
                    set: { onSelect($0 + startYear) }
                )) {
                    ForEach(0..<range) { index in
                        Text("\(startYear + index)").tag(index)
                    }
                }
                .pickerStyle(.wheel)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Select Year")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

