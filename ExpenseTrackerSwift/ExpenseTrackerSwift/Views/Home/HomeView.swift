import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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
    
    @State private var showingAddBudget = false
    @State private var showingError = false
    @State private var isImportingBudget = false
    @State private var importSuccessMessage: String?
    @State private var showingImportAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                WelcomeHeader(
                    viewModel: viewModel,
                    onAddBudget: { showingAddBudget = true },
                    onImportBudget: { isImportingBudget = true }
                )
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // Summary Cards
                if viewModel.budgets.isEmpty {
                    EmptyBudgetCard(viewModel: viewModel) {
                        showingAddBudget = true
                    }
                    .padding(.horizontal)
                } else {
                    ForEach(viewModel.budgets) { budget in
                        NavigationLink(destination: BudgetDetailView(budget: budget)) {
                            BudgetSummaryCard(budget: budget)
                                .padding(.horizontal)
                                .id(budget.id)
                        }
                        .buttonStyle(.plain)
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
        .fileImporter(
            isPresented: $isImportingBudget,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
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
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                viewModel.errorMessage = "Permission denied to access the file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let parser = CSVParser.shared
                let importManager = ImportManager(modelContext: viewModel.modelContext)
                
                let csvBudget = try parser.parseBudget(from: url)
                let newBudget = try importManager.importBudget(from: csvBudget)
                
                importSuccessMessage = "Successfully imported budget '\(newBudget.name)'."
                showingImportAlert = true
                viewModel.loadBudgets()
                
            } catch {
                viewModel.errorMessage = "Import failed: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            viewModel.errorMessage = "Import failed: \(error.localizedDescription)"
        }
    }
}

struct WelcomeHeader: View {
    @ObservedObject var viewModel: BudgetViewModel
    let onAddBudget: () -> Void
    let onImportBudget: () -> Void
    
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
            
            HStack(spacing: 16) {
                Menu {
                    Button(action: onAddBudget) {
                        Label("Add Budget", systemImage: "plus")
                    }
                    Button(action: onImportBudget) {
                        Label("Import Budget", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.appAccent)
                }
                
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundStyle(Color.appSecondary)
                }
            }
            .padding(.trailing, 8)
            
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
        .appCardStyle()
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
    HomeView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
        .environmentObject(CurrencyManager())
}
