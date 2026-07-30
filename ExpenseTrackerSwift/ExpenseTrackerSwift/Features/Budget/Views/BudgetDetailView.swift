//
//  BudgetDetailView.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BudgetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: SharedCurrencyService
    let budget: Budget
    private let budgetModel: BudgetModel
    var viewModel: BudgetViewModel?
    
    init(budget: Budget, viewModel: BudgetViewModel? = nil) {
        self.budget = budget
        self.viewModel = viewModel
        self.budgetModel = BudgetModel(budgetModel: budget)
    }
    
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    
    // Add Month States
    @State private var showingAddMonthPicker = false
    @State private var pickerMonth = Calendar.current.component(.month, from: Date())
    @State private var pickerYear = Calendar.current.component(.year, from: Date())
    
    // Import States (Transactions)
    @State private var isImportingTransactions = false
    @State private var showingImportInstruction = false
    
    // Import States (Budget Template)
    @State private var isImportingBudget = false
    @State private var showingImportBudgetInstruction = false
    
    // Import Result States
    @State private var importMessage: String?
    @State private var showingImportAlert = false
    @State private var importErrorMessage: String?
    @State private var showingImportError = false

    var body: some View {
        List {
            // Add Month section
            Section {
                Button(action: { showingAddMonthPicker = true }) {
                    Label("Add Month", systemImage: "calendar.badge.plus")
                        .fontWeight(.medium)
                        .foregroundStyle(Color.appAccent)
                }
            }
            
            // List of months
            Section("Budget Periods") {
                let periods = budgetModel.activeBudgetPeriods()
                if periods.isEmpty {
                    Text("No active budget months. Tap 'Add Month' or import templates to initialize.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(periods.reversed(), id: \.self) { month in
                        NavigationLink(destination: MonthlyBudgetDetailView(budget: budget, month: month, budgetViewModel: viewModel, budgetModel: budgetModel)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(month.monthYearString)
                                        .font(.headline)
                                    
                                    // Small summary of spent vs planned
                                    let planned = budgetModel.plannedExpenses(date: month)
                                    let spent = budgetModel.expensesInMonth(date: month)
                                    Text("Spent: \(spent.formatted(.currency(code: currencyManager.currencyCode))) / Planned: \(planned.formatted(.currency(code: currencyManager.currencyCode)))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                
                                // Progress pill
                                let remaining = budgetModel.remainingInMonth(date: month)
                                Text(remaining >= 0 ? "Under" : "Over")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(remaining >= 0 ? Color.green : Color.red)
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle(budget.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Budget", systemImage: "trash")
                    }
                    
                    Divider()
                    
                    Button {
                        showingEditSheet = true
                        SharedAnalyticsService.instance.trackEvent("Budget Edit Clicked (Detail)")
                    } label: {
                        Label("Edit Budget", systemImage: "pencil")
                    }
                    
                    Divider()

                    Button {
                        showingImportBudgetInstruction = true
                        SharedAnalyticsService.instance.trackEvent("Budget Import Clicked")
                    } label: {
                        Label("Import Budget Templates", systemImage: "folder.badge.plus")
                    }
                    
                    Button {
                        showingImportInstruction = true
                        SharedAnalyticsService.instance.trackEvent("Transaction Import Clicked")
                    } label: {
                        Label("Import Transactions", systemImage: "square.and.arrow.down")
                    }
                    
                    Divider()

                    NavigationLink {
                        BudgetHistoryView(budget: budget)
                    } label: {
                        Label("View History", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            BudgetFormView(
                viewModel: viewModel ?? BudgetViewModel(modelContext: modelContext),
                existingBudget: budget
            )
        }
        .sheet(isPresented: $showingAddMonthPicker) {
            VStack(spacing: 20) {
                Text("Choose Month & Year")
                    .font(.headline)
                    .padding(.top)
                
                HStack(spacing: 0) {
                    Picker("Month", selection: $pickerMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(Calendar.current.monthSymbols[month - 1]).tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 150)
                    
                    Picker("Year", selection: $pickerYear) {
                        let currentYear = Calendar.current.component(.year, from: Date())
                        ForEach((currentYear - 5)...(currentYear + 5), id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                }
                
                Button("Initialize Month") {
                    var components = DateComponents()
                    components.year = pickerYear
                    components.month = pickerMonth
                    if let selectedDate = Calendar.current.date(from: components) {
                        if let vm = viewModel {
                            try? vm.addBudgetPeriod(for: budget, month: selectedDate)
                        } else {
                            let vm = BudgetViewModel(modelContext: modelContext)
                            try? vm.addBudgetPeriod(for: budget, month: selectedDate)
                        }
                    }
                    showingAddMonthPicker = false
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .presentationDetents([.height(300)])
            .onAppear {
                pickerMonth = Calendar.current.component(.month, from: Date())
                pickerYear = Calendar.current.component(.year, from: Date())
            }
        }
        .alert("Import Transactions", isPresented: $showingImportInstruction) {
            Button("Continue") {
                isImportingTransactions = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Select one or more CSV files. The budget period for each file will be auto-detected from its filename (e.g., 'Dec25.csv')")
        }
        .alert("Import Budget Templates", isPresented: $showingImportBudgetInstruction) {
            Button("Continue") {
                isImportingBudget = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Select one or more CSV files containing category allocations. The month period will be auto-detected from the filename (e.g. 'Jun26.csv').")
        }
        .fileImporter(
            isPresented: $isImportingTransactions,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: true
        ) { result in
            handleTransactionFilePicked(result)
        }
        .fileImporter(
            isPresented: $isImportingBudget,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: true
        ) { result in
            handleBudgetFilePicked(result)
        }
        .alert("Import Success", isPresented: $showingImportAlert) {
            Button("OK") { }
        } message: {
            Text(importMessage ?? "Import complete")
        }
        .alert("Import Failed", isPresented: $showingImportError) {
            Button("OK") { }
        } message: {
            Text(importErrorMessage ?? "Unknown error")
        }
        .confirmationDialog("Delete Budget", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteBudget()
                SharedAnalyticsService.instance.trackEvent("Budget Delete Confirmed (Detail)", properties: ["budget_name": budget.name])
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this budget? All associated categories and transactions will be permanently deleted.")
        }
    }
    
    private func deleteBudget() {
        if let vm = viewModel {
            try? vm.deleteBudget(budget)
        } else {
            modelContext.delete(budget)
            try? modelContext.save()
        }
        dismiss()
    }
    
    private func handleTransactionFilePicked(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else { return }
            
            var processedFiles: [(String, [CSVTransaction])] = []
            var tempFileURLs: [URL] = []
            let parser = CSVParser.shared
            
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                do {
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    tempFileURLs.append(tempURL)
                    
                    let transactions = try parser.parseTransactions(from: tempURL)
                    processedFiles.append((url.lastPathComponent, transactions))
                    
                } catch {
                    print("Error preparing/parsing file \(url.lastPathComponent): \(error)")
                }
                
                url.stopAccessingSecurityScopedResource()
            }
            
            guard !processedFiles.isEmpty else {
                importErrorMessage = "Failed to parse any selected files."
                showingImportError = true
                return
            }
            
            do {
                let importManager = ImportManager(modelContext: modelContext)
                let totalCount = try importManager.importBatchTransactions(files: processedFiles, into: budget)
                
                if totalCount > 0 {
                    importMessage = "Successfully imported \(totalCount) transactions from \(processedFiles.count) file(s)."
                } else {
                    importMessage = "No new transactions were imported. They might be duplicates."
                }
                showingImportAlert = true
                SharedAnalyticsService.instance.trackEvent("Transaction Import Success", properties: [
                    "imported_count": totalCount,
                    "file_count": processedFiles.count
                ])
                
            } catch {
                importErrorMessage = "Import failed: \(error.localizedDescription)"
                showingImportError = true
                SharedAnalyticsService.instance.trackEvent("Transaction Import Failed", properties: ["error": error.localizedDescription])
            }
            
            for tempURL in tempFileURLs {
                try? FileManager.default.removeItem(at: tempURL)
            }
            
        case .failure(let error):
            importErrorMessage = error.localizedDescription
            showingImportError = true
        }
    }
    
    private func handleBudgetFilePicked(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else { return }
            
            var processedBudgets: [CSVBudget] = []
            var tempFileURLs: [URL] = []
            let parser = CSVParser.shared
            
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                do {
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    tempFileURLs.append(tempURL)
                    
                    let csvBudget = try parser.parseBudget(from: tempURL)
                    processedBudgets.append(csvBudget)
                    
                } catch {
                    print("Error preparing/parsing file \(url.lastPathComponent): \(error)")
                }
                
                url.stopAccessingSecurityScopedResource()
            }
            
            guard !processedBudgets.isEmpty else {
                importErrorMessage = "Failed to parse any selected budget template files."
                showingImportError = true
                return
            }
            
            do {
                let importManager = ImportManager(modelContext: modelContext)
                var count = 0
                for csvBudget in processedBudgets {
                    _ = try importManager.importBudget(from: csvBudget)
                    count += csvBudget.items.count
                }
                
                importMessage = "Successfully imported \(count) category allocation(s)."
                showingImportAlert = true
                SharedAnalyticsService.instance.trackEvent("Budget Template Import Success", properties: [
                    "imported_categories": count,
                    "file_count": processedBudgets.count
                ])
                
            } catch {
                importErrorMessage = "Import failed: \(error.localizedDescription)"
                showingImportError = true
                SharedAnalyticsService.instance.trackEvent("Budget Template Import Failed", properties: ["error": error.localizedDescription])
            }
            
            for tempURL in tempFileURLs {
                try? FileManager.default.removeItem(at: tempURL)
            }
            
        case .failure(let error):
            importErrorMessage = error.localizedDescription
            showingImportError = true
        }
    }
}
