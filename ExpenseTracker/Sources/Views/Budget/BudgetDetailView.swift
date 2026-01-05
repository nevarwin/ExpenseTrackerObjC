//
//  BudgetDetailView.swift
//  ExpenseTracker
//
//  Created by raven on 8/26/25.
//

import SwiftUI
import CoreData

struct BudgetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    let budget: Budget?
    @StateObject private var viewModel: BudgetDetailViewModel
    @State private var budgetName: String = ""
    @State private var showCategoryForm = false
    @State private var selectedCategory: Category?
    @State private var isIncomeCategory = false
    @State private var showMonthPicker = false
    @State private var showYearPicker = false
    
    init(budget: Budget?, context: NSManagedObjectContext) {
        self.budget = budget
        let budgetToUse = budget ?? {
            let newBudget = NSEntityDescription.insertNewObject(forEntityName: "Budget", into: context) as! Budget
            newBudget.createdAt = Date()
            newBudget.isActive = true
            return newBudget
        }()
        _viewModel = StateObject(wrappedValue: BudgetDetailViewModel(budget: budgetToUse, context: context))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if viewModel.budget.objectID.isTemporaryID == false {
                    datePickerSection
                }
                
                budgetNameSection
                budgetInfoSection
                categoriesSection
            }
            .navigationTitle(viewModel.budget.objectID.isTemporaryID ? "Add Budget" : "Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.budget.objectID.isTemporaryID {
                            viewContext.delete(viewModel.budget)
                        }
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveBudget(name: budgetName)
                        dismiss()
                    }
                    .disabled(budgetName.isEmpty || viewModel.expenseCategories.isEmpty || viewModel.incomeCategories.isEmpty)
                }
            }
            .sheet(isPresented: $showCategoryForm) {
                CategoryFormView(
                    budget: viewModel.budget,
                    isIncome: isIncomeCategory,
                    context: viewContext
                )
                .onDisappear {
                    viewModel.fetchCategories()
                }
            }
            .sheet(item: $selectedCategory) { category in
                CategoryFormView(
                    budget: viewModel.budget,
                    isIncome: category.isIncome,
                    existingCategory: category,
                    context: viewContext
                )
                .onDisappear {
                    viewModel.fetchCategories()
                }
            }
            .sheet(isPresented: $showMonthPicker) {
                MonthPickerView(selectedMonth: viewModel.currentDateComponents.month ?? 1) { month in
                    viewModel.currentDateComponents.month = month
                    viewModel.fetchCategories()
                }
            }
            .sheet(isPresented: $showYearPicker) {
                YearPickerView(selectedYear: viewModel.currentDateComponents.year ?? 2025) { year in
                    viewModel.currentDateComponents.year = year
                    viewModel.fetchCategories()
                }
            }
            .onAppear {
                budgetName = viewModel.budget.name ?? ""
                viewModel.fetchCategories()
            }
        }
    }
    
    private var datePickerSection: some View {
        Section {
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
        }
    }
    
    private var budgetNameSection: some View {
        Section {
            TextField("Budget Name", text: $budgetName)
                .font(.system(size: 34, weight: .bold))
        }
    }
    
    private var budgetInfoSection: some View {
        Section {
            DisclosureGroup("BUDGET SUMMARY", isExpanded: $viewModel.isBudgetSectionExpanded) {
                HStack {
                    Text("Remaining Budget")
                    Spacer()
                    Text(CurrencyFormatter.format(viewModel.remainingBudget))
                }
                
                HStack {
                    Text("Total Used Budget")
                    Spacer()
                    Text(CurrencyFormatter.format(viewModel.totalUsedBudget))
                }
                
                HStack {
                    Text("Expenses")
                    Spacer()
                    Text(CurrencyFormatter.format(viewModel.totalExpenses))
                }
                
                HStack {
                    Text("Income")
                    Spacer()
                    Text(CurrencyFormatter.format(viewModel.totalIncome))
                }
            }
        }
    }
    
    private var categoriesSection: some View {
        Group {
            Section {
                HStack {
                    Text("EXPENSES - \(CurrencyFormatter.format(viewModel.totalExpenses))")
                    Spacer()
                    Button(action: {
                        isIncomeCategory = false
                        showCategoryForm = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ForEach(viewModel.expenseCategories, id: \.objectID) { category in
                    CategoryRow(category: category)
                        .onTapGesture {
                            selectedCategory = category
                        }
                }
                .onDelete { indexSet in
                    // Handle delete
                }
            }
            
            Section {
                HStack {
                    Text("INCOME - \(CurrencyFormatter.format(viewModel.totalIncome))")
                    Spacer()
                    Button(action: {
                        isIncomeCategory = true
                        showCategoryForm = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ForEach(viewModel.incomeCategories, id: \.objectID) { category in
                    CategoryRow(category: category)
                        .onTapGesture {
                            selectedCategory = category
                        }
                }
                .onDelete { indexSet in
                    // Handle delete
                }
            }
        }
    }
}

struct CategoryRow: View {
    let category: Category
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category.name ?? "Unknown")
                .font(.system(size: 18, weight: .bold))
            
            HStack {
                Text("Allocated: \(CurrencyFormatter.format(category.allocatedAmount ?? 0))")
                Text("Used: \(CurrencyFormatter.format(category.usedAmount ?? 0))")
            }
            .font(.system(size: 14))
            .foregroundColor(.secondary)
        }
    }
}

#Preview {
    BudgetDetailView(budget: nil, context: PersistenceController.preview.container.viewContext)
}

