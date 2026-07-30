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
                }
                
                Section {
                    Button("Current Month") {
                        selectedDate = Date()
                    }
                    
                    Button("Previous Month") {
                        selectedDate = selectedDate.previousMonth
                    }
                    
                    Button("Next Month") {
                        selectedDate = selectedDate.nextMonth
                    }
                }
            }
            .navigationTitle("Select Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TransactionMonthPickerView(selectedDate: .constant(Date()))
}
