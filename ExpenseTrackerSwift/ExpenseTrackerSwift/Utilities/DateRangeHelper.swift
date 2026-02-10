import Foundation

/// Utility for calculating date ranges for monthly budget periods
struct DateRangeHelper {
    
    // MARK: - Month Bounds
    
    /// Get the start and end dates for the month containing the given date
    /// - Parameter date: The date to calculate bounds for (defaults to current date)
    /// - Returns: Tuple of (start, end) dates for the month
    static func monthBounds(for date: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        
        // Get the start of the month
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let startOfMonth = calendar.date(from: components) else {
            return (date, date)
        }
        
        // Get the end of the month (last moment of the last day)
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: startOfMonth) else {
            return (startOfMonth, startOfMonth)
        }
        
        return (startOfMonth, endOfMonth)
    }
    
    /// Get the start and end dates for the current month
    static func currentMonthBounds() -> (start: Date, end: Date) {
        return monthBounds(for: Date())
    }
    
    // MARK: - Date Checks
    
    /// Check if a date is in the current month
    /// - Parameter date: The date to check
    /// - Returns: True if the date is in the current month
    static func isInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }
    
    /// Check if two dates are in the same month
    /// - Parameters:
    ///   - date1: First date
    ///   - date2: Second date
    /// - Returns: True if both dates are in the same month and year
    static func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, equalTo: date2, toGranularity: .month)
    }
    
    // MARK: - Month Lists
    
    /// Get a list of month start dates between two dates
    /// - Parameters:
    ///   - start: Starting date
    ///   - end: Ending date
    /// - Returns: Array of dates representing the first day of each month in the range
    static func monthsBetween(start: Date, end: Date) -> [Date] {
        let calendar = Calendar.current
        var months: [Date] = []
        
        // Start at the beginning of the start month
        let startBounds = monthBounds(for: start)
        var currentMonth = startBounds.start
        
        // Add months until we reach or pass the end date
        while currentMonth <= end {
            months.append(currentMonth)
            
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else {
                break
            }
            currentMonth = nextMonth
        }
        
        return months
    }
    
    // MARK: - Formatting
    
    /// Format a date as "Month Year" (e.g., "February 2026")
    /// - Parameter date: The date to format
    /// - Returns: Formatted string
    static func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    /// Format a date as "Mon Year" (e.g., "Feb 2026")
    /// - Parameter date: The date to format
    /// - Returns: Formatted string
    static func shortMonthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
    
    /// Format a date as "Month" only (e.g., "February")
    /// - Parameter date: The date to format
    /// - Returns: Formatted string
    static func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
    
    // MARK: - Date Navigation
    
    /// Get the date for the previous month
    /// - Parameter from: Starting date (defaults to current date)
    /// - Returns: Date representing the same day in the previous month
    static func previousMonth(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: -1, to: date) ?? date
    }
    
    /// Get the date for the next month
    /// - Parameter from: Starting date (defaults to current date)
    /// - Returns: Date representing the same day in the next month
    static func nextMonth(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: 1, to: date) ?? date
    }
}
