import SwiftData
import SwiftUI

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
            Group {
                if let viewModel = viewModel {
                    BudgetListContent(viewModel: viewModel)
                } else {
                    ProgressView()
                        .onAppear {
                            // Initialize ViewModel exactly once if not injected
                            if injectedViewModel == nil {
                                let vm = BudgetViewModel(modelContext: modelContext)
                                self.internalViewModel = vm
                                vm.loadBudgets()
                            }
                        }
                }
            }
            .navigationTitle("Budgets")
            .navigationDestination(for: Budget.self) { budget in
                BudgetDetailView(budget: budget)
            }
        }
    }
}

struct BudgetListContent: View {
    @ObservedObject var viewModel: BudgetViewModel
    @State private var showingAddBudget = false
    @State private var showingError = false
    
    var body: some View {
        contentView
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddBudget = true }) {
                        Label("Add Budget", systemImage: "plus")
                    }
                }
            }
        .sheet(
            isPresented: $showingAddBudget,
            onDismiss: {
                // Reload budgets when sheet dismisses to ensure list is updated
                viewModel.loadBudgets()
            }
        ) {
            BudgetFormView(viewModel: viewModel)
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
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.budgets.isEmpty {
            if viewModel.isLoading {
                ProgressView("Loading budgets...")
            } else {
                ContentUnavailableView(
                    "No Budgets",
                    systemImage: "creditcard",
                    description: Text("Create your first budget to get started")
                )
            }
        } else {
            List {
                ForEach(viewModel.budgets) { budget in
                    NavigationLink(value: budget) {
                        BudgetRowView(budget: budget)
                    }
                }
                .onDelete(perform: deleteBudgets)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.large)
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private func deleteBudgets(at offsets: IndexSet) {
        // Collect budgets to delete
        let budgetsToDelete = offsets.map { viewModel.budgets[$0] }
        
        // Delete each budget
        for budget in budgetsToDelete {
            do {
                try viewModel.deleteBudget(budget)
            } catch {
                viewModel.errorMessage = "Failed to delete budget: \(error.localizedDescription)"
            }
        }
    }
}

struct BudgetRowView: View {
    let budget: Budget
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.name)
                    .font(.headline)
                
                Spacer()
                
                if !budget.isActive {
                    Text("Inactive")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(budget.totalAmount, format: .currency(code: currencyManager.currencyCode))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(budget.remainingAmount, format: .currency(code: currencyManager.currencyCode))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(budget.remainingAmount >= 0 ? .green : .red)
                }
            }
            
            // Progress indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    let progress =
                    budget.totalAmount > 0
                    ? min(
                        max(
                            0,
                            Double(truncating: (budget.totalExpenses / budget.totalAmount) as NSDecimalNumber)),
                        1.0) : 0
                    
                    Rectangle()
                        .fill(progress > 0.9 ? Color.red : Color.blue)
                        .frame(width: geometry.size.width * progress, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        BudgetListView()
    }
    .modelContainer(for: [Budget.self, Category.self, Transaction.self])
}
