import SwiftUI
import SwiftData

struct TransactionQuickAddSheet: View {
    @Bindable var viewModel: TransactionViewModel
    let activeBudgets: [Budget]
    let initialBudget: Budget
    
    var body: some View {
        TransactionFormView(
            activeBudgets: activeBudgets,
            initialBudget: initialBudget,
            viewModel: viewModel
        )
    }
}
