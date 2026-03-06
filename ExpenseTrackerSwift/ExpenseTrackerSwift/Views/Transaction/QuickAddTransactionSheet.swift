import SwiftUI
import SwiftData

import SwiftData

struct QuickAddTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: TransactionViewModel
    
    let activeBudgets: [Budget]
    let initialBudget: Budget
    
    @State private var amount: String = ""
    @State private var isIncome: Bool = false
    @State private var selectedCategory: Category?
    @State private var showFullForm: Bool = false
    
    // Defaulting to today and the corresponding budget period
    @State private var date: Date
    @State private var selectedBudgetPeriod: Date
    
    @State private var showingOverflowAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(viewModel: TransactionViewModel, activeBudgets: [Budget], initialBudget: Budget) {
        self.viewModel = viewModel
        self.activeBudgets = activeBudgets
        self.initialBudget = initialBudget
        
        let initialDate = viewModel.selectedDate
        _date = State(initialValue: initialDate)
        _selectedBudgetPeriod = State(initialValue: DateRangeHelper.monthBounds(for: initialDate).start)
    }
    
    var body: some View {
        NavigationStack {
            if showFullForm {
                TransactionFormView(
                    activeBudgets: activeBudgets,
                    initialBudget: initialBudget,
                    viewModel: viewModel
                )
            } else {
                VStack(spacing: 20) {
                    // Amount Input
                    TextField("0.00", text: $amount)
                        .font(.system(size: 54, weight: .bold))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .padding(.top, 30)
                    
                    // Income/Expense Segmented Control
                    Picker("Transaction Type", selection: $isIncome) {
                        Text("Expense").tag(false)
                        Text("Income").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Horizontal Category Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(filteredCategories) { category in
                                CategorySelectionIcon(
                                    category: category,
                                    isSelected: selectedCategory?.id == category.id
                                )
                                .onTapGesture {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            showFullForm = true
                        } label: {
                            Text("Expand for more details")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button {
                            saveTransaction()
                        } label: {
                            Text("Save Transaction")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(12)
                        }
                        .disabled(!isValid)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .navigationTitle("Quick Add")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .alert("Amount Exceeds Allocation", isPresented: $showingOverflowAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Proceed Anyway") {
                        performSave()
                    }
                } message: {
                    Text("The entered amount exceeds the allocated budget for this category. The excess will be applied to the total. Do you want to continue?")
                }
                .alert("Error", isPresented: $showingError) {
                    Button("OK") { }
                } message: {
                    Text(errorMessage)
                }
            }
        }
        .presentationDetents(showFullForm ? [.large] : [.medium, .large])
        .onAppear {
            selectedBudgetPeriod = DateRangeHelper.monthBounds(for: date).start
            viewModel.loadAvailableCategories(
                transactionDate: date,
                budget: initialBudget,
                excluding: nil
            )
        }
        .onChange(of: isIncome) { _, _ in
            // Clear selection when switching types
            selectedCategory = nil
        }
    }
    
    private var filteredCategories: [Category] {
        viewModel.availableCategories.filter { $0.isIncome == isIncome }
    }
    
    private var isValid: Bool {
        guard let decimalAmount = Decimal(string: amount),
              decimalAmount > 0,
              selectedCategory != nil else {
            return false
        }
        return true
    }
    
    private func saveTransaction() {
        guard let decimalAmount = Decimal(string: amount),
              let category = selectedCategory else {
            return
        }
        
        let hasOverflow = viewModel.checkOverflow(
            amount: decimalAmount,
            budget: initialBudget,
            category: category,
            existing: nil
        )
        
        if hasOverflow {
            showingOverflowAlert = true
            return
        }
        
        performSave()
    }
    
    private func performSave() {
        guard let decimalAmount = Decimal(string: amount),
              let category = selectedCategory else { return }
        
        do {
            try viewModel.saveTransaction(
                amount: decimalAmount,
                description: category.name, // Use category name as default description for quick add
                date: date,
                budget: initialBudget,
                category: category,
                budgetPeriod: selectedBudgetPeriod,
                existing: nil
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct CategorySelectionIcon: View {
    let category: Category
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: IconHelper.icon(for: category.name))
                .font(.title2)
                .foregroundColor(isSelected ? .white : Color.appSecondary)
                .frame(width: 60, height: 60)
                .background(isSelected ? Color.appAccent : Color.appLightGray)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.appAccent : Color.clear, lineWidth: 2)
                )
            
            Text(category.name)
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
        }
        .frame(width: 70)
    }
}
