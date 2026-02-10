import SwiftUI

struct MonthPickerView: View {
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
                        selectedDate = DateRangeHelper.previousMonth(from: selectedDate)
                    }
                    
                    Button("Next Month") {
                        selectedDate = DateRangeHelper.nextMonth(from: selectedDate)
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
    MonthPickerView(selectedDate: .constant(Date()))
}
