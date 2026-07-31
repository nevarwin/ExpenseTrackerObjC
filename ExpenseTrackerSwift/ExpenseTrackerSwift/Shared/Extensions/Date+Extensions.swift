import Foundation

extension Date {
    /// Get the start and end dates for the month containing this date
    var monthBounds: (start: Date, end: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        guard let startOfMonth = calendar.date(from: components) else {
            return (self, self)
        }
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: startOfMonth) else {
            return (startOfMonth, startOfMonth)
        }
        return (startOfMonth, endOfMonth)
    }
    
    /// Check if this date is in the current month
    var isInCurrentMonth: Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// Check if this date is in the same month as another date
    func isSameMonth(as otherDate: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: otherDate, toGranularity: .month)
    }
    
    /// Format this date as "Month Year" (e.g., "February 2026")
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
    
    /// Get the date for the previous month relative to this date
    var previousMonth: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: -1, to: self) ?? self
    }
    
    /// Get the date for the next month relative to this date
    var nextMonth: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: 1, to: self) ?? self
    }
    
    /// Get a list of month start dates between two dates
    static func monthsBetween(start: Date, end: Date) -> [Date] {
        let calendar = Calendar.current
        var months: [Date] = []
        
        var currentMonth = start.monthBounds.start
        
        while currentMonth <= end {
            months.append(currentMonth)
            
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else {
                break
            }
            currentMonth = nextMonth
        }
        
        return months
    }
}
