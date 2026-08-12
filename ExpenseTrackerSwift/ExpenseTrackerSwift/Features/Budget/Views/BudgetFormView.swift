//
//  BudgetFormView.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import SwiftUI
import SwiftData

struct BudgetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.analyticsService) private var analyticsService
    @EnvironmentObject var currencyManager: SharedCurrencyService
    @ObservedObject var viewModel: BudgetViewModel

    @State private var name: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDeleteConfirmation = false
    
    let existingBudget: Budget?

    init(viewModel: BudgetViewModel, existingBudget: Budget? = nil) {
        self.viewModel = viewModel
        self.existingBudget = existingBudget

        if let budget = existingBudget {
            _name = State(initialValue: budget.name)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Budget Name", text: $name)
                        .accessibilityIdentifier("budget_name_field")
                        .overlay(alignment: .trailing) {
                            if name.trimmingCharacters(in: .whitespaces).isEmpty {
                                Text("Required")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.trailing, 8)
                            }
                        }
                } header: {
                    Text("Budget Details")
                }

                if existingBudget != nil {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label(String(localized: "Delete Budget"), systemImage: "trash")
                        }
                        .accessibilityIdentifier("budget_form_delete_button")
                    }
                }
            }
            .navigationTitle(existingBudget == nil ? "New Budget" : "Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("budget_cancel_button")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveBudget() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("budget_save_button")
                }
            }
            .alert(String(localized: "Delete Budget"), isPresented: $showingDeleteConfirmation) {
                Button(String(localized: "Delete"), role: .destructive) {
                    deleteBudget()
                }
                Button(String(localized: "Cancel"), role: .cancel) { }
            } message: {
                Text(String(localized: "Are you sure you want to delete this budget? All associated categories and transactions will be permanently deleted."))
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                analyticsService.trackScreen("Budget Form")
            }
        }
    }

    private func saveBudget() {
        do {
            if let existing = existingBudget {
                try viewModel.updateBudget(existing, name: name, totalAmount: existing.totalAmount)
                analyticsService.trackEvent("Budget Updated")
            } else {
                _ = try viewModel.createBudget(name: name, totalAmount: 0)
                analyticsService.trackEvent("Budget Created")
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func deleteBudget() {
        guard let budget = existingBudget else { return }
        do {
            try viewModel.deleteBudget(budget)
            analyticsService.trackEvent("Budget Deleted")
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Budget.self, configurations: config)
    let viewModel = BudgetViewModel(modelContext: container.mainContext)

    BudgetFormView(viewModel: viewModel)
}

