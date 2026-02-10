import SwiftUI
import Charts

struct BudgetHistoryView: View {
    let budget: Budget
    @EnvironmentObject var currencyManager: CurrencyManager
    @State private var selectedRange: DateRange = .sixMonths
    
    enum DateRange: String, CaseIterable {
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case all = "All"
        
        var displayName: String {
            switch self {
            case .threeMonths: return "3 Months"
            case .sixMonths: return "6 Months"
            case .oneYear: return "1 Year"
            case .all: return "All Time"
            }
        }
    }
    
    private var monthsToShow: [Date] {
        let calendar = Calendar.current
        let oldestTransaction = budget.transactions.min(by: { $0.date < $1.date })?.date ?? Date()
        let startDate: Date
        
        switch selectedRange {
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        case .oneYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        case .all:
            startDate = oldestTransaction
        }
        
        return DateRangeHelper.monthsBetween(start: startDate, end: Date())
    }
    
    var body: some View {
        List {
            // Range picker
            Section {
                Picker("Range", selection: $selectedRange) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            // Trend chart
            Section {
                if monthsToShow.count > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Spending Trend")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        Chart {
                            ForEach(monthsToShow, id: \.self) { month in
                                LineMark(
                                    x: .value("Month", month, unit: .month),
                                    y: .value("Expenses", NSDecimalNumber(decimal: budget.expensesInMonth(month)).doubleValue)
                                )
                                .foregroundStyle(Color.appAccent)
                                .interpolationMethod(.catmullRom)
                                
                                AreaMark(
                                    x: .value("Month", month, unit: .month),
                                    y: .value("Expenses", NSDecimalNumber(decimal: budget.expensesInMonth(month)).doubleValue)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.appAccent.opacity(0.3), Color.appAccent.opacity(0.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(DateRangeHelper.shortMonthYearString(from: date))
                                            .font(.caption2)
                                    }
                                }
                                AxisGridLine()
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisValueLabel()
                                AxisGridLine()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundStyle(Color.appSecondary.opacity(0.3))
                        Text("Not enough data to show trend")
                            .font(.subheadline)
                            .foregroundStyle(Color.appSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                }
            }
            
            // Monthly breakdown
            Section("Monthly Breakdown") {
                if monthsToShow.isEmpty {
                    Text("No transaction history")
                        .foregroundStyle(. secondary)
                        .padding()
                } else {
                    ForEach(monthsToShow.reversed(), id: \.self) { month in
                        MonthSummaryRow(budget: budget, month: month)
                    }
                }
            }
        }
        .navigationTitle("Budget History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MonthSummaryRow: View {
    let budget: Budget
    let month: Date
    @EnvironmentObject var currencyManager: CurrencyManager
    
    private var isCurrentMonth: Bool {
        DateRangeHelper.isInCurrentMonth(month)
    }
    
    var body: some View {
        NavigationLink {
            MonthDetailView(budget: budget, month: month)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(DateRangeHelper.monthYearString(from: month))
                        .font(.headline)
                    
                    if isCurrentMonth {
                        Text("Current")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.appAccent)
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Income")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(budget.incomeInMonth(month), format: .currency(code: currencyManager.currencyCode))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spent")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(budget.expensesInMonth(month), format: .currency(code: currencyManager.currencyCode))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(budget.remainingInMonth(month), format: .currency(code: currencyManager.currencyCode))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(budget.remainingInMonth(month) >= 0 ? .green : .red)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}


#Preview {
    @Previewable @State var budget: Budget = {
        let b = Budget(name: "February Budget", totalAmount: 5000)
        return b
    }()
    
    NavigationStack {
        BudgetHistoryView(budget: budget)
            .environmentObject(CurrencyManager())
    }
}

