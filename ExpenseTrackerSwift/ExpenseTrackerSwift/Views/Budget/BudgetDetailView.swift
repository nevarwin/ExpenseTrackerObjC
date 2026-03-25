import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BudgetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: CurrencyManager
    let budget: Budget
    var viewModel: BudgetViewModel?
    
    @State private var categoryViewModel: CategoryViewModel?
    @State private var transactionViewModel: TransactionViewModel?
    @State private var showingEditSheet = false
    
    // Month Selection
    @State private var selectedMonth: Date = Date()
    @State private var showingDatePicker = false
    @State private var pickerMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var pickerYear: Int = Calendar.current.component(.year, from: Date())
    
    // Import States
    @State private var isImportingTransactions = false
    @State private var importMessage: String?
    @State private var showingImportAlert = false
    @State private var importErrorMessage: String?
    @State private var showingImportError = false
    
    @State private var showingImportInstruction = false
    
    // Inline Category Creation
    @State private var newCategoryName: String = ""
    @State private var newCategoryAmount: String = ""
    @State private var newCategoryIsIncome: Bool = false
    
    @State private var showingDeleteConfirmation = false
    
    // Search Text State
    @State private var searchText: String = ""
    
    var body: some View {
        List {
            // Month Selector
            Section("Period") {
                Button(action: { showingDatePicker = true }) {
                    LabeledContent("Viewing Period") {
                        HStack(spacing: 4) {
                            Text(DateRangeHelper.monthYearString(from: selectedMonth))
                                .font(.body)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .foregroundStyle(.primary)
                .sheet(isPresented: $showingDatePicker) {
                    VStack(spacing: 20) {
                        Text("Select Month & Year")
                            .font(.headline)
                            .padding(.top)
                        
                        HStack(spacing: 0) {
                            Picker("Month", selection: $pickerMonth) {
                                ForEach(1...12, id: \.self) { month in
                                    Text(Calendar.current.monthSymbols[month - 1]).tag(month)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 150)
                            
                            Picker("Year", selection: $pickerYear) {
                                let currentYear = Calendar.current.component(.year, from: Date())
                                ForEach((currentYear - 10)...(currentYear + 10), id: \.self) { year in
                                    Text(String(year).replacingOccurrences(of: ",", with: "")).tag(year)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                        }
                        
                        Button("Done") {
                            var components = DateComponents()
                            components.year = pickerYear
                            components.month = pickerMonth
                            if let newDate = Calendar.current.date(from: components) {
                                selectedMonth = newDate
                            }
                            showingDatePicker = false
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom)
                    }
                    .presentationDetents([.height(300)])
                    .onAppear {
                        pickerMonth = Calendar.current.component(.month, from: selectedMonth)
                        pickerYear = Calendar.current.component(.year, from: selectedMonth)
                    }
                }
            }

            Section("Expense Overview") {
                let pExpense = budget.plannedExpenses(for: selectedMonth)
                let aExpense = budget.expensesInMonth(selectedMonth)
                let dExpense = budget.expenseDiffInMonth(selectedMonth)
                
                LabeledContent("Planned Expense", value: pExpense, format: .currency(code: currencyManager.currencyCode))
                LabeledContent("Actual Expense", value: aExpense, format: .currency(code: currencyManager.currencyCode))
                LabeledContent("Difference") {
                    Text(dExpense, format: .currency(code: currencyManager.currencyCode))
                        .foregroundStyle(dExpense >= 0 ? .green : .red)
                        .fontWeight(.semibold)
                }
            }
            
            Section("Income Overview") {
                let pIncome = budget.plannedIncome(for: selectedMonth)
                let aIncome = budget.incomeInMonth(selectedMonth)
                let dIncome = budget.incomeDiffInMonth(selectedMonth)
                
                LabeledContent("Planned Income", value: pIncome, format: .currency(code: currencyManager.currencyCode))
                LabeledContent("Actual Income", value: aIncome, format: .currency(code: currencyManager.currencyCode))
                LabeledContent("Difference") {
                    Text(dIncome, format: .currency(code: currencyManager.currencyCode))
                        .foregroundStyle(dIncome >= 0 ? .green : .red)
                        .fontWeight(.semibold)
                }
            }

            Section("Total Savings") {
                let savings = budget.remainingInMonth(selectedMonth)
                LabeledContent("Savings") {
                    Text(savings, format: .currency(code: currencyManager.currencyCode))
                        .foregroundStyle(savings >= 0 ? .green : .red)
                        .fontWeight(.semibold)
                }
            }
            
            if let viewModel = categoryViewModel {
                let searchResults = searchText.isEmpty 
                    ? viewModel.categories 
                    : viewModel.categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                
                let expenses = searchResults.filter { !$0.isIncome }
                let incomes = searchResults.filter { $0.isIncome }
                
                if viewModel.categories.isEmpty {
                    Section("Categories") {
                        Text("No categories")
                            .foregroundStyle(.secondary)
                    }
                } else if !searchText.isEmpty && searchResults.isEmpty {
                    Section("Categories") {
                        Text("No matching categories")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    if !expenses.isEmpty {
                        Section("Expense Categories") {
                            ForEach(expenses) { category in
                                NavigationLink(destination: CategoryTransactionsView(category: category, month: selectedMonth)) {
                                    CategoryRowView(category: category, month: selectedMonth)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            }
                        }
                    }
                    
                    if !incomes.isEmpty {
                        Section("Income Categories") {
                            ForEach(incomes) { category in
                                NavigationLink(destination: CategoryTransactionsView(category: category, month: selectedMonth)) {
                                    CategoryRowView(category: category, month: selectedMonth)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            }
                        }
                    }
                }
                
                // MARK: - Inline Quick Create Row
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Add Category").font(.caption).foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            TextField("Name", text: $newCategoryName)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Amount", text: $newCategoryAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                        
                        HStack {
                            Picker("Type", selection: $newCategoryIsIncome) {
                                Text("Expense").tag(false)
                                Text("Income").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 160)
                            
                            Spacer()
                            
                            Button(action: addInlineCategory) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.appAccent)
                            }
                            .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty || (Decimal(string: newCategoryAmount) ?? 0) <= 0)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search categories")
        .navigationTitle(budget.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Budget", systemImage: "trash")
                        }
                        
                        Divider()
                        
                        Button {
                            showingEditSheet = true
                            PostHogManager.shared.trackEvent("Budget Edit Clicked (Detail)")
                        } label: {
                            Label("Edit Budget", systemImage: "pencil")
                        }
                        
                        Button {
                            showingImportInstruction = true
                            PostHogManager.shared.trackEvent("Transaction Import Clicked")
                        } label: {
                            Label("Import Transactions", systemImage: "square.and.arrow.down")
                        }
                        
                        Divider()

                        NavigationLink {
                            BudgetHistoryView(budget: budget)
                        } label: {
                            Label("View History", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                BudgetFormView(
                    viewModel: BudgetViewModel(modelContext: modelContext),
                    existingBudget: budget
                )
            }
            .alert("Import Transactions", isPresented: $showingImportInstruction) {
                Button("Continue") {
                    isImportingTransactions = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Select one or more CSV files. The budget period for each file will be auto-detected from its filename (e.g., 'Dec25.csv')")
            }
            .fileImporter(
                isPresented: $isImportingTransactions,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: true
            ) { result in
                handleFilePicked(result)
            }
            .alert("Import Success", isPresented: $showingImportAlert) {
                Button("OK") { }
            } message: {
                Text(importMessage ?? "Import complete")
            }
            .alert("Import Failed", isPresented: $showingImportError) {
                Button("OK") { }
            } message: {
                Text(importErrorMessage ?? "Unknown error")
            }
            .confirmationDialog("Delete Budget", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                deleteBudget()
                PostHogManager.shared.trackEvent("Budget Delete Confirmed (Detail)", properties: ["budget_name": budget.name])
            }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this budget? All associated categories and transactions will be permanently deleted.")
            }
            .onAppear {
                if categoryViewModel == nil {
                    categoryViewModel = CategoryViewModel(modelContext: modelContext)
                    categoryViewModel?.loadCategories(for: budget)
                }
                
                if transactionViewModel == nil {
                    transactionViewModel = TransactionViewModel(modelContext: modelContext)
                    transactionViewModel?.loadTransactions(for: budget)
                }
            }
    }
    
    // Step 1: Files picked → copy to temp, parse and import
    private func handleFilePicked(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else { return }
            
            var processedFiles: [(String, [CSVTransaction])] = []
            var tempFileURLs: [URL] = []
            let parser = CSVParser.shared
            
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                
                // Copy to temp
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                do {
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    tempFileURLs.append(tempURL)
                    
                    // Parse transactions
                    let transactions = try parser.parseTransactions(from: tempURL)
                    processedFiles.append((url.lastPathComponent, transactions))
                    
                } catch {
                    print("Error preparing/parsing file \(url.lastPathComponent): \(error)")
                }
                
                url.stopAccessingSecurityScopedResource()
            }
            
            guard !processedFiles.isEmpty else {
                importErrorMessage = "Failed to parse any selected files."
                showingImportError = true
                return
            }
            
            // Execute import
            do {
                let importManager = ImportManager(modelContext: modelContext)
                let totalCount = try importManager.importBatchTransactions(files: processedFiles, into: budget)
                
                if totalCount > 0 {
                    importMessage = "Successfully imported \(totalCount) transactions from \(processedFiles.count) file(s)."
                } else {
                    importMessage = "No new transactions were imported. They might be duplicates."
                }
                showingImportAlert = true
                PostHogManager.shared.trackEvent("Transaction Import Success", properties: [
                    "imported_count": totalCount,
                    "file_count": processedFiles.count
                ])
                
                // Refresh data
                transactionViewModel?.loadTransactions(for: budget)
                categoryViewModel?.loadCategories(for: budget)
                
            } catch {
                importErrorMessage = "Import failed: \(error.localizedDescription)"
                showingImportError = true
                PostHogManager.shared.trackEvent("Transaction Import Failed", properties: ["error": error.localizedDescription])
            }
            
            // Clean up temp files
            for tempURL in tempFileURLs {
                try? FileManager.default.removeItem(at: tempURL)
            }
            
        case .failure(let error):
            importErrorMessage = error.localizedDescription
            showingImportError = true
        }
    }
    
    // Step 3: Add Inline Category
    private func addInlineCategory() {
        guard let viewModel = categoryViewModel else { return }
        let amount = Decimal(string: newCategoryAmount) ?? 0
        
        do {
            try viewModel.createCategory(
                name: newCategoryName.trimmingCharacters(in: .whitespaces),
                allocatedAmount: amount,
                isIncome: newCategoryIsIncome,
                budget: budget
            )
            
            // Reset fields on success
            withAnimation {
                newCategoryName = ""
                newCategoryAmount = ""
                newCategoryIsIncome = false
            }
        } catch {
            print("Failed to create category: \(error.localizedDescription)")
        }
    }
    
    // Step 4: Delete Budget
    private func deleteBudget() {
        if let vm = viewModel {
            try? vm.deleteBudget(budget)
        } else {
            modelContext.delete(budget)
            try? modelContext.save()
        }
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Budget.self, configurations: config)
    let budget = Budget(name: "Monthly Budget", startDate: Date(), totalAmount: 5000)
    container.mainContext.insert(budget)
    
    return NavigationStack {
        BudgetDetailView(budget: budget, viewModel: nil)
            .modelContainer(container)
            .environmentObject(CurrencyManager())
    }
}
