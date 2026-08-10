import SwiftUI
import SwiftData

@main
struct ExpenseMeApp: App {
    @StateObject private var appearanceManager: SharedAppearanceService
    @StateObject private var currencyManager: SharedCurrencyService

    let modelContainer: ModelContainer

    private static var isUITestMode: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITestMode")
    }

    init() {
        // 1. Configure services
        SharedAppearanceService.configure()
        SharedAnalyticsService.configure()
        SharedCurrencyService.configure()
        SharedPermissionService.configure()

        // 2. Setup analytics
        SharedAnalyticsService.instance.setup()

        // 3. Initialize StateObjects
        _appearanceManager = StateObject(wrappedValue: SharedAppearanceService.instance)
        _currencyManager = StateObject(wrappedValue: SharedCurrencyService.instance)

        // 4. Create model container (in-memory for UI tests)
        if Self.isUITestMode {
            let schema = Schema([Transaction.self, Category.self, Budget.self, InstallmentPlan.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                let container = try ModelContainer(for: schema, configurations: [config])
                Self.seedUITestData(into: container.mainContext)
                self.modelContainer = container
            } catch {
                fatalError("UITestMode: Failed to create in-memory container: \(error)")
            }
        } else {
            do {
                self.modelContainer = try ModelContainer(for: Transaction.self, Category.self, Budget.self, InstallmentPlan.self)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appearanceManager)
                .environmentObject(currencyManager)
                .preferredColorScheme(appearanceManager.userAppearance.colorScheme)
                .tint(appearanceManager.selectedAccent.color)
        }
        .modelContainer(modelContainer)
    }

    // MARK: - UI Test Seed Data

    @MainActor
    private static func seedUITestData(into context: ModelContext) {
        let budget = Budget(name: "Monthly Budget", totalAmount: 5000, isActive: true)
        context.insert(budget)

        // Expense categories
        let food = Category(name: "Food", allocatedAmount: 1000, isIncome: false, budget: budget)
        let transport = Category(name: "Transport", allocatedAmount: 500, isIncome: false, budget: budget)
        let shopping = Category(name: "Shopping", allocatedAmount: 800, isIncome: false, budget: budget)

        // Income category
        let salary = Category(name: "Salary", allocatedAmount: 3000, isIncome: true, budget: budget)

        [food, transport, shopping, salary].forEach { context.insert($0) }

        // Pre-existing transaction for today (so list/delete/edit tests have data)
        let transaction = Transaction(
            amount: 50,
            description: "Lunch at cafe",
            date: Date(),
            budget: budget,
            category: food
        )
        context.insert(transaction)

        try? context.save()
    }
}
