//
//  TransactionFormView.swift
//  ExpenseTracker
//
//  Created by raven on 6/27/25.
//

import SwiftUI
import CoreData

struct TransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: TransactionFormViewModel
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showAmountExceededAlert = false
    
    init(existingTransaction: Transaction? = nil, context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: TransactionFormViewModel(context: context, existingTransaction: existingTransaction))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("Enter amount", text: $viewModel.amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                    }
                    
                    HStack {
                        Text("Description")
                        Spacer()
                        TextField("Enter description", text: $viewModel.description)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    Picker("Budget", selection: $viewModel.selectedBudgetID) {
                        Text("Select Budget").tag(nil as NSManagedObjectID?)
                        ForEach(viewModel.budgets, id: \.objectID) { budget in
                            Text(budget.name ?? "Unknown").tag(budget.objectID as NSManagedObjectID?)
                        }
                    }
                    .onChange(of: viewModel.selectedBudgetID) { _ in
                        viewModel.fetchCategories()
                    }
                    
                    Picker("Type", selection: $viewModel.selectedTypeIndex) {
                        Text("Select Type").tag(3)
                        Text("Expense").tag(0)
                        Text("Income").tag(1)
                    }
                    .disabled(viewModel.selectedBudgetID == nil)
                    .onChange(of: viewModel.selectedTypeIndex) { _ in
                        if viewModel.selectedTypeIndex != 3 {
                            viewModel.fetchCategories()
                        }
                    }
                    
                    Picker("Category", selection: $viewModel.selectedCategoryID) {
                        Text("Select Category").tag(nil as NSManagedObjectID?)
                        ForEach(viewModel.categories, id: \.objectID) { category in
                            Text(category.name ?? "Unknown").tag(category.objectID as NSManagedObjectID?)
                        }
                    }
                    .disabled(viewModel.selectedTypeIndex == 3 || viewModel.selectedBudgetID == nil)
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Edit Transaction" : "Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isEditMode ? "Update" : "Add") {
                        saveTransaction()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Amount Exceeded", isPresented: $showAmountExceededAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Save Anyway") {
                    saveTransaction(ignoreExceeded: true)
                }
            } message: {
                Text("The amount exceeds the budget allocated, but the transaction will still be saved.")
            }
        }
    }
    
    private func saveTransaction(ignoreExceeded: Bool = false) {
        do {
            try viewModel.saveTransaction(ignoreExceeded: ignoreExceeded)
            dismiss()
        } catch TransactionFormViewModel.TransactionFormError.amountExceeded {
            if !ignoreExceeded {
                showAmountExceededAlert = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    TransactionFormView(context: PersistenceController.preview.container.viewContext)
}

