//
//  ImportView.swift
//  ExpenseTrackerSwift
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    let targetBudget: Budget?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: ImportViewModel?
    @State private var showingFileImporter = false
    @State private var selectedImportType: ImportType
    
    init(targetBudget: Budget? = nil, initialImportType: ImportType = .fullWorkbook) {
        self.targetBudget = targetBudget
        _selectedImportType = State(initialValue: initialImportType)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header / Import Type Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Import Type")
                            .font(.headline)
                            .foregroundStyle(Color.appSecondary)
                        
                        Picker("Import Type", selection: $selectedImportType) {
                            ForEach(ImportType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)
                    
                    // Description Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: selectedImportType.iconName)
                                .font(.title2)
                                .foregroundStyle(Color.appPrimary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedImportType.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                Text(selectedImportType.description)
                                    .font(.caption)
                                    .foregroundStyle(Color.appSecondary)
                            }
                        }
                        
                        if selectedImportType == .transactions, let budget = targetBudget {
                            Divider()
                                .padding(.vertical, 4)
                            
                            HStack {
                                Text("Target Budget:")
                                    .font(.caption)
                                    .foregroundStyle(Color.appSecondary)
                                Text(budget.name)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.appPrimary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    // Excel Installment Formatting Tip Card
                    if selectedImportType == .fullWorkbook {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(Color.orange)
                                Text("Excel Template Tip")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            Text("To automatically track an expense as an installment, prefix the category name in your Excel Expenses table with **Installment:** (e.g., **Installment: Midea Aircon**). The app will automatically create and link an installment plan for it upon import.")
                                .font(.caption)
                                .foregroundStyle(Color.appSecondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    
                    // Import Trigger Card
                    VStack(spacing: 16) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.appPrimary)
                        
                        Text("Select CSV File(s)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Supports formatted CSV files exported from bank or budget templates.")
                            .font(.caption)
                            .foregroundStyle(Color.appSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            showingFileImporter = true
                        } label: {
                            HStack {
                                Image(systemName: "folder.fill")
                                Text("Browse Files")
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appPrimary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.horizontal)
                        .disabled(viewModel?.isImporting ?? false)
                    }
                    .padding(.vertical, 24)
                    .background(Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Status Banners (for standalone errors if any)
                    if let vm = viewModel, !vm.isImporting {
                        if let error = vm.errorMessage, vm.currentProgress == nil {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Error")
                                    .font(.headline)
                                    .foregroundStyle(Color.red)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.appSecondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(viewModel?.isImporting ?? false)
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: selectedImportType == .fullWorkbook
                    ? [UTType(filenameExtension: "xlsx") ?? UTType("org.openxmlformats.spreadsheetml.sheet") ?? .data]
                    : [.commaSeparatedText, .plainText],
                allowsMultipleSelection: selectedImportType != .fullWorkbook
            ) { result in
                handleFilePicked(result)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ImportViewModel(modelContext: modelContext)
                }
            }
            .overlay {
                if let vm = viewModel, vm.isImporting, let progress = vm.currentProgress {
                    ImportLoadingView(
                        importType: selectedImportType,
                        progress: progress,
                        result: vm.importResult,
                        onCancel: {
                            vm.cancelImport()
                        },
                        onDone: {
                            vm.dismissLoading()
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel?.isImporting)
        }
    }
    
    private func handleFilePicked(_ result: Result<[URL], Error>) {
        guard let vm = viewModel else { return }
        
        switch result {
        case .success(let urls):
            if selectedImportType == .fullWorkbook {
                if let url = urls.first {
                    vm.importWorkbookFile(url: url)
                }
            } else if selectedImportType == .transactions {
                if let budget = targetBudget {
                    vm.importTransactionFiles(urls: urls, into: budget)
                } else {
                    vm.errorMessage = "No budget target selected for transaction import."
                }
            } else {
                vm.importBudgetFiles(urls: urls)
            }
        case .failure(let error):
            vm.errorMessage = "File selection error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ImportView()
}
