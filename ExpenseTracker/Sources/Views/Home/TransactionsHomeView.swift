//
//  TransactionsHomeView.swift
//  ExpenseTracker
//
//  Created by raven on 6/26/25.
//

import SwiftUI
import CoreData

struct TransactionsHomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: TransactionsViewModel
    @State private var showTransactionForm = false
    @State private var selectedTransaction: Transaction?
    @State private var showMonthPicker = false
    @State private var showYearPicker = false
    
    init() {
        // Will be initialized properly in onAppear with the environment context
        _viewModel = StateObject(wrappedValue: TransactionsViewModel(context: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                datePickerView
                segmentControls
                transactionsList
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showTransactionForm) {
            TransactionFormView(context: viewContext)
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionFormView(existingTransaction: transaction, context: viewContext)
        }
        .sheet(isPresented: $showMonthPicker) {
            MonthPickerView(selectedMonth: viewModel.currentDateComponents.month ?? 1) { month in
                viewModel.currentDateComponents.month = month
                viewModel.updateFilters()
            }
        }
        .sheet(isPresented: $showYearPicker) {
            YearPickerView(selectedYear: viewModel.currentDateComponents.year ?? 2025) { year in
                viewModel.currentDateComponents.year = year
                viewModel.updateFilters()
            }
        }
        .onAppear {
            // Update viewModel with environment context if needed
            viewModel.updateFilters()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Transactions")
                .font(.system(size: 34, weight: .bold))
            Spacer()
            Button(action: {
                showTransactionForm = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var datePickerView: some View {
        HStack {
            Button(action: { viewModel.previousMonth() }) {
                Text("◀︎")
                    .font(.system(size: 20, weight: .bold))
            }
            
            Spacer()
            
            Button(action: { showMonthPicker = true }) {
                Text(viewModel.monthYearString.components(separatedBy: " ").first ?? "")
                    .font(.system(size: 22, weight: .semibold))
            }
            
            Button(action: { showYearPicker = true }) {
                Text(viewModel.monthYearString.components(separatedBy: " ").last ?? "")
                    .font(.system(size: 22, weight: .semibold))
            }
            
            Spacer()
            
            Button(action: { viewModel.nextMonth() }) {
                Text("▶︎")
                    .font(.system(size: 20, weight: .bold))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var segmentControls: some View {
        VStack(spacing: 8) {
            Picker("Type", selection: $viewModel.selectedTypeIndex) {
                Text("Expense").tag(0)
                Text("Income").tag(1)
                Text("All").tag(2)
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.selectedTypeIndex) { _ in
                viewModel.updateFilters()
            }
            
            Picker("Week", selection: $viewModel.selectedWeekIndex) {
                ForEach(0..<5) { index in
                    Text("Week \(index + 1)").tag(index)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.selectedWeekIndex) { _ in
                viewModel.updateFilters()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var transactionsList: some View {
        List {
            Section(header: Text("Transactions \(viewModel.dateRange)")) {
                ForEach(viewModel.transactions, id: \.objectID) { transaction in
                    TransactionRow(transaction: transaction)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deleteTransaction(transaction)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
                            selectedTransaction = transaction
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.category?.isIncome == true ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(transaction.category?.isIncome == true ? .green : .red)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category?.name ?? "Unknown")
                    .font(.system(size: 18, weight: .bold))
                
                if let date = transaction.date {
                    Text(date, style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let amount = transaction.amount {
                Text(formatAmount(amount, isIncome: transaction.category?.isIncome == true))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(transaction.category?.isIncome == true ? .green : .red)
            }
        }
    }
    
    private func formatAmount(_ amount: NSDecimalNumber, isIncome: Bool) -> String {
        let sign = isIncome ? "+" : "–"
        return "\(sign) \(CurrencyFormatter.format(amount))"
    }
}

extension Transaction: Identifiable {
    public var id: NSManagedObjectID {
        objectID
    }
}

#Preview {
    TransactionsHomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
