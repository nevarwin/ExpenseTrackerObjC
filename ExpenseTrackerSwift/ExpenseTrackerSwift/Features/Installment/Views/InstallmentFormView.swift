//
//  InstallmentFormView.swift
//  ExpenseTrackerSwift
//

import SwiftUI
import SwiftData

struct InstallmentFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Budget.startDate, order: .reverse) private var budgets: [Budget]
    
    @State private var name: String = ""
    @State private var totalAmountString: String = ""
    @State private var monthlyAmountString: String = ""
    @State private var totalMonths: Int = 24
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -13, to: Date()) ?? Date()
    @State private var selectedCategory: Category?
    @State private var notes: String = ""
    @State private var errorMessage: String?
    
    private var activeBudget: Budget? {
        budgets.first
    }
    
    private var calculatedMonthly: Decimal {
        guard let total = Decimal(string: totalAmountString), totalMonths > 0 else { return 0 }
        return total / Decimal(totalMonths)
    }
    
    private var calculatedElapsedMonths: Int {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month], from: startDate)
        let nowComponents = calendar.dateComponents([.year, .month], from: Date())
        
        let yearDiff = (nowComponents.year ?? 0) - (startComponents.year ?? 0)
        let monthDiff = (nowComponents.month ?? 0) - (startComponents.month ?? 0)
        let months = yearDiff * 12 + monthDiff + 1
        return max(1, min(totalMonths, months))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Installment Plan Details")) {
                    TextField("Name (e.g. Laptop Purchase)", text: $name)
                    
                    HStack {
                        Text("Total Amount ($)")
                        Spacer()
                        TextField("2400.00", text: $totalAmountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: totalAmountString) { oldValue, newValue in
                                if monthlyAmountString.isEmpty || oldValue != newValue {
                                    let monthly = calculatedMonthly
                                    if monthly > 0 {
                                        monthlyAmountString = NSDecimalNumber(decimal: monthly).stringValue
                                    }
                                }
                            }
                    }
                    
                    HStack {
                        Text("Monthly Payment ($)")
                        Spacer()
                        TextField("100.00", text: $monthlyAmountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Stepper("Tenure: \(totalMonths) Months", value: $totalMonths, in: 2...120)
                }
                
                Section(header: Text("Timeline & Schedule")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                    
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(calculatedElapsedMonths) of \(totalMonths) months elapsed")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Will generate \(calculatedElapsedMonths) past/current monthly records starting \(startDate.formatted(date: .abbreviated, time: .omitted)).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
                
                if let budget = activeBudget {
                    Section(header: Text("Expense Category")) {
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select Category").tag(Category?.none)
                            ForEach(budget.sortedCategories.filter { !$0.isIncome }) { category in
                                Text(category.name).tag(Category?.some(category))
                            }
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextField("Optional notes or reference #", text: $notes)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Installment Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveInstallmentPlan()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || totalAmountString.isEmpty)
                }
            }
            .onAppear {
                if selectedCategory == nil, let firstCategory = activeBudget?.categories.first(where: { !$0.isIncome }) {
                    selectedCategory = firstCategory
                }
            }
        }
    }
    
    private func saveInstallmentPlan() {
        guard let budget = activeBudget else {
            errorMessage = "No active budget found."
            return
        }
        guard let category = selectedCategory else {
            errorMessage = "Please select a category."
            return
        }
        guard let total = Decimal(string: totalAmountString), total > 0 else {
            errorMessage = "Please enter a valid total amount."
            return
        }
        let monthly = Decimal(string: monthlyAmountString) ?? (total / Decimal(totalMonths))
        
        let service = InstallmentService(modelContext: modelContext)
        do {
            try service.createInstallmentPlan(
                name: name.trimmingCharacters(in: .whitespaces),
                totalAmount: total,
                monthlyAmount: monthly,
                startDate: startDate,
                totalMonths: totalMonths,
                category: category,
                budget: budget,
                notes: notes
            )
            dismiss()
        } catch {
            errorMessage = "Failed to save installment: \(error.localizedDescription)"
        }
    }
}
