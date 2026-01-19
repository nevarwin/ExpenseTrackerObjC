import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TransactionViewModel?
    @State private var showingAddTransaction = false
    
    @Query(filter: #Predicate<Budget> { $0.isActive == true })
    private var activeBudgets: [Budget]
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    if viewModel.isLoading {
                        ProgressView("Loading transactions...")
                    } else if viewModel.transactions.isEmpty {
                        ContentUnavailableView(
                            "No Transactions",
                            systemImage: "list.bullet",
                            description: Text("Add your first transaction to get started")
                        )
                    } else {
                        List {
                            ForEach(viewModel.transactions) { transaction in
                                TransactionDetailRow(transaction: transaction)
                            }
                            .onDelete(perform: deleteTransactions)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddTransaction = true }) {
                        Label("Add Transaction", systemImage: "plus")
                    }
                    .disabled(activeBudgets.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                if let budget = activeBudgets.first {
                    TransactionFormView(budget: budget, viewModel: viewModel!)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TransactionViewModel(modelContext: modelContext)
            }
            viewModel?.loadTransactions()
        }
    }
    
    private func deleteTransactions(at offsets: IndexSet) {
        guard let viewModel = viewModel else { return }
        
        for index in offsets {
            let transaction = viewModel.transactions[index]
            try? viewModel.deleteTransaction(transaction)
        }
    }
}

struct TransactionDetailRow: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.desc)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if let category = transaction.category {
                        Text(category.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(transaction.amount, format: .currency(code: "USD"))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(transaction.isIncome ? .green : .red)
                    
                    Text(transaction.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TransactionViewModel
    
    let budget: Budget
    let existingTransaction: Transaction?
    
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var date: Date = Date()
    @State private var isIncome: Bool = false
    @State private var selectedCategory: Category?
    @State private var showingOverflowAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(budget: Budget, viewModel: TransactionViewModel, existingTransaction: Transaction? = nil) {
        self.budget = budget
        self.viewModel = viewModel
        self.existingTransaction = existingTransaction
        
        if let transaction = existingTransaction {
            _amount = State(initialValue: "\(transaction.amount)")
            _description = State(initialValue: transaction.desc)
            _date = State(initialValue: transaction.date)
            _isIncome = State(initialValue: transaction.isIncome)
            _selectedCategory = State(initialValue: transaction.category)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Details") {
                    Toggle("Income", isOn: $isIncome)
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Description", text: $description)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select Category").tag(nil as Category?)
                        
                        ForEach(viewModel.availableCategories) { category in
                            Text(category.name).tag(category as Category?)
                        }
                    }
                }
            }
            .navigationTitle(existingTransaction == nil ? "New Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTransaction() }
                        .disabled(!isValid)
                }
            }
            .alert("Amount Exceeds Allocation", isPresented: $showingOverflowAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Proceed Anyway") {
                    dismiss()
                }
            } message: {
                Text("The entered amount exceeds the allocated budget for this category. The excess will be applied to the total. Do you want to continue?")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            loadCategories()
        }
        .onChange(of: isIncome) { _, _ in loadCategories() }
        .onChange(of: date) { _, _ in loadCategories() }
    }
    
    private var isValid: Bool {
        guard let decimalAmount = Decimal(string: amount),
              decimalAmount > 0,
              !description.isEmpty,
              selectedCategory != nil else {
            return false
        }
        return true
    }
    
    private func loadCategories() {
        viewModel.loadAvailableCategories(
            isIncome: isIncome,
            transactionDate: date,
            budget: budget,
            excluding: existingTransaction
        )
    }
    
    private func saveTransaction() {
        guard let decimalAmount = Decimal(string: amount),
              let category = selectedCategory else {
            return
        }
        
        do {
            let hasOverflow = try viewModel.saveTransaction(
                amount: decimalAmount,
                description: description,
                date: date,
                budget: budget,
                category: category,
                existing: existingTransaction
            )
            
            if hasOverflow {
                showingOverflowAlert = true
            } else {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    TransactionListView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
}
