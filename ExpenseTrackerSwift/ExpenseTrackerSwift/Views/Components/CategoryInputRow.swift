import SwiftUI

/// Inline category input row for budget creation/editing
struct CategoryInputRow: View {
    @Binding var draft: CategoryDraft
    let onDelete: () -> Void
    
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
                TextField("Amount", text: $draft.allocatedAmount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: 120)
                
                Spacer()
                
                Button(action: {
                    draft.isIncome.toggle()
                }) {
                    Text(draft.isIncome ? "Income" : "Expense")
                        .foregroundStyle(draft.isIncome ? .green : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(draft.isIncome ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
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
