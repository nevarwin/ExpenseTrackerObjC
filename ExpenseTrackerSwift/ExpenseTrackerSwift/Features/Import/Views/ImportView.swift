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
    @State private var selectedImportType: ImportType = .transactions
    
    init(targetBudget: Budget? = nil) {
        self.targetBudget = targetBudget
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
                    
                    // Status Banners
                    if let vm = viewModel {
                        if vm.isImporting {
                            ProgressView("Processing files...")
                                .padding()
                        }
                        
                        if let result = vm.importResult {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundStyle(result.success ? Color.green : Color.red)
                                    Text(result.success ? "Import Complete" : "Import Failed")
                                        .font(.headline)
                                }
                                
                                Text(result.message)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.appSecondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        } else if let error = vm.errorMessage {
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
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: true
            ) { result in
                handleFilePicked(result)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ImportViewModel(modelContext: modelContext)
                }
            }
        }
    }
    
    private func handleFilePicked(_ result: Result<[URL], Error>) {
        guard let vm = viewModel else { return }
        
        switch result {
        case .success(let urls):
            if selectedImportType == .transactions {
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
