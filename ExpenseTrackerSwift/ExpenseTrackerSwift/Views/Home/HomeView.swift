import SwiftUI
import SwiftData

struct HomeView: View {
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
                // Background
                Color.appLightGray.ignoresSafeArea()
                
                if let viewModel = viewModel {
                    HomeContent(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                WelcomeHeader(viewModel: viewModel)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // Summary Cards
                if let currentBudget = viewModel.selectedBudget {
                    BudgetSummaryCard(budget: currentBudget)
                        .padding(.horizontal)
                        .id(currentBudget.id)
                } else {
                    EmptyBudgetCard(viewModel: viewModel)
                        .padding(.horizontal)
                }
                
                // Recent Transactions
                if let currentBudget = viewModel.selectedBudget {
                    RecentTransactionsSection(budget: currentBudget)
                        .padding(.horizontal)
                        .id(currentBudget.id)
                }
                
                // Category Overview
                if let currentBudget = viewModel.selectedBudget {
                    CategoryOverviewSection(budget: currentBudget)
                        .padding(.horizontal)
                        .id(currentBudget.id)
                }
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            viewModel.loadBudgets()
        }
    }
}

struct WelcomeHeader: View {
    @ObservedObject var viewModel: BudgetViewModel
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appSecondary)
                
                Text(viewModel.selectedBudget?.name ?? "Dashboard")
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.appPrimary)
            }
            Spacer()
            
            // Budget Switcher
            Menu {
                ForEach(viewModel.budgets.filter { $0.isActive }) { budget in
                    Button {
                        withAnimation {
                            viewModel.selectBudget(budget)
                        }
                    } label: {
                        HStack {
                            Text(budget.name)
                            if viewModel.selectedBudget?.id == budget.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Divider()
                
                NavigationLink(destination: BudgetListView(viewModel: viewModel)) {
                    Label("Manage Budgets", systemImage: "gearshape")
                }
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.appAccent)
                    .opacity(0.8)
            }
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
                    
                    Text("Monthly Budget")
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
                        Text("Spent")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        Text(budget.totalExpenses, format: .currency(code: currencyManager.currencyCode))
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.appPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Remaining")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        Text(budget.remainingAmount, format: .currency(code: currencyManager.currencyCode))
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(budget.remainingAmount >= 0 ? Color.green : Color.red)
                    }
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.appLightGray)
                            .frame(height: 12)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        budget.remainingAmount >= 0 ? Color.appAccent : Color.red,
                                        budget.remainingAmount >= 0 ? Color.cyan : Color.orange
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
        .cardStyle()
        .onAppear {
            let progress = min(max(0, Double(truncating: (budget.totalExpenses / budget.totalAmount) as NSDecimalNumber)), 1.0)
            withAnimation(.spring(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: budget.totalExpenses) { oldVal, newVal in
             let progress = min(max(0, Double(truncating: (newVal / budget.totalAmount) as NSDecimalNumber)), 1.0)
             withAnimation(.spring(duration: 1.0)) {
                 animatedProgress = progress
             }
        }
    }
}

struct EmptyBudgetCard: View {
    var viewModel: BudgetViewModel?
    
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
            
            NavigationLink(destination: BudgetListView(viewModel: viewModel)) {
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
        .cardStyle()
    }
}

struct RecentTransactionsSection: View {
    @Query private var recentTransactions: [Transaction]
    
    init(budget: Budget) {
        let budgetId = budget.id
        _recentTransactions = Query(
            filter: #Predicate<Transaction> {
                $0.budget?.id == budgetId && $0.isActive == true
            },
            sort: \Transaction.date,
            order: .reverse
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .headerStyle()
                Spacer()
                NavigationLink(destination: TransactionListView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(Color.appAccent)
                }
            }
            
