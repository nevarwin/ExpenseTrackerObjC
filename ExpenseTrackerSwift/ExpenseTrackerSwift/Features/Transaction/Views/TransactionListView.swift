import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
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
    
    private func deleteTransactions(at offsets: IndexSet) {
        guard let viewModel = viewModel else { return }
        
        for index in offsets {
            let transaction = viewModel.transactions[index]
            try? viewModel.deleteTransaction(transaction)
        }
    }
    
    @ViewBuilder
    private func calendarContent(viewModel: TransactionViewModel) -> some View {
        TransactionCalendarView(viewModel: viewModel) { hasTransactions in
            hasUserSelectedDate = true
            if !hasTransactions && !activeBudgets.isEmpty {
                showingAddTransaction = true
            }
        }
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func transactionListContent(viewModel: TransactionViewModel) -> some View {
        VStack(spacing: 0) {
            if verticalSizeClass != .compact {
                calendarContent(viewModel: viewModel)
            }
            
            List {
                if viewModel.isLoading {
                    Section {
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
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        }
                    }
                    .accessibilityIdentifier("transaction_loading")
                } else if !hasUserSelectedDate && viewModel.searchText.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "Select a Date",
                            systemImage: "calendar",
                            description: Text(verticalSizeClass == .compact ? "Tap a date on the calendar to the left to view your transactions." : "Tap a date on the calendar above to view your transactions.")
                        )
                        .padding(.vertical, 40)
                        .accessibilityIdentifier("transaction_empty_select_date")
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else if viewModel.transactions.isEmpty {
                    Section {
                        ContentUnavailableView(
                            viewModel.searchText.isEmpty ? "No Transactions" : "No Results",
                            systemImage: viewModel.searchText.isEmpty ? "list.bullet" : "magnifyingglass",
                            description: Text(viewModel.searchText.isEmpty ? "No transactions found for this period" : "No transactions match '\(viewModel.searchText)'")
                        )
                        .padding(.vertical, 40)
                        .accessibilityIdentifier("transaction_empty_no_results")
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    Section {
                        ForEach(Array(viewModel.transactions.enumerated()), id: \.element.id) { index, transaction in
                            Button {
                                selectedTransaction = transaction
                            } label: {
                                TransactionRowView(transaction: transaction)
                                    .background {
                                        if index == 0 {
                                            GeometryReader { proxy in
                                                Color.clear
                                                    .preference(
                                                        key: ScrollOffsetPreferenceKey.self,
                                                        value: proxy.frame(in: .named("scroll")).minY
                                                    )
                                            }
                                        }
                                    }
                            }
                            .bouncyButtonStyle()
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    try? viewModel.deleteTransaction(transaction)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    selectedTransaction = transaction
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    } header: {
                        EmptyView()
                    } footer: {
                        EmptyView()
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(0)
            .coordinateSpace(name: "scroll")
            .accessibilityIdentifier("transaction_list")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                guard !viewModel.isLoading else { return }
                // Collapsing logic
                // If scrolling down (value goes negative), collapse to week
                // If scrolling up near top (value goes near 0), expand to month
                if value < -20 && viewModel.calendarScope == .month {
                    withAnimation {
                        viewModel.calendarScope = .week
                    }
                } else if value >= 0 && viewModel.calendarScope == .week {
                    withAnimation {
                        viewModel.calendarScope = .month
                    }
                }
            }
        }
    }
}

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
