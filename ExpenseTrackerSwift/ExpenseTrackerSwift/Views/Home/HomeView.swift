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
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
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
            
            // Settings
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundStyle(Color.appSecondary)
            }
            .padding(.trailing, 8)
            
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
                        Text("Spent")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        Text(budget.currentMonthExpenses, format: .currency(code: currencyManager.currencyCode))
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.appPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Remaining")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        Text(budget.currentMonthRemaining, format: .currency(code: currencyManager.currencyCode))
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(budget.currentMonthRemaining >= 0 ? Color.green : Color.red)
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
                                        budget.currentMonthRemaining >= 0 ? Color.appAccent : Color.red,
                                        budget.currentMonthRemaining >= 0 ? Color.cyan : Color.orange
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
            let progress = min(max(0, Double(truncating: (budget.currentMonthExpenses / budget.totalAmount) as NSDecimalNumber)), 1.0)
            withAnimation(.spring(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: budget.currentMonthExpenses) { oldVal, newVal in
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


#Preview {
    HomeView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
        .environmentObject(CurrencyManager())
}
