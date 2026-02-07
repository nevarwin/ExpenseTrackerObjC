import SwiftUI

struct CalendarView: View {
    @Bindable var viewModel: TransactionViewModel
    
    @State private var showingDatePicker = false
    @State private var selectedMonth = 1
    @State private var selectedYear = 2024
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header: Navigation & Range Toggle
            HStack(spacing: 16) {
                // Previous Button
                Button(action: { 
                    withAnimation { viewModel.previousPage() }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                        .foregroundStyle(.primary)
                }
                
                // Month/Year Title (Unified Picker)
                Button(action: { showingDatePicker = true }) {
                    HStack(spacing: 4) {
                        Text(monthYearString)
                            .font(.headline)
                            .fontWeight(.bold)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.primary)
                }
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
                                    Text(String(year).replacingOccurrences(of: ",", with: "")).tag(year)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                        }
                        
                        Button("Done") {
                            viewModel.updateMonth(year: selectedYear, month: selectedMonth)
                            showingDatePicker = false
                            viewModel.loadTransactions()
                            viewModel.loadTransactionDates()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom)
                    }
                    .presentationDetents([.height(300)])
                    .onAppear {
                        selectedMonth = viewModel.currentMonth
                        selectedYear = viewModel.currentYear
                    }
                }
                
                // Next Button
                Button(action: { 
                    withAnimation { viewModel.nextPage() }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // Range Toggle
                Toggle("Range", isOn: $viewModel.isRangeMode)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .overlay(
                        Text(viewModel.isRangeMode ? "Range" : "Single")
                            .font(.caption2)
                            .offset(y: 20)
                    )
            }
            .padding(.horizontal)
            
            // Days Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(Color.appSecondary)
                }
                
                ForEach(viewModel.generateCalendarDays(), id: \.self) { date in
                    if let date = date {
                        DayCell(date: date, viewModel: viewModel)
                            .onTapGesture {
                                viewModel.selectDate(date)
                            }
                    } else {
                        Text("")
                    }
                }
            }
            .padding(.horizontal)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -50 {
                            withAnimation { viewModel.nextPage() }
                        } else if value.translation.width > 50 {
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
        .onChange(of: viewModel.selectedDate) { _, _ in
            viewModel.loadTransactionDates()
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.selectedDate)
    }
}

struct DayCell: View {
    let date: Date
    var viewModel: TransactionViewModel
    
    private var selectionState: SelectionState {
        if viewModel.isRangeMode, let range = viewModel.selectedDateRange {
            if range.contains(date) {
                if range.lowerBound == range.upperBound {
                    return .single // Single day range
                } else if Calendar.current.isDate(date, inSameDayAs: range.lowerBound) {
                    return .start // Start of range
                } else if Calendar.current.isDate(date, inSameDayAs: range.upperBound) {
                    return .end // End of range
                } else {
                    return .middle // Middle of range
                }
            }
        } else if Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate) && !viewModel.isRangeMode {
            return .single // Single selection mode
        }
        return .none
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var hasTransaction: Bool {
        viewModel.transactionDates.contains(Calendar.current.startOfDay(for: date))
    }
    
    enum SelectionState {
        case none, single, start, middle, end
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.callout)
                .fontWeight(selectionState != .none ? .semibold : .regular)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(backgroundView)
                .foregroundStyle(selectionState != .none ? .white : .primary)
                .overlay(
                    // Today indicator (only if not selected)
                    selectionState == .none && isToday ? Circle().stroke(Color.blue, lineWidth: 1) : nil
                )
            
            // Transaction Indicator
            if hasTransaction {
                Circle()
                    .fill(Color.red)
                    .frame(width: 4, height: 4)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch selectionState {
        case .single:
            Circle().fill(Color.blue)
        case .start:
            HStack(spacing: 0) {
                Color.clear
                Color.blue
            }
            .overlay(
                Circle().fill(Color.blue)
            )
        case .middle:
            Color.blue
        case .end:
             HStack(spacing: 0) {
                Color.blue
                Color.clear
            }
            .overlay(
                Circle().fill(Color.blue)
            )
        case .none:
            Color.clear
        }
    }
}
