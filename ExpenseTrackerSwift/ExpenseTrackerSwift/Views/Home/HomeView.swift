import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Budget> { $0.isActive == true })
    private var activeBudgets: [Budget]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    if let currentBudget = activeBudgets.first {
                        BudgetSummaryCard(budget: currentBudget)
                    } else {
                        EmptyBudgetCard()
                    }
                    
                    // Recent Transactions
                    RecentTransactionsSection()
                    
                    // Category Overview
                    CategoryOverviewSection()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct BudgetSummaryCard: View {
    let budget: Budget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(budget.name)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(budget.totalAmount, format: .currency(code: "USD"))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(budget.remainingAmount, format: .currency(code: "USD"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(budget.remainingAmount >= 0 ? .green : .red)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    let progress = min(max(0, Double(truncating: (budget.totalExpenses / budget.totalAmount) as NSDecimalNumber)), 1.0)
                    
                    Rectangle()
                        .fill(progress > 0.9 ? Color.red : Color.blue)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct EmptyBudgetCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text("No Active Budget")
                .font(.headline)
            
            Text("Create a budget to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            NavigationLink(destination: BudgetListView()) {
                Text("Create Budget")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RecentTransactionsSection: View {
    @Query(
        filter: #Predicate<Transaction> { $0.isActive == true },
        sort: \Transaction.date,
        order: .reverse
    )
    private var recentTransactions: [Transaction]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Transactions")
                .font(.headline)
                .padding(.horizontal)
            
            if recentTransactions.isEmpty {
                Text("No transactions yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(recentTransactions.prefix(5)) { transaction in
                    TransactionRowView(transaction: transaction)
                }
            }
        }
    }
}

struct CategoryOverviewSection: View {
    @Query(filter: #Predicate<Category> { $0.isActive == true })
    private var categories: [Category]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Categories")
                .font(.headline)
                .padding(.horizontal)
            
            if categories.isEmpty {
                Text("No categories yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(categories.prefix(5)) { category in
                    CategoryRowView(category: category)
                }
            }
        }
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transaction.desc)
                    .font(.body)
                
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(transaction.amount, format: .currency(code: "USD"))
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(transaction.isIncome ? .green : .red)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct CategoryRowView: View {
    let category: Category
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(category.name)
                    .font(.body)
                
                Spacer()
                
                Text("\(Int(category.usagePercentage * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(category.isOverBudget ? Color.red : Color.blue)
                        .frame(width: geometry.size.width * min(category.usagePercentage, 1.0), height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
}
