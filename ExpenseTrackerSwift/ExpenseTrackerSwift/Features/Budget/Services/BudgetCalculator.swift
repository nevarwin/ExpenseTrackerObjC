//  
//  BudgetCalculator.swift
//  ExpenseTrackerSwift
//

import Foundation

@MainActor
protocol BudgetCalculatorProtocol: AnyObject {
    func activeBudgetPeriods() -> [Date]
    func transactionsInMonth(date: Date) -> [Transaction]
    func categoriesInMonth(date: Date) -> [Category]
    func expensesInMonth(date: Date) -> Decimal
    func incomeInMonth(date: Date) -> Decimal
    func remainingInMonth(date: Date) -> Decimal
    func plannedExpenses(date: Date) -> Decimal
    func plannedIncome(date: Date) -> Decimal
    func expenseDiffInMonth(date: Date) -> Decimal
    func incomeDiffInMonth(date: Date) -> Decimal
    func updateRemainingAmount()
}

@MainActor
final class BudgetCalculator: BudgetCalculatorProtocol {
    let budget: Budget
    
    init(budget: Budget) {
        self.budget = budget
    }
}

extension BudgetCalculator {
    
    private var transactions: [Transaction] {
        budget.transactions
    }
    
    private var categories: [Category] {
        budget.categories
    }

    func activeBudgetPeriods() -> [Date] {
        let transactionPeriods = transactions.compactMap { $0.isActive ? $0.budgetPeriod : nil }
        let categoryPeriods = categories.compactMap { $0.isActive ? $0.budgetPeriod : nil }
        let periods = Set(transactionPeriods + categoryPeriods)
        return periods.sorted()
    }
    
    func transactionsInMonth(date: Date) -> [Transaction] {
        let bounds = date.monthBounds
        return transactions.filter { transaction in
            transaction.isActive &&
            transaction.budgetPeriod.isSameMonth(as: bounds.start)
        }
    }
    
    func expensesInMonth(date: Date) -> Decimal {
        transactionsInMonth(date: date)
            .filter { !($0.category?.isIncome ?? false) }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    func incomeInMonth(date: Date) -> Decimal {
        transactionsInMonth(date: date)
            .filter { $0.category?.isIncome ?? false }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    func remainingInMonth(date: Date) -> Decimal {
        incomeInMonth(date: date) - expensesInMonth(date: date)
    }
    
    func categoriesInMonth(date: Date) -> [Category] {
        let bounds = date.monthBounds
        return categories.filter { category in
            category.isActive &&
            category.budgetPeriod.isSameMonth(as: bounds.start)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    
    func plannedExpenses(date: Date) -> Decimal {
        categoriesInMonth(date: date)
            .filter { !$0.isIncome }
            .reduce(Decimal.zero) { $0 + $1.allocatedAmount }
    }
    
    func plannedIncome(date: Date) -> Decimal {
        categoriesInMonth(date: date)
            .filter { $0.isIncome }
            .reduce(Decimal.zero) { $0 + $1.allocatedAmount }
    }
    
    func expenseDiffInMonth(date: Date) -> Decimal {
        plannedExpenses(date: date) - expensesInMonth(date: date)
    }
    
    func incomeDiffInMonth(date: Date) -> Decimal {
        incomeInMonth(date: date) - plannedIncome(date: date)
    }
    
    func updateRemainingAmount() {
        let totalExpenses = transactions
            .filter { !($0.category?.isIncome ?? false) && $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let totalIncome = transactions
            .filter { ($0.category?.isIncome ?? false) && $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.amount }
            
        budget.remainingAmount = totalIncome - totalExpenses
        budget.updatedAt = Date()
    }
}
