//  
//  BudgetModel.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import Foundation

@MainActor
protocol BudgetModelProtocol: AnyObject {
    func activeBudgetPeriods() -> [Date]
    func transactionsInMonth(date: Date) -> [Transaction]
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
final class BudgetModel: BudgetModelProtocol {
    let budgetModel: Budget
    
    init(budgetModel: Budget) {
        self.budgetModel = budgetModel
    }
}

extension BudgetModel {
    
    private var transactions: [Transaction] {
        budgetModel.transactions
    }
    
    private var categories: [Category] {
        budgetModel.categories
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
    
    func plannedExpenses(date: Date) -> Decimal {
        categories
            .filter { !$0.isIncome && $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.allocatedAmount }
    }
    
    func plannedIncome(date: Date) -> Decimal {
        categories
            .filter { $0.isIncome && $0.isActive }
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
            
        budgetModel.remainingAmount = totalIncome - totalExpenses
        budgetModel.updatedAt = Date()
    }
    
}
