//
//  InstallmentService.swift
//  ExpenseTrackerSwift
//

import Foundation
import SwiftData

final class InstallmentService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Creates a new InstallmentPlan and auto-populates transaction rows for past and current elapsed months.
    @discardableResult
    func createInstallmentPlan(
        name: String,
        totalAmount: Decimal,
        monthlyAmount: Decimal,
        startDate: Date,
        totalMonths: Int = 24,
        category: Category,
        budget: Budget,
        notes: String = ""
    ) throws -> InstallmentPlan {
        let plan = InstallmentPlan(
            name: name,
            totalAmount: totalAmount,
            monthlyAmount: monthlyAmount,
            startDate: startDate,
            totalMonths: totalMonths,
            notes: notes
        )
        modelContext.insert(plan)
        
        // Populate transaction rows for elapsed months up to current month
        let calendar = Calendar.current
        let elapsedCount = plan.elapsedMonths()
        
        for index in 1...elapsedCount {
            if let dateForMonth = calendar.date(byAdding: .month, value: index - 1, to: startDate) {
                let periodStart = dateForMonth.monthBounds.start
                
                let transaction = Transaction(
                    amount: monthlyAmount,
                    description: name,
                    date: dateForMonth,
                    budget: budget,
                    category: category,
                    budgetPeriod: periodStart,
                    installmentPlan: plan,
                    installmentIndex: index,
                    installmentTotalMonths: totalMonths
                )
                modelContext.insert(transaction)
                plan.transactions.append(transaction)
                
                category.usedAmount += monthlyAmount
                category.updatedAt = Date()
            }
        }
        
        try modelContext.save()
        return plan
    }
    
    /// Pays off an active installment plan early by creating a final settlement transaction for the remaining balance.
    func payOffEarly(plan: InstallmentPlan, in budget: Budget, category: Category) throws {
        guard plan.remainingBalance > 0 else { return }
        
        let remainingBalance = plan.remainingBalance
        let currentIndex = plan.elapsedMonths() + 1
        let now = Date()
        
        let finalTx = Transaction(
            amount: remainingBalance,
            description: "\(plan.name) (Early Payoff)",
            date: now,
            budget: budget,
            category: category,
            budgetPeriod: now.monthBounds.start,
            installmentPlan: plan,
            installmentIndex: currentIndex,
            installmentTotalMonths: plan.totalMonths
        )
        modelContext.insert(finalTx)
        plan.transactions.append(finalTx)
        
        category.usedAmount += remainingBalance
        category.updatedAt = Date()
        plan.updatedAt = Date()
        
        try modelContext.save()
    }
    
    /// Updates an existing InstallmentPlan's properties and cascades tenure / totalMonths changes to linked transactions.
    func updateInstallmentPlan(
        _ plan: InstallmentPlan,
        name: String,
        totalAmount: Decimal,
        monthlyAmount: Decimal,
        startDate: Date,
        totalMonths: Int,
        category: Category? = nil,
        notes: String = ""
    ) throws {
        let oldName = plan.name
        let safeTotalMonths = max(1, totalMonths)
        
        plan.name = name
        plan.totalAmount = totalAmount
        plan.monthlyAmount = monthlyAmount
        plan.startDate = startDate
        plan.totalMonths = safeTotalMonths
        plan.notes = notes
        plan.updatedAt = Date()
        
        for tx in plan.transactions {
            tx.installmentTotalMonths = safeTotalMonths
            if tx.desc == oldName {
                tx.desc = name
            }
            if let newCategory = category, let currentCat = tx.category, currentCat.id != newCategory.id {
                currentCat.usedAmount = max(0, currentCat.usedAmount - tx.amount)
                currentCat.updatedAt = Date()
                tx.category = newCategory
                newCategory.usedAmount += tx.amount
                newCategory.updatedAt = Date()
            }
            tx.updatedAt = Date()
        }
        
        try modelContext.save()
    }
    
    /// Deletes an installment plan and its associated transactions.
    func deleteInstallmentPlan(_ plan: InstallmentPlan) throws {
        for tx in plan.transactions {
            if let cat = tx.category {
                cat.usedAmount = max(0, cat.usedAmount - tx.amount)
            }
            modelContext.delete(tx)
        }
        modelContext.delete(plan)
        try modelContext.save()
    }
}
