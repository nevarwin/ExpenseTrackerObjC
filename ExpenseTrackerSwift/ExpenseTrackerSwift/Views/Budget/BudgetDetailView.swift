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
    @State private var showingMonthPicker = false
    
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
    
    var body: some View {
        List {
            // Month Selector
            Section {
                Button {
                    showingMonthPicker = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Viewing Period")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(DateRangeHelper.monthYearString(from: selectedMonth))
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.appAccent)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                }
            }
            
            Section("Recent Transactions") {
                if let viewModel = transactionViewModel {
                    if viewModel.transactions.isEmpty {
                        Text("No transactions")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.transactions.prefix(10)) { transaction in
                            TransactionRowView(transaction: transaction)
                        }
                    }
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
        .sheet(isPresented: $showingMonthPicker) {
            MonthPickerView(selectedDate: $selectedMonth)
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
