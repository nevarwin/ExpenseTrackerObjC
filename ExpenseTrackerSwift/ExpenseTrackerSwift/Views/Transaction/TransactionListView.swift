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
                    VStack(spacing: 0) {
                        // Custom Calendar View
                        CalendarView(viewModel: viewModel)
                            .padding(.bottom, 8)
                        
                        if viewModel.isLoading {
                            ProgressView("Loading transactions...")
                                .frame(maxHeight: .infinity)
                        } else if viewModel.transactions.isEmpty {
                            ContentUnavailableView(
                                "No Transactions",
                                systemImage: "list.bullet",
                                description: Text("No transactions found for this period")
                            )
                            .frame(maxHeight: .infinity)
                        } else {
                            List {
                                // Scroll detection helper
                                GeometryReader { proxy in
                                    Color.clear
                                        .preference(
                                            key: ScrollOffsetPreferenceKey.self,
                                            value: proxy.frame(in: .named("scroll")).minY
                                        )
                                }
                                .frame(height: 0)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                
                                ForEach(viewModel.transactions) { transaction in
                                    TransactionDetailRow(transaction: transaction)
                                }
                                .onDelete(perform: deleteTransactions)
                            }
                            .listStyle(.plain)
                            .coordinateSpace(name: "scroll")
                            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                                // Collapsing logic
                                // If scrolling down (value goes negative), collapse to week
                                // If scrolling up near top (value goes near 0), expand to month
                                if value < -20 && viewModel.calendarScope == .month {
                                    withAnimation {
                                        viewModel.calendarScope = .week
                                    }
                                } else if value > 0 && viewModel.calendarScope == .week {
                                    withAnimation {
                                        viewModel.calendarScope = .month
                                    }
                                }
                            }
                            // Header showing the range if needed, but we have the top bar now
                        }
                    }
                    .onChange(of: viewModel.selectedDate) { _, _ in viewModel.loadTransactions() }
                    .onChange(of: viewModel.selectedDateRange) { _, _ in viewModel.loadTransactions() }
                    
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
                if let firstBudget = activeBudgets.first, let viewModel = viewModel {
                    TransactionFormView(
                        activeBudgets: activeBudgets,
                        initialBudget: firstBudget,
                        viewModel: viewModel
                    )
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
    @EnvironmentObject var currencyManager: CurrencyManager
    
    @State private var isRevealed: Bool = false
    
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
                            .foregroundStyle(Color.appSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if transaction.shouldCensorAmount && !isRevealed {
                        Text("****")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(transaction.isIncome ? .green : .red)
                            .onTapGesture {
                                withAnimation {
                                    isRevealed.toggle()
                                }
                            }
                    } else {
                        Text(transaction.amount, format: .currency(code: currencyManager.currencyCode))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(transaction.isIncome ? .green : .red)
                            .onTapGesture {
                                if transaction.shouldCensorAmount {
                                    withAnimation {
                                        isRevealed.toggle()
                                    }
                                }
                            }
                    }
                    
                    Text(transaction.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(Color.appSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct TransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: CurrencyManager
    @Bindable var viewModel: TransactionViewModel
    
    let availableBudgets: [Budget]
    let existingTransaction: Transaction?
    
    @State private var selectedBudget: Budget
    
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var date: Date = Date()

    @State private var selectedCategory: Category?
    @State private var showingOverflowAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(activeBudgets: [Budget], initialBudget: Budget, viewModel: TransactionViewModel, existingTransaction: Transaction? = nil) {
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

                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Description", text: $description)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
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
                }
                
                if let category = selectedCategory, category.isInstallment {
                    LabeledContent("Monthly Installment") {
                        Text(category.allocatedAmount, format: .currency(code: currencyManager.currencyCode))
                            .foregroundStyle(Color.appSecondary)
                    }
                    
                    if let decimalAmount = Decimal(string: amount), decimalAmount > 0 {
                        if decimalAmount > category.allocatedAmount {
                            Text("Extra payment of \(decimalAmount - category.allocatedAmount, format: .currency(code: currencyManager.currencyCode)) will reduce the term.")
                                .font(.caption)
                                .foregroundStyle(Color.appAccent)
                        } else if decimalAmount < category.allocatedAmount {
                            Text("Payment is less than the monthly installment.")
                                .font(.caption)
                                .foregroundStyle(.orange)
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
        .onAppear {
            loadCategories()
        }

        .onChange(of: date) { _, _ in loadCategories() }
        .onChange(of: selectedBudget) { _, _ in
            selectedCategory = nil
            loadCategories()
        }
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
                existing: existingTransaction
            )
            dismiss()
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
