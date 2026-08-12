import SwiftUI

struct TransactionCalendarView: View {
    @Bindable var viewModel: TransactionViewModel
    var onDateTapped: ((Bool) -> Void)? = nil
    
    @State private var showingDatePicker = false
    @State private var selectedMonth = 1
    @State private var selectedYear = 2024
    @State private var swipeDirection: Edge = .trailing
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header: Navigation & Range Toggle
            VStack(spacing: 16) {
                // Top Row: Today Button, Scope Toggle, Range Toggle
                HStack {
                    Button(action: { 
                        swipeDirection = .trailing
                        withAnimation { 
                            viewModel.selectedDate = Date()
                            viewModel.loadTransactions()
                            viewModel.loadTransactionDates()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("Today")
                                .font(.subheadline)
                                .foregroundStyle(Calendar.current.isDateInToday(viewModel.selectedDate) ? .primary : .secondary)
                                .bold(Calendar.current.isDateInToday(viewModel.selectedDate))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityIdentifier("calendar_today_button")
                    
                    Spacer()
                    
                    Picker("Scope", selection: $viewModel.calendarScope) {
                        Text("Week").tag(TransactionViewModel.CalendarScope.week)
                        Text("Month").tag(TransactionViewModel.CalendarScope.month)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                    .accessibilityIdentifier("calendar_scope_picker")
                    
                    Spacer()
                    
                    Toggle("Range", isOn: $viewModel.isRangeMode)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .appAccent))
                        .accessibilityIdentifier("calendar_range_toggle")
                }
                .padding(.horizontal)
                
                // Bottom Row: Month/Year & Navigation
                HStack(spacing: 16) {
                    // Previous Button
                    Button(action: { 
                        swipeDirection = .leading
                        withAnimation { viewModel.previousPage() }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                            .padding(10)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                            .foregroundStyle(.primary)
                            .minTouchTarget()
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("calendar_prev_button")
                    
                    // Month/Year Title (Unified Picker)
                    Button(action: { showingDatePicker = true }) {
                        HStack(spacing: 4) {
                            Text(monthYearString)
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.primary)
                        .minTouchTarget()
                    }
                    .accessibilityIdentifier("calendar_month_year_button")
                    .sheet(isPresented: $showingDatePicker) {
                        VStack(spacing: 20) {
                            Text("Select Month & Year")
                                .font(.headline)
                                .padding(.top)
                            
                            HStack(spacing: 0) {
                                Picker("Month", selection: $selectedMonth) {
                                    ForEach(1...12, id: \.self) { month in
                                        Text(Calendar.current.monthSymbols[month - 1]).tag(month)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 150)
                                
                                Picker("Year", selection: $selectedYear) {
                                    ForEach((viewModel.currentYear - 10)...(viewModel.currentYear + 10), id: \.self) { year in
                                        Text(verbatim: "\(year)").tag(year)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 100)
                            }
                            
                            Button("Done") {
                                swipeDirection = selectedMonth > viewModel.currentMonth || selectedYear > viewModel.currentYear ? .trailing : .leading
                                withAnimation {
                                    viewModel.updateMonth(year: selectedYear, month: selectedMonth)
                                }
                                showingDatePicker = false
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.emeraldPrimary)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(300)])
                        .onAppear {
                            selectedMonth = viewModel.currentMonth
                            selectedYear = viewModel.currentYear
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Next Button
                    Button(action: { 
                        swipeDirection = .trailing
                        withAnimation { viewModel.nextPage() }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .padding(10)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                            .foregroundStyle(.primary)
                            .minTouchTarget()
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("calendar_next_button")
                }
                .padding(.horizontal)
            }
            
            // Days Grid
            VStack {
                // Weekday headers
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .foregroundStyle(Color.appSecondary)
                    }
                }
                .padding(.horizontal)
                
                // Actual days
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                    ForEach(Array(viewModel.generateCalendarDays().enumerated()), id: \.offset) { _, date in
                        if let date = date {
                            DayCell(date: date, viewModel: viewModel) {
                                viewModel.selectDate(date)
                                
                                let hasTx = viewModel.transactionDates.contains(Calendar.current.startOfDay(for: date))
                                onDateTapped?(hasTx)
                            }
                        } else {
                            Color.clear
                                .frame(minHeight: 32)
                        }
                    }
                }
                .padding(.horizontal)
                .id(calendarScopeID)
                .transition(.push(from: swipeDirection))
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 15, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        guard abs(horizontal) > abs(vertical) else { return }
                        
                        if horizontal < -50 {
                            swipeDirection = .trailing
                            withAnimation { viewModel.nextPage() }
                        } else if horizontal > 50 {
                            swipeDirection = .leading
                            withAnimation { viewModel.previousPage() }
                        }
                    }
            )
            .animation(.easeInOut, value: viewModel.calendarScope)
            .animation(.easeInOut, value: viewModel.selectedDate)
        }
        .padding(.vertical)
        .background(Color.appBackground)
        .onAppear {
            viewModel.loadTransactionDates()
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.selectedDate)
    }
    
    private var calendarScopeID: String {
        if viewModel.calendarScope == .week {
            return "week-\(viewModel.currentYear)-\(Calendar.current.component(.weekOfYear, from: viewModel.selectedDate))-\(viewModel.isRangeMode)"
        } else {
            return "month-\(viewModel.currentYear)-\(viewModel.currentMonth)-\(viewModel.isRangeMode)"
        }
    }
}

struct DayCell: View {
    let date: Date
    var viewModel: TransactionViewModel
    var action: () -> Void
    
    private var selectionState: SelectionState {
        if viewModel.isRangeMode, let range = viewModel.selectedDateRange {
            if range.contains(date) {
                if range.lowerBound == range.upperBound {
                    return .single
                } else if Calendar.current.isDate(date, inSameDayAs: range.lowerBound) {
                    return .start
                } else if Calendar.current.isDate(date, inSameDayAs: range.upperBound) {
                    return .end
                } else {
                    return .middle
                }
            }
        } else if Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate) && !viewModel.isRangeMode {
            return .single
        }
        return .none
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var hasIncome: Bool {
        viewModel.incomeTransactionDates.contains(Calendar.current.startOfDay(for: date))
    }
    
    private var hasExpense: Bool {
        viewModel.expenseTransactionDates.contains(Calendar.current.startOfDay(for: date))
    }
    
    private var isSearchResult: Bool {
        viewModel.searchHighlightDates.contains(Calendar.current.startOfDay(for: date))
    }
    
    enum SelectionState {
        case none, single, start, middle, end
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.callout)
                    .fontWeight(selectionState != .none ? .semibold : .regular)
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .background(backgroundView)
                    .foregroundStyle(selectionState == .single || selectionState == .start || selectionState == .end ? Color.white : Color.appPrimary)
                    .overlay(
                        Group {
                            if isSearchResult {
                                Circle().stroke(Color.emeraldPrimary, lineWidth: 2)
                            } else if selectionState == .none && isToday {
                                Circle().stroke(Color.dynamicAccent, lineWidth: 1)
                            }
                        }
                    )
                
                // Income & Expense Indicator Dots
                HStack(spacing: 2) {
                    if hasIncome {
                        Circle()
                            .fill(Color.emeraldPrimary)
                            .frame(width: 4, height: 4)
                    }
                    if hasExpense {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 4, height: 4)
                    }
                    if !hasIncome && !hasExpense {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(date.formatted(.dateTime.month().day())) \((hasIncome || hasExpense) ? "Has transactions" : "No transactions")"))
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch selectionState {
        case .single:
            Circle().fill(Color.dynamicAccent)
        case .start:
            HStack(spacing: 0) {
                Color.clear
                Color.emeraldSurface
            }
            .overlay(
                Circle().fill(Color.dynamicAccent)
            )
        case .middle:
            Rectangle().fill(Color.emeraldSurface)
        case .end:
             HStack(spacing: 0) {
                Color.emeraldSurface
                Color.clear
            }
            .overlay(
                Circle().fill(Color.dynamicAccent)
            )
        case .none:
            Color.clear
        }
    }
}
