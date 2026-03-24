import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BudgetListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var internalViewModel: BudgetViewModel?
    private let injectedViewModel: BudgetViewModel?
    
    private var viewModel: BudgetViewModel? {
        injectedViewModel ?? internalViewModel
    }
    
    init(viewModel: BudgetViewModel? = nil) {
        self.injectedViewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
                if let viewModel = viewModel {
                    HomeContent(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Budgets")
            .onAppear {
                PostHogManager.shared.trackScreen("Home")
                if injectedViewModel == nil && internalViewModel == nil {
                    let vm = BudgetViewModel(modelContext: modelContext)
                    self.internalViewModel = vm
                    vm.loadBudgets()
                }
            }
        }
    }
}

struct HomeContent: View {
    @ObservedObject var viewModel: BudgetViewModel
    
    @State private var showingAddBudget = false
    @State private var budgetToEdit: Budget?
    @State private var showingError = false
    @State private var isImportingBudget = false
    @State private var importSuccessMessage: String?
    @State private var showingImportAlert = false
    @State private var budgetToDelete: Budget?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Cards
                if viewModel.budgets.isEmpty {
                    EmptyBudgetCard(viewModel: viewModel) {
                        showingAddBudget = true
                    }
                    .padding(.horizontal)
                } else {
                    ForEach(viewModel.budgets) { budget in
                        NavigationLink(destination: BudgetDetailView(budget: budget, viewModel: viewModel)) {
                            BudgetSummaryCard(budget: budget)
                                .padding(.horizontal)
                                .id(budget.id)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                budgetToDelete = budget
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                budgetToEdit = budget
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            viewModel.loadBudgets()
        }
        .sheet(
            isPresented: $showingAddBudget,
            onDismiss: {
                viewModel.loadBudgets()
            }
        ) {
            BudgetFormView(viewModel: viewModel)
        }
        .sheet(item: $budgetToEdit, onDismiss: {
            viewModel.loadBudgets()
        }) { budget in
            BudgetFormView(viewModel: viewModel, existingBudget: budget)
        }
        .fileImporter(
            isPresented: $isImportingBudget,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: true
        ) { result in
            handleImport(result)
        }
        .alert("Import Result", isPresented: $showingImportAlert) {
            Button("OK") { }
        } message: {
            Text(importSuccessMessage ?? "Unknown result")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            showingError = newValue != nil
        }
        .confirmationDialog(
            "Delete Budget",
            isPresented: Binding(
                get: { budgetToDelete != nil },
                set: { if !$0 { budgetToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let budget = budgetToDelete {
                    try? viewModel.deleteBudget(budget)
                }
            }
            Button("Cancel", role: .cancel) {
                budgetToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this budget? All associated categories and transactions will be permanently deleted.")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    toolbarMenu
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    @ViewBuilder
    private var toolbarMenu: some View {
        Button {
            showingAddBudget = true
        } label: {
            Label("Add Budget", systemImage: "plus")
        }
        
        Button {
            isImportingBudget = true
        } label: {
            Label("Import Budget", systemImage: "square.and.arrow.down")
        }
        
        Divider()
        
        NavigationLink {
            SettingsView()
        } label: {
            Label("Settings", systemImage: "gearshape.fill")
        }
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else { return }
            
            do {
                let parser = CSVParser.shared
                let importManager = ImportManager(modelContext: viewModel.modelContext)
                var importedNames: [String] = []
                var failedCount = 0
                
                for url in urls {
                    if url.startAccessingSecurityScopedResource() {
                        do {
                            let csvBudget = try parser.parseBudget(from: url)
                            let newBudget = try importManager.importBudget(from: csvBudget)
                            importedNames.append(newBudget.name)
                        } catch {
                            print("DEBUG: Import failed for \(url.lastPathComponent): \(error.localizedDescription)")
                            failedCount += 1
                        }
                        url.stopAccessingSecurityScopedResource()
                    } else {
                        failedCount += 1
                    }
                }
                
                if importedNames.isEmpty {
                    viewModel.errorMessage = "Failed to import budgets. Ensure files are accessible."
                } else {
                    let baseMessage = "Successfully imported \(importedNames.count) budget(s)."
                    importSuccessMessage = failedCount > 0 ? "\(baseMessage) (\(failedCount) failed.)" : baseMessage
                    showingImportAlert = true
                    viewModel.loadBudgets()
                }
            }
            
        case .failure(let error):
            viewModel.errorMessage = "Import failed: \(error.localizedDescription)"
        }
    }
}

struct BudgetSummaryCard: View {
    let budget: Budget
    @EnvironmentObject var currencyManager: CurrencyManager
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.name)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.appPrimary)
                    
                    Text("\(DateRangeHelper.monthYearString(from: Date())) Budget")
                        .subheaderStyle()
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.appLightGray, lineWidth: 6)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(
                            budget.remainingAmount >= 0 ? Color.appAccent : Color.red,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "creditcard.fill")
                        .font(.caption)
                        .foregroundStyle(Color.appSecondary)
                }
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Income")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(budget.currentMonthIncome, format: .currency(code: currencyManager.currencyCode))
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                            Text("/ " + budget.plannedIncome().formatted(.currency(code: currencyManager.currencyCode)))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Expenses")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(budget.currentMonthExpenses, format: .currency(code: currencyManager.currencyCode))
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(budget.currentMonthExpenses > budget.plannedExpenses() ? .red : .appPrimary)
                            Text("/ " + budget.plannedExpenses().formatted(.currency(code: currencyManager.currencyCode)))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Progress Bar (Expense vs Planned)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.appLightGray)
                            .frame(height: 12)
                        
                        let isOverBudget = budget.currentMonthExpenses > budget.plannedExpenses() && budget.plannedExpenses() > 0
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        isOverBudget ? Color.red : Color.appAccent,
                                        isOverBudget ? Color.orange : Color.cyan
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, min(geometry.size.width * animatedProgress, geometry.size.width)), height: 12)
                    }
                }
                .frame(height: 12)
            }
        }
        .appCardStyle()
        .onAppear {
            updateProgress()
        }
        .onChange(of: budget.currentMonthExpenses) { _, _ in
            updateProgress()
        }
        .onChange(of: budget.categories) { _, _ in
            updateProgress()
        }
    }
    
    private func updateProgress() {
        let planned = budget.plannedExpenses()
        let spent = budget.currentMonthExpenses
        let progress = planned > 0 ? min(max(0, Double(truncating: (spent / planned) as NSDecimalNumber)), 1.0) : 0
        
        withAnimation(.spring(duration: 1.0)) {
            animatedProgress = progress
        }
    }
}

struct EmptyBudgetCard: View {
    var viewModel: BudgetViewModel?
    var onAddBudget: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.appAccent)
                .padding(.top, 8)
            
            VStack(spacing: 8) {
                Text("No Active Budget")
                    .headerStyle()
                
                Text("Create your first budget to start tracking your expenses effectively.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.appSecondary)
                    .padding(.horizontal)
            }
            
            Button(action: { onAddBudget?() }) {
                Text("Create New Budget")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appAccent)
                    .cornerRadius(12)
                    .shadow(color: Color.appAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .appCardStyle()
    }
}


#Preview {
    BudgetListView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
        .environmentObject(CurrencyManager())
}
