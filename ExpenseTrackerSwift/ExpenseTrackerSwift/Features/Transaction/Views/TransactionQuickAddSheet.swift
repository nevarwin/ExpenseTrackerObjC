import SwiftUI
import SwiftData

struct TransactionQuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: TransactionViewModel
    
    let activeBudgets: [Budget]
    let initialBudget: Budget
    
    @State private var amount: String = ""
    @State private var description: String = "" // Added description field
    @State private var isIncome: Bool = false
    @State private var selectedCategory: Category?
    @State private var showFullForm: Bool = false
    
    @FocusState private var isAmountFocused: Bool // For auto-focus
    
    @State private var lastAutoFilledDescription: String = "" // Track last auto-fill
    
    // Defaulting to today and the corresponding budget period
    @State private var date: Date
    @State private var selectedBudgetPeriod: Date
    
    @State private var showingOverflowAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    init(viewModel: TransactionViewModel, activeBudgets: [Budget], initialBudget: Budget) {
        self.viewModel = viewModel
        self.activeBudgets = activeBudgets
        self.initialBudget = initialBudget
        
        let initialDate = viewModel.selectedDate
        _date = State(initialValue: initialDate)
        let monthBounds = initialDate.monthBounds
        _selectedBudgetPeriod = State(initialValue: monthBounds.start)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if showFullForm {
                    TransactionFormView(
                        activeBudgets: activeBudgets,
                        initialBudget: initialBudget,
                        viewModel: viewModel
                    )
                } else {
                    VStack(spacing: 12) {
                        amountDescriptionRow
                        quickAmountChips
                        
                        VStack(spacing: 12) {
                            categorySelectionSection
                            typeAndSaveRow
                        }
                        
                        Button {
                            showFullForm = true
                        } label: {
                            Text("Expand for more details")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityIdentifier("quickadd_expand_button")
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .presentationDetents(showFullForm ? [.large] : [.height(340)])
        .presentationDragIndicator(.visible)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !showFullForm {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("quickadd_cancel_button")
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isAmountFocused = false
                    }
                }
            }
        }
        .alert("Amount Exceeds Allocation", isPresented: $showingOverflowAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Proceed Anyway") {
                performSave()
            }
        } message: {
            Text("The entered amount exceeds the allocated budget for this category. The excess will be applied to the total. Do you want to continue?")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            selectedBudgetPeriod = date.monthBounds.start
            viewModel.loadAvailableCategories(
                transactionDate: date,
                budget: initialBudget,
                excluding: nil
            )
            // Auto-focus amount
            isAmountFocused = true
        }
        .onChange(of: isIncome) { _, _ in
            selectedCategory = nil
        }
    }
    
    private var filteredCategories: [Category] {
        viewModel.availableCategories.filter { $0.isIncome == isIncome }
    }
    
    // MARK: - Subviews
    
    private var amountDescriptionRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Amount")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $amount)
                    .font(.system(size: 36, weight: .bold))
                    .keyboardType(.decimalPad)
                    .focused($isAmountFocused)
                    .accessibilityIdentifier("quickadd_amount_field")
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Description")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                TextField("Notes", text: $description)
                    .font(.body)
                    .submitLabel(.done)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    .accessibilityIdentifier("quickadd_description_field")
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var quickAmountChips: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach([5, 10, 25, 50], id: \.self) { val in
                Button("+\(val)") {
                    let current = Decimal(string: amount) ?? 0
                    let newAmount = current + Decimal(val)
                    amount = "\(newAmount)"
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.emeraldPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.emeraldSurface)
                .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var categorySelectionSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(filteredCategories) { category in
                    CompactCategoryButton(
                        category: category,
                        isSelected: selectedCategory?.id == category.id
                    )
                    .onTapGesture {
                        // Update description if it's empty or matches the last auto-filled name
                        if description.isEmpty || description == lastAutoFilledDescription {
                            description = category.name
                            lastAutoFilledDescription = category.name
                        }
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 48)
    }
    
    private var typeAndSaveRow: some View {
        HStack {
            Picker("Type", selection: $isIncome) {
                Text("Expense").tag(false)
                Text("Income").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
            .accessibilityIdentifier("quickadd_type_picker")
            
            Spacer()
            
            if !amount.isEmpty && selectedCategory != nil {
                Button {
                    saveTransaction()
                } label: {
                    Label("Save", systemImage: "checkmark")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.emeraldPrimary)
                        .clipShape(Capsule())
                }
                .accessibilityIdentifier("quickadd_save_button")
            }
        }
        .padding(.horizontal)
    }
    
    private var isValid: Bool {
        guard let decimalAmount = Decimal(string: amount),
              decimalAmount > 0,
              selectedCategory != nil else {
            return false
        }
        return true
    }
    
    private func saveTransaction() {
        guard let decimalAmount = Decimal(string: amount),
              let category = selectedCategory else {
            return
        }
        
        let hasOverflow = viewModel.checkOverflow(
            amount: decimalAmount,
            date: date,
            budget: initialBudget,
            category: category,
            existing: nil
        )
        
        if hasOverflow {
            showingOverflowAlert = true
            return
        }
        
        performSave()
    }
    
    private func performSave() {
        guard let decimalAmount = Decimal(string: amount),
              let category = selectedCategory else { return }
        
        do {
            try viewModel.saveTransaction(
                amount: decimalAmount,
                description: description.isEmpty ? category.name : description,
                date: date,
                budget: initialBudget,
                category: category,
                budgetPeriod: selectedBudgetPeriod,
                existing: nil
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct CompactCategoryButton: View {
    let category: Category
    let isSelected: Bool
    
    var body: some View {
        Text(category.name)
            .font(.system(.subheadline, design: .rounded))
            .fontWeight(isSelected ? .semibold : .medium)
            .foregroundStyle(isSelected ? Color.white : Color.appPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.emeraldPrimary : Color.appLightGray)
            .clipShape(Capsule())
            .accessibilityIdentifier("quickadd_category_\(category.name)")
    }
}

