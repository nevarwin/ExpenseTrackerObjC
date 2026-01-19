import SwiftUI
import SwiftData

struct BudgetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BudgetViewModel
    
    @State private var name: String = ""
    @State private var totalAmount: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let existingBudget: Budget?
    
    init(viewModel: BudgetViewModel, existingBudget: Budget? = nil) {
        self.viewModel = viewModel
        self.existingBudget = existingBudget
        
        if let budget = existingBudget {
            _name = State(initialValue: budget.name)
            _totalAmount = State(initialValue: "\(budget.totalAmount)")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Details") {
                    TextField("Budget Name", text: $name)
                    
                    TextField("Total Amount", text: $totalAmount)
                        .keyboardType(.decimalPad)
                }
                
                if existingBudget != nil {
                    Section {
                        Button(role: .destructive) {
                            deleteBudget()
                        } label: {
                            Label("Delete Budget", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(existingBudget == nil ? "New Budget" : "Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveBudget() }
                        .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && Decimal(string: totalAmount) != nil && (Decimal(string: totalAmount) ?? 0) > 0
    }
    
    private func saveBudget() {
        guard let amount = Decimal(string: totalAmount) else { return }
        
        do {
            if let existing = existingBudget {
                try viewModel.updateBudget(existing, name: name, totalAmount: amount)
            } else {
                try viewModel.createBudget(name: name, totalAmount: amount)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func deleteBudget() {
        guard let budget = existingBudget else { return }
        
        do {
            try viewModel.deleteBudget(budget)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Budget.self, configurations: config)
    let viewModel = BudgetViewModel(modelContext: container.mainContext)
    
    BudgetFormView(viewModel: viewModel)
}
