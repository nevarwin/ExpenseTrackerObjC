import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BudgetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currencyManager: CurrencyManager
    let budget: Budget
    
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
    
    // Import month selection
    @State private var pendingImportURL: URL?
    @State private var importMonth: Date = Date()
    @State private var showingImportMonthPicker = false
    
    // Inline Category Creation
    @State private var newCategoryName: String = ""
    @State private var newCategoryAmount: String = ""
    @State private var newCategoryIsIncome: Bool = false
    
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
            
            Section("Budget Overview") {
                LabeledContent("Total Budget", value: budget.totalAmount, format: .currency(code: currencyManager.currencyCode))
                LabeledContent("Total Income", value: budget.incomeInMonth(selectedMonth), format: .currency(code: currencyManager.currencyCode))
                LabeledContent("Total Expenses", value: budget.expensesInMonth(selectedMonth), format: .currency(code: currencyManager.currencyCode))
                LabeledContent("Remaining") {
                    Text(budget.remainingInMonth(selectedMonth), format: .currency(code: currencyManager.currencyCode))
                        .foregroundStyle(budget.remainingInMonth(selectedMonth) >= 0 ? .green : .red)
                        .fontWeight(.semibold)
                }
            }
            
            Section("Categories") {
                if let viewModel = categoryViewModel {
                    if viewModel.categories.isEmpty {
                        Text("No categories")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.categories) { category in
                            NavigationLink(destination: CategoryTransactionsView(category: category, month: selectedMonth)) {
                                CategoryRowView(category: category, month: selectedMonth)
                            }
                        }
                    }
                    
                    // MARK: - Inline Quick Create Row
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
        .navigationTitle(budget.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    NavigationLink {
                        BudgetHistoryView(budget: budget)
                    } label: {
                        Label("View History", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    
                    Divider()
                    
                    Button {
                        isImportingTransactions = true
                    } label: {
                        Label("Import Transactions", systemImage: "square.and.arrow.down")
                    }
                    
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Budget", systemImage: "pencil")
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
        .fileImporter(
            isPresented: $isImportingTransactions,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFilePicked(result)
        }
        .sheet(isPresented: $showingImportMonthPicker, onDismiss: {
            if let url = pendingImportURL {
                executeTransactionImport(from: url)
                pendingImportURL = nil
            }
        }) {
            MonthPickerView(selectedDate: $importMonth)
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
    
    // Step 1: File picked → copy to temp, show month picker
    private func handleFilePicked(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importErrorMessage = "Permission denied."
                showingImportError = true
                return
            }
            
            // Copy to temp so we can access it after the security scope ends
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try FileManager.default.copyItem(at: url, to: tempURL)
            } catch {
                url.stopAccessingSecurityScopedResource()
                importErrorMessage = "Failed to prepare file: \(error.localizedDescription)"
                showingImportError = true
                return
            }
            url.stopAccessingSecurityScopedResource()
            
            // Pre-fill with current viewing month, then show picker
            importMonth = selectedMonth
            pendingImportURL = tempURL
            showingImportMonthPicker = true
            
        case .failure(let error):
            importErrorMessage = error.localizedDescription
            showingImportError = true
        }
    }
    
    // Step 2: Month selected → run import
    private func executeTransactionImport(from url: URL) {
        do {
            let parser = CSVParser.shared
            let importManager = ImportManager(modelContext: modelContext)
            
            let transactions = try parser.parseTransactions(from: url)
            let count = try importManager.importTransactions(
                from: transactions,
                into: budget,
                budgetPeriod: importMonth
            )
            
            importMessage = "Successfully imported \(count) transactions."
            showingImportAlert = true
            
            // Refresh data
            transactionViewModel?.loadTransactions(for: budget)
            categoryViewModel?.loadCategories(for: budget)
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: url)
            
        } catch {
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
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Budget.self, configurations: config)
    let budget = Budget(name: "Monthly Budget", totalAmount: 5000)
    container.mainContext.insert(budget)
    
    return NavigationStack {
        BudgetDetailView(budget: budget)
            .modelContainer(container)
            .environmentObject(CurrencyManager())
    }
}
