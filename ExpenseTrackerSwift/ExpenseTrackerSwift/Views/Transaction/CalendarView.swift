import SwiftUI

struct CalendarView: View {
    @Bindable var viewModel: TransactionViewModel
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header: Dropdowns & Range Toggle
            HStack(spacing: 16) {
                // Year Dropdown
                Menu {
                    ForEach((viewModel.currentYear - 5)...(viewModel.currentYear + 5), id: \.self) { year in
                        Button(String(year)) {
                            viewModel.updateMonth(year: year, month: viewModel.currentMonth)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(String(viewModel.currentYear))
                            .fontWeight(.bold)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.primary)
                }
                
                // Month Dropdown
                Menu {
                    ForEach(1...12, id: \.self) { month in
                        Button(Calendar.current.monthSymbols[month - 1]) {
                            viewModel.updateMonth(year: viewModel.currentYear, month: month)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(Calendar.current.monthSymbols[viewModel.currentMonth - 1])
                            .fontWeight(.bold)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
                
                ForEach(generateDaysInMonth(), id: \.self) { date in
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
        }
        .padding(.vertical)
        .background(Color.appBackground)
    }
    
    private func generateDaysInMonth() -> [Date?] {
        let components = DateComponents(year: viewModel.currentYear, month: viewModel.currentMonth)
        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        let weekday = calendar.component(.weekday, from: startOfMonth) // 1 = Sun, 2 = Mon...
        let offset = weekday - 1
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
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
    
    enum SelectionState {
        case none, single, start, middle, end
    }
    
    var body: some View {
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
