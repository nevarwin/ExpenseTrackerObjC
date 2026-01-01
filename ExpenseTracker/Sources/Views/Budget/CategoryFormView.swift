//
//  CategoryFormView.swift
//  ExpenseTracker
//
//  Created by raven on 10/13/25.
//

import SwiftUI
import CoreData

struct CategoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    let budget: Budget
    let isIncome: Bool
    let existingCategory: Category?
    @StateObject private var viewModel: CategoryFormViewModel
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(budget: Budget, isIncome: Bool, existingCategory: Category? = nil, context: NSManagedObjectContext) {
        self.budget = budget
        self.isIncome = isIncome
        self.existingCategory = existingCategory
        _viewModel = StateObject(wrappedValue: CategoryFormViewModel(
            context: context,
            budget: budget,
            isIncome: isIncome,
            existingCategory: existingCategory
        ))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Category Name", text: $viewModel.name)
                        .font(.system(size: 20, weight: .bold))
                }
                
                Section {
                    TextField("Amount", text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                        .monospacedDigit()
                        .onChange(of: viewModel.amount) { _ in
                            viewModel.computeMonthlyAmount()
                        }
                    
                    Toggle("Pay in Installments", isOn: $viewModel.isInstallment)
                        .onChange(of: viewModel.isInstallment) { _ in
                            viewModel.computeMonthlyAmount()
                        }
                    
                    if viewModel.isInstallment {
                        DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: [.date])
                        
                        TextField("Months", text: $viewModel.months)
                            .keyboardType(.numberPad)
                            .onChange(of: viewModel.months) { _ in
                                viewModel.computeMonthlyAmount()
                            }
                        
                        TextField("Monthly Payment", text: $viewModel.monthlyPayment)
                            .keyboardType(.decimalPad)
                            .monospacedDigit()
                            .disabled(true)
                    }
                }
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isEditMode ? "Update" : "Add") {
                        saveCategory()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveCategory() {
        do {
            try viewModel.saveCategory()
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let budget = Budget(context: context)
    budget.name = "Sample Budget"
    return CategoryFormView(budget: budget, isIncome: false, context: context)
}

