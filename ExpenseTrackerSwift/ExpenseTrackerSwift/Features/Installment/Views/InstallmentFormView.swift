//
//  InstallmentFormView.swift
//  ExpenseTrackerSwift
//

import SwiftUI
import SwiftData

struct InstallmentFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: SharedCurrencyService
    
    let planToEdit: InstallmentPlan?
    
    @Query(sort: \Budget.startDate, order: .reverse) private var budgets: [Budget]
    
    @State private var name: String
    @State private var totalAmountString: String
    @State private var monthlyAmountString: String
    @State private var totalMonths: Int
    @State private var totalMonthsString: String
    @State private var startDate: Date
    @State private var selectedCategory: Category?
    @State private var notes: String
    @State private var errorMessage: String?
    
    private let presetMonths: [Int] = [3, 6, 12, 18, 24, 36, 48, 60]
    
    init(planToEdit: InstallmentPlan? = nil) {
        self.planToEdit = planToEdit
        
        if let plan = planToEdit {
            _name = State(initialValue: plan.name)
            _totalAmountString = State(initialValue: NSDecimalNumber(decimal: plan.totalAmount).stringValue)
            _monthlyAmountString = State(initialValue: NSDecimalNumber(decimal: plan.monthlyAmount).stringValue)
            _totalMonths = State(initialValue: plan.totalMonths)
            _totalMonthsString = State(initialValue: "\(plan.totalMonths)")
            _startDate = State(initialValue: plan.startDate)
            _selectedCategory = State(initialValue: plan.transactions.first?.category)
            _notes = State(initialValue: plan.notes)
        } else {
            _name = State(initialValue: "")
            _totalAmountString = State(initialValue: "")
            _monthlyAmountString = State(initialValue: "")
            _totalMonths = State(initialValue: 24)
            _totalMonthsString = State(initialValue: "24")
            let defaultStart = Calendar.current.date(byAdding: .month, value: -13, to: Date()) ?? Date()
            _startDate = State(initialValue: defaultStart)
            _selectedCategory = State(initialValue: nil)
            _notes = State(initialValue: "")
        }
    }
    
    private var activeBudget: Budget? {
        budgets.first
    }
    
    private var isEditing: Bool {
        planToEdit != nil
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
    
    private var remainingMonthsCount: Int {
        max(0, totalMonths - calculatedElapsedMonths)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Installment Plan Details")) {
                    TextField("Name (e.g. Laptop Purchase)", text: $name)
                    
                    HStack {
                        Text("Total Amount (\(currencyManager.currencyCode))")
                        Spacer()
                        TextField("2400.00", text: $totalAmountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: totalAmountString) { oldValue, newValue in
                                if monthlyAmountString.isEmpty || oldValue != newValue {
                                    recalculateMonthly()
                                }
                            }
                    }
                    
                    HStack {
                        Text("Monthly Payment (\(currencyManager.currencyCode))")
                        Spacer()
                        TextField("100.00", text: $monthlyAmountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Tenure / Duration")) {
                    // Quick-select preset chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(presetMonths, id: \.self) { months in
                                Button(action: {
                                    updateMonths(months)
                                }) {
                                    Text("\(months) mo")
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(totalMonths == months ? .bold : .medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(totalMonths == months ? Color.emeraldPrimary : Color.appLightGray)
                                        .foregroundStyle(totalMonths == months ? Color.white : Color.appPrimary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Stepper and direct numeric input
                    HStack {
                        Text("Custom Months")
                        Spacer()
                        
                        TextField("Months", text: $totalMonthsString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: totalMonthsString) { _, newValue in
                                if let parsed = Int(newValue), parsed > 0 {
                                    let clamped = min(max(1, parsed), 240)
                                    if totalMonths != clamped {
                                        totalMonths = clamped
                                        recalculateMonthly()
                                    }
                                }
                            }
                        
                        Stepper("", value: Binding(
                            get: { totalMonths },
                            set: { newVal in
                                updateMonths(newVal)
                            }
                        ), in: 1...240)
                        .labelsHidden()
                    }
                }
                
                Section(header: Text("Timeline & Schedule")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                    
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(Color.emeraldPrimary)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(calculatedElapsedMonths) of \(totalMonths) months elapsed")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.appPrimary)
                            
                            if isEditing {
                                Text("\(remainingMonthsCount) months remaining.")
                                    .font(.caption)
                                    .foregroundStyle(Color.appSecondary)
                            } else {
                                Text("Will generate \(calculatedElapsedMonths) past/current records starting \(startDate.formatted(date: .abbreviated, time: .omitted)).")
                                    .font(.caption)
                                    .foregroundStyle(Color.appSecondary)
                            }
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
            .navigationTitle(isEditing ? "Edit Installment Plan" : "New Installment Plan")
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
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || totalAmountString.isEmpty || totalMonths < 1)
                }
            }
            .onAppear {
                if selectedCategory == nil, let firstCategory = activeBudget?.categories.first(where: { !$0.isIncome }) {
                    selectedCategory = firstCategory
                }
            }
        }
    }
    
    private func updateMonths(_ months: Int) {
        let clamped = max(1, min(240, months))
        totalMonths = clamped
        totalMonthsString = "\(clamped)"
        recalculateMonthly()
    }
    
    private func recalculateMonthly() {
        let monthly = calculatedMonthly
        if monthly > 0 {
            monthlyAmountString = NSDecimalNumber(decimal: monthly).stringValue
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
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        
        let service = InstallmentService(modelContext: modelContext)
        do {
            if let existingPlan = planToEdit {
                try service.updateInstallmentPlan(
                    existingPlan,
                    name: trimmedName,
                    totalAmount: total,
                    monthlyAmount: monthly,
                    startDate: startDate,
                    totalMonths: totalMonths,
                    category: category,
                    notes: notes
                )
            } else {
                try service.createInstallmentPlan(
                    name: trimmedName,
                    totalAmount: total,
                    monthlyAmount: monthly,
                    startDate: startDate,
                    totalMonths: totalMonths,
                    category: category,
                    budget: budget,
                    notes: notes
                )
            }
            dismiss()
        } catch {
            errorMessage = "Failed to save installment: \(error.localizedDescription)"
        }
    }
}

#Preview {
    InstallmentFormView()
        .environmentObject(SharedCurrencyService())
}
