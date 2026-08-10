import SwiftUI

struct TransactionMonthPickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Select Month",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .accessibilityIdentifier("month_picker_date_picker")
                }
                
                Section {
                    Button("Current Month") {
                        selectedDate = Date()
                    }
                    .accessibilityIdentifier("month_picker_current_month")
                    
                    Button("Previous Month") {
                        selectedDate = selectedDate.previousMonth
                    }
                    .accessibilityIdentifier("month_picker_previous_month")
                    
                    Button("Next Month") {
                        selectedDate = selectedDate.nextMonth
                    }
                    .accessibilityIdentifier("month_picker_next_month")
                }
            }
            .navigationTitle("Select Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("month_picker_done_button")
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("month_picker_cancel_button")
                }
            }
        }
    }
}

#Preview {
    TransactionMonthPickerView(selectedDate: .constant(Date()))
}
