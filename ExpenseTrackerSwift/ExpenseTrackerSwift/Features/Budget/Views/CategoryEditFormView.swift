import SwiftUI
import SwiftData

struct CategoryEditFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currencyManager: CurrencyManager
    
    @Bindable var category: Category
    
    @State private var name: String = ""
    @State private var allocatedAmount: String = ""
    @State private var isIncome: Bool = false
    
    init(category: Category) {
        self.category = category
        _name = State(initialValue: category.name)
        _allocatedAmount = State(initialValue: "\(category.allocatedAmount)")
        _isIncome = State(initialValue: category.isIncome)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $name)
                        .overlay(alignment: .trailing) {
                            if name.trimmingCharacters(in: .whitespaces).isEmpty {
                                Text("Required")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.trailing, 8)
                            }
                        }
                    
                    LabeledContent("Allocated Amount") {
                        TextField("0.00", text: $allocatedAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Type", selection: $isIncome) {
                        Text("Expense").tag(false)
                        Text("Income").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button(role: .destructive) {
                        deleteCategory()
                    } label: {
                        Label("Delete Category", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCategory() }
                        .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              let amount = Decimal(string: allocatedAmount),
              amount >= 0 else {
            return false
        }
        return true
    }
    
    private func saveCategory() {
        guard let amount = Decimal(string: allocatedAmount) else { return }
        
        category.name = name.trimmingCharacters(in: .whitespaces)
        category.allocatedAmount = amount
        category.isIncome = isIncome
        category.updatedAt = Date()
        
        try? modelContext.save()
        dismiss()
    }
    
    private func deleteCategory() {
        category.isActive = false
        category.updatedAt = Date()
        try? modelContext.save()
        dismiss()
    }
}
