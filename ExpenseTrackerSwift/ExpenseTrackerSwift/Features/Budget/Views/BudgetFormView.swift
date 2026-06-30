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
    @EnvironmentObject var currencyManager: CurrencyManager
    @ObservedObject var viewModel: BudgetViewModel

    @State private var name: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
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
                            deleteBudget()
                        } label: {
                            Label("Delete Budget", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(existingBudget == nil ? "New Budget" : "Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveBudget() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                PostHogManager.shared.trackScreen("Budget Form")
            }
        }
    }

    private func saveBudget() {
        do {
            if let existing = existingBudget {
                try viewModel.updateBudget(existing, name: name, totalAmount: existing.totalAmount)
                PostHogManager.shared.trackEvent("Budget Updated")
            } else {
                _ = try viewModel.createBudget(name: name, totalAmount: 0)
                PostHogManager.shared.trackEvent("Budget Created")
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
            PostHogManager.shared.trackEvent("Budget Deleted")
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