            if recentTransactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.largeTitle)
                        .foregroundStyle(Color.gray.opacity(0.3))
                    Text("No recent transactions")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color.white)
                .cornerRadius(16)
            } else {
                VStack(spacing: 0) {
                    ForEach(recentTransactions.prefix(5)) { transaction in
                        TransactionRowView(transaction: transaction)
                        if transaction != recentTransactions.prefix(5).last {
                            Divider()
                                .padding(.leading, 70) // Indented divider
                        }
                    }
                }
                .cardStyle(padding: 0)
            }
        }
    }
}

struct CategoryOverviewSection: View {
    @Query private var categories: [Category]
    
    init(budget: Budget) {
        let budgetId = budget.id
        _categories = Query(
            filter: #Predicate<Category> {
                $0.budget?.id == budgetId && $0.isActive == true
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Categories")
                    .headerStyle()
                Spacer()
                // Optional: Link to full category list if essential
            }
            
            if categories.isEmpty {
                 Text("No categories found")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(categories) { category in
                            CategorySummaryCard(category: category)
                        }
                    }
                    .padding(.vertical, 10) // Space for shadow
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}

struct CategorySummaryCard: View {
    let category: Category
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon & Name
            HStack {
                Image(systemName: IconHelper.icon(for: category.name))
                    .foregroundStyle(Color.white)
                    .font(.caption)
                    .padding(8)
                    .background(Color.appAccent)
                    .clipShape(Circle())
                
                Text(category.name)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
            }
            
            // Stats
            VStack(alignment: .leading, spacing: 4) {
                Text("Available")
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
                
                Text(category.remainingAmount, format: .currency(code: currencyManager.currencyCode))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(category.remainingAmount >= 0 ? Color.appPrimary : Color.red)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appLightGray)
                        .frame(height: 6)
                    
                    let progress = min(max(0, category.usagePercentage), 1.0)
                    Capsule()
                        .fill(category.isOverBudget ? Color.red : Color.appAccent)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
            
            // Details text (Spent / Total)
            HStack {
                Text("\(category.usedAmount.formatted(.currency(code: currencyManager.currencyCode))) spent")
                Spacer()
                Text("of \(category.allocatedAmount.formatted(.currency(code: currencyManager.currencyCode)))")
            }
            .font(.caption2)
            .foregroundStyle(Color.secondary)
        }
        .padding(16)
        .frame(width: 160)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.appLightGray)
                    .frame(width: 40, height: 40)
                
                if let category = transaction.category {
                    Image(systemName: IconHelper.icon(for: category.name))
                        .foregroundStyle(Color.appAccent)
                        .font(.system(size: 16))
                } else {
                    Image(systemName: "bag.fill")
                        .foregroundStyle(Color.appSecondary)
                        .font(.caption)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.desc)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.appPrimary)
                
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
            
            Spacer()
            
            Text(transaction.amount, format: .currency(code: currencyManager.currencyCode))
                .font(.system(.body, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(transaction.isIncome ? Color.green : Color.appPrimary)
        }
        .padding()
        .background(Color.white)
    }
}

// MARK: - Helper

struct IconHelper {
    static func icon(for name: String) -> String {
        let n = name.lowercased()
        if n.contains("food") || n.contains("eat") || n.contains("restaurant") { return "fork.knife" }
        if n.contains("transport") || n.contains("travel") || n.contains("gas") || n.contains("car") { return "car.fill" }
        if n.contains("shop") || n.contains("cloth") || n.contains("buy") { return "bag.fill" }
        if n.contains("house") || n.contains("rent") || n.contains("home") { return "house.fill" }
        if n.contains("bill") || n.contains("utility") || n.contains("electric") { return "bolt.fill" }
        if n.contains("entertainment") || n.contains("movie") || n.contains("game") { return "tv.fill" }
        if n.contains("health") || n.contains("med") || n.contains("doctor") { return "heart.fill" }
        if n.contains("work") || n.contains("salary") { return "briefcase.fill" }
        if n.contains("money") || n.contains("cash") { return "banknote.fill" }
        return "tag.fill"
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
        .environmentObject(CurrencyManager())
}
