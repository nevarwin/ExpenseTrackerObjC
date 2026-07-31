import SwiftUI
import SwiftData

struct TransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: SharedCurrencyService
    @Bindable var viewModel: TransactionViewModel
    
    let availableBudgets: [Budget]
    let existingTransaction: Transaction?
    
    @State private var selectedBudget: Budget
    
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var date: Date = Date()
    @State private var selectedBudgetPeriod: Date = Date()
    
    @State private var selectedCategory: Category?
    @State private var showingOverflowAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingBudgetPeriodPicker = false
    
    init(activeBudgets: [Budget], initialBudget: Budget, viewModel: TransactionViewModel, existingTransaction: Transaction? = nil, initialCategory: Category? = nil, initialDate: Date? = nil) {
        self.availableBudgets = activeBudgets
        _selectedBudget = State(initialValue: initialBudget)
        self.viewModel = viewModel
        self.existingTransaction = existingTransaction
        
        if let transaction = existingTransaction,
           let transactionBudget = transaction.budget {
            _selectedBudget = State(initialValue: transactionBudget)
            _amount = State(initialValue: "\(transaction.amount)")
            _description = State(initialValue: transaction.desc)
            _date = State(initialValue: transaction.date)
            _selectedCategory = State(initialValue: transaction.category)
            _selectedBudgetPeriod = State(initialValue: transaction.budgetPeriod)
        } else {
            // For new transactions, use initial values if provided
            let transactionDate = initialDate ?? Date()
            _date = State(initialValue: transactionDate)
            _selectedBudgetPeriod = State(initialValue: transactionDate.monthBounds.start)
            _selectedCategory = State(initialValue: initialCategory)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Details") {
                    Picker("Budget", selection: $selectedBudget) {
                        ForEach(availableBudgets) { budget in
                            Text(budget.name).tag(budget)
                        }
                    }
                    .accessibilityIdentifier("form_budget_picker")
                    
                    LabeledContent("Amount") {
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("form_amount_field")
                            .onChange(of: amount) { oldValue, newValue in
                                let parts = newValue.split(separator: ".")
                                if let intPart = parts.first, intPart.count > 9 {
                                    amount = oldValue
                                }
                            }
                    }
                    
                    LabeledContent("Description") {
                        TextField("Enter description", text: $description)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("form_description_field")
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("form_date_picker")
                }
                
                Section("Budget Period") {
                    Button {
                        showingBudgetPeriodPicker = true
                    } label: {
                        HStack {
                            Text("Assign to Month")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(selectedBudgetPeriod.monthYearString)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .accessibilityIdentifier("form_budget_period_button")
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select Category").tag(nil as Category?)
                        
                        Section("Income") {
                            ForEach(viewModel.availableCategories.filter { $0.isIncome }) { category in
                                Text(category.name).tag(category as Category?)
                            }
                        }
                        
                        Section("Expense") {
                            ForEach(viewModel.availableCategories.filter { !$0.isIncome }) { category in
                                Text(category.name).tag(category as Category?)
                            }
                        }
                    }
                    .accessibilityIdentifier("form_category_picker")
                }
            }
            .navigationTitle(existingTransaction == nil ? "New Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("form_cancel_button")
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTransaction() }
                        .disabled(!isValid)
                        .accessibilityIdentifier("form_save_button")
                }
            }
            .alert("Amount Exceeds Allocation", isPresented: $showingOverflowAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Proceed Anyway") {
                    performSave()
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
        .sheet(isPresented: $showingBudgetPeriodPicker) {
            TransactionMonthPickerView(selectedDate: $selectedBudgetPeriod)
        }
        .onAppear {
            loadCategories()
        }
        
        .onChange(of: date) { _, newDate in
            // Auto-sync budget period when transaction date changes
            selectedBudgetPeriod = newDate.monthBounds.start
            loadCategories()
        }
        .onChange(of: selectedBudget) { _, _ in
            selectedCategory = nil
            loadCategories()
        }
    }
    
    private var isValid: Bool {
        guard let decimalAmount = Decimal(string: amount),
              decimalAmount > 0,
              decimalAmount <= 999_999_999,
              !description.isEmpty,
              selectedCategory != nil else {
            return false
        }
        return true
    }
    
    private func loadCategories() {
        viewModel.loadAvailableCategories(
            transactionDate: date,
            budget: selectedBudget,
            excluding: existingTransaction
        )
    }
    
    private func saveTransaction() {
        guard let decimalAmount = Decimal(string: amount),
              let category = selectedCategory else {
            return
        }
        
        // 1. Check for overflow
        let hasOverflow = viewModel.checkOverflow(
            amount: decimalAmount,
            date: date,
            budget: selectedBudget,
            category: category,
            existing: existingTransaction
        )
        
        if hasOverflow {
            showingOverflowAlert = true
            return // Stop here, wait for user confirmation
        }
        
        // 2. If no overflow, save immediately
        performSave()
    }
    
    private func performSave() {
        guard let decimalAmount = Decimal(string: amount),
              let category = selectedCategory else { return }
        
        do {
            try viewModel.saveTransaction(
                amount: decimalAmount,
                description: description,
                date: date,
                budget: selectedBudget,
                category: category,
                budgetPeriod: selectedBudgetPeriod,
                existing: existingTransaction
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}
