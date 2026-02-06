import SwiftUI

/// Inline category input row for budget creation/editing
struct CategoryInputRow: View {
    @Binding var draft: CategoryDraft
    let onDelete: () -> Void
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Category Name", text: $draft.name)
                    .textFieldStyle(.plain)
                
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                if draft.isInstallment {
                    VStack(alignment: .leading) {
                        Text("Monthly:")
                            .font(.caption)
                            .foregroundStyle(Color.appSecondary)
                        Text(formatCurrency(draft.allocatedDecimal))
                            .fontWeight(.medium)
                            .foregroundStyle(Color.appPrimary)
                    }
                    .frame(maxWidth: 120, alignment: .leading)
                } else {
                    TextField("Amount", text: $draft.allocatedAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .frame(maxWidth: 120)
                }
                
                Spacer()
                
                Button(action: {
                    draft.isIncome.toggle()
                    if draft.isIncome {
                        draft.isInstallment = false
                    }
                }) {
                    Text(draft.isIncome ? "Income" : "Expense")
                        .foregroundStyle(draft.isIncome ? .green : Color.appPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(draft.isIncome ? Color.green.opacity(0.2) : Color.appAccent.opacity(0.2))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            if !draft.isIncome {
                Toggle("Installment", isOn: $draft.isInstallment)
                    .toggleStyle(SwitchToggleStyle(tint: Color.appAccent))
                    .font(.subheadline)
            }
            
            if draft.isInstallment {
                HStack {
                    TextField("Total", text: $draft.totalInstallmentAmount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Months", text: $draft.installmentMonths)
                        .keyboardType(.numberPad)
                }
                .textFieldStyle(.roundedBorder)
                
                DatePicker("Start Date", selection: $draft.installmentStartDate, displayedComponents: [.date])
            }
            
            // Validation feedback
            if !draft.name.trimmingCharacters(in: .whitespaces).isEmpty && 
               draft.allocatedDecimal <= 0 {
                Text("Amount must be greater than 0")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyManager.currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currencyManager.currencySymbol)0.00"
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var draft = CategoryDraft(name: "Groceries", allocatedAmount: "500", isIncome: false)
        
        var body: some View {
            Form {
                CategoryInputRow(draft: $draft, onDelete: {})
            }
        }
    }
    
    return PreviewWrapper()
}
