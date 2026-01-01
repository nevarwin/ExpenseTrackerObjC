//
//  DateExtensions.swift
//  ExpenseTracker
//
//  Created by raven on 6/26/25.
//

import Foundation

extension Date {
    func startOfMonth(calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func endOfMonth(calendar: Calendar = .current) -> Date {
        let components = DateComponents(month: 1, day: -1)
        return calendar.date(byAdding: components, to: startOfMonth(calendar: calendar)) ?? self
    }
    
    func startOfWeek(calendar: Calendar = .current) -> Date {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: components) ?? self
    }
    
    func endOfWeek(calendar: Calendar = .current) -> Date {
        var cal = calendar
        cal.firstWeekday = 2
        let components = DateComponents(day: 6)
        return cal.date(byAdding: components, to: startOfWeek(calendar: cal)) ?? self
    }
    
    func weekIndexInMonth(calendar: Calendar = .current) -> Int {
        var cal = calendar
        cal.firstWeekday = 2
        
        let startOfMonth = self.startOfMonth(calendar: cal)
        let firstMonday = startOfMonth.startOfWeek(calendar: cal)
        
        if firstMonday < startOfMonth {
            let daysToAdd = (9 - cal.component(.weekday, from: startOfMonth)) % 7
            let adjustedMonday = cal.date(byAdding: .day, value: daysToAdd, to: startOfMonth) ?? startOfMonth
            let daysDiff = cal.dateComponents([.day], from: adjustedMonday, to: self).day ?? 0
            return max(0, daysDiff / 7)
        } else {
            let daysDiff = cal.dateComponents([.day], from: firstMonday, to: self).day ?? 0
            return max(0, daysDiff / 7)
        }
    }
}

extension DateComponents {
    static func monthYear(month: Int, year: Int, calendar: Calendar = .current) -> DateComponents {
        var components = DateComponents()
        components.year = year
        components.month = month
        return components
    }
}

