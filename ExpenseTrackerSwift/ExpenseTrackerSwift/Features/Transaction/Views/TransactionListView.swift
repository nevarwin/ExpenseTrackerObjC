import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currencyManager: SharedCurrencyService
    @State private var viewModel: TransactionViewModel?
    @State private var showingAddTransaction = false
    @State private var selectedTransaction: Transaction?
    @State private var hasUserSelectedDate = false

    @Query(filter: #Predicate<Budget> { $0.isActive == true })
    private var activeBudgets: [Budget]

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    Group {
                        if verticalSizeClass == .compact {
                            HStack(alignment: .top, spacing: 16) {
                                ScrollView(.vertical, showsIndicators: false) {
                                    calendarContent(viewModel: viewModel)
                                }
                                .frame(maxWidth: 350)

                                transactionListContent(viewModel: viewModel)
                            }
                        } else {
                            transactionListContent(viewModel: viewModel)
                        }
                    }
                    .onChange(of: viewModel.selectedDate) { _, _ in viewModel.loadTransactions() }
                    .onChange(of: viewModel.selectedDateRange) { _, _ in viewModel.loadTransactions() }

                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { newValue in
                    viewModel?.searchText = newValue
                    if newValue.isEmpty {
                        viewModel?.searchHighlightDates.removeAll()
                        viewModel?.loadTransactions()
                    } else {
                        viewModel?.performGlobalSearch()
                    }
                }
            ), prompt: "Search transactions...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddTransaction = true }) {
                        Label("Add Transaction", systemImage: "plus")
                    }
                    .disabled(activeBudgets.isEmpty)
                    .accessibilityIdentifier("transaction_add_button")
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                if let firstBudget = activeBudgets.first, let viewModel = viewModel {
                    TransactionQuickAddSheet(
                        viewModel: viewModel,
                        activeBudgets: activeBudgets,
                        initialBudget: firstBudget
                    )
                }
            }
            .sheet(item: $selectedTransaction) { transaction in
                if let viewModel = viewModel,
                   let budget = transaction.budget ?? activeBudgets.first {
                    TransactionFormView(
                        activeBudgets: activeBudgets,
                        initialBudget: budget,
                        viewModel: viewModel,
                        existingTransaction: transaction
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TransactionViewModel(modelContext: modelContext)
            }
            viewModel?.loadTransactions()
        }
    }

    // MARK: - Calendar Content

    @ViewBuilder
    private func calendarContent(viewModel: TransactionViewModel) -> some View {
        TransactionCalendarView(viewModel: viewModel) { _ in
            hasUserSelectedDate = true
        }
        .padding(.bottom, 8)
    }

    // MARK: - Unified Scroll Content (Portrait)

    @ViewBuilder
    private func transactionListContent(viewModel: TransactionViewModel) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: []) {
                // Calendar sits at the top of the unified scroll
                if verticalSizeClass != .compact {
                    calendarContent(viewModel: viewModel)
                }

                // Scroll Offset Anchor
                Color.clear
                    .frame(height: 0)
                    .background {
                        GeometryReader { proxy in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: proxy.frame(in: .named("scroll")).minY
                                )
                        }
                    }

                // Financial Summary Header
                transactionSummaryHeader(viewModel: viewModel)
                    .padding(.horizontal)

                // Transaction items
                transactionItemsContent(viewModel: viewModel)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }
        }
        .coordinateSpace(name: "scroll")
        .accessibilityIdentifier("transaction_list")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            guard !viewModel.isLoading else { return }
            if value < -60 && viewModel.calendarScope == .month {
                withAnimation(.easeInOut) {
                    viewModel.calendarScope = .week
                }
            } else if value >= 10 && viewModel.calendarScope == .week {
                withAnimation(.easeInOut) {
                    viewModel.calendarScope = .month
                }
            }
        }
    }

    // MARK: - Financial Summary Header

    @ViewBuilder
    private func transactionSummaryHeader(viewModel: TransactionViewModel) -> some View {
        if !viewModel.transactions.isEmpty {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Income")
                        .font(.caption2)
                        .foregroundStyle(Color.appSecondary)
                    Text(viewModel.totalIncome, format: .currency(code: currencyManager.currencyCode))
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.emeraldPrimary)
                }

                Spacer()

                VStack(alignment: .center, spacing: AppSpacing.xs) {
                    Text("Expense")
                        .font(.caption2)
                        .foregroundStyle(Color.appSecondary)
                    Text(viewModel.totalExpense, format: .currency(code: currencyManager.currencyCode))
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.appPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    Text("Net")
                        .font(.caption2)
                        .foregroundStyle(Color.appSecondary)
                    Text(viewModel.netBalance, format: .currency(code: currencyManager.currencyCode))
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(viewModel.netBalance >= 0 ? Color.emeraldPrimary : Color.red)
                }
            }
            .appCardStyle()
            .padding(.bottom, AppSpacing.sm)
        }
    }

    // MARK: - Transaction Items

    @ViewBuilder
    private func transactionItemsContent(viewModel: TransactionViewModel) -> some View {
        if viewModel.isLoading {
            loadingSkeletonView
                .accessibilityIdentifier("transaction_loading")
        } else if !hasUserSelectedDate && viewModel.searchText.isEmpty {
            ContentUnavailableView(
                "Select a Date",
                systemImage: "calendar",
                description: Text(
                    verticalSizeClass == .compact
                        ? "Tap a date on the calendar to the left to view your transactions."
                        : "Tap a date on the calendar above to view your transactions."
                )
            )
            .padding(.vertical, 40)
            .accessibilityIdentifier("transaction_empty_select_date")
        } else if viewModel.transactions.isEmpty {
            ContentUnavailableView(
                viewModel.searchText.isEmpty ? "No Transactions" : "No Results",
                systemImage: viewModel.searchText.isEmpty ? "list.bullet" : "magnifyingglass",
                description: Text(
                    viewModel.searchText.isEmpty
                        ? "No transactions found for this period"
                        : "No transactions match '\(viewModel.searchText)'"
                )
            )
            .padding(.vertical, 40)
            .accessibilityIdentifier("transaction_empty_no_results")
        } else {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.transactions, id: \.id) { transaction in
                    SwipeActionView(
                        trailingActions: [
                            SwipeAction(
                                label: String(localized: "Delete"),
                                systemImage: "trash",
                                tint: .red,
                                role: .destructive
                            ) {
                                try? viewModel.deleteTransaction(transaction)
                            }
                        ],
                        onTap: {
                            selectedTransaction = transaction
                        }
                    ) {
                        TransactionRowView(transaction: transaction)
                            .accessibilityIdentifier("transaction_row")
                    }
                }
            }
        }
    }

    // MARK: - Loading Skeleton

    private var loadingSkeletonView: some View {
        LazyVStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { _ in
                HStack(spacing: AppSpacing.lg) {
                    Circle()
                        .fill(Color.appLightGray)
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.appLightGray)
                            .frame(width: 120, height: 16)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.appLightGray)
                            .frame(width: 80, height: 12)
                    }
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appLightGray)
                        .frame(width: 60, height: 18)
                }
                .appCardStyle()
                .redacted(reason: .placeholder)
                .shimmering()
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    TransactionListView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
}
