import SwiftUI

/// Sheet for adding or editing a single category draft
struct CategoryDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: CurrencyManager

    @Binding var draft: CategoryDraft
    let isNew: Bool

    // Local copy so we can cancel without committing
    @State private var localDraft: CategoryDraft

    init(draft: Binding<CategoryDraft>, isNew: Bool) {
        self._draft = draft
        self.isNew = isNew
        self._localDraft = State(initialValue: draft.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $localDraft.name)

                    Picker("Type", selection: $localDraft.isIncome) {
                        Text("Income").tag(true)
                        Text("Expense").tag(false)
                    }
                    .pickerStyle(.segmented)


                    TextField("Amount", text: $localDraft.allocatedAmount)
                        .keyboardType(.decimalPad)

                    // Inline validation
                    if !localDraft.name.trimmingCharacters(in: .whitespaces).isEmpty &&
                        localDraft.allocatedDecimal <= 0 {
                        Text("Amount must be greater than 0")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }


            }
            .navigationTitle(isNew ? "Add Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        draft = localDraft
                        dismiss()
                    }
                    .disabled(!isLocalDraftValid)
                }
            }
        }
    }

    private var isLocalDraftValid: Bool {
        guard !localDraft.name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return localDraft.allocatedDecimal > 0
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyManager.currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currencyManager.currencySymbol)0.00"
    }
}
