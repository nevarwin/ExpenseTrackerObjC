//
//  ServiceEnvironmentKeys.swift
//  ExpenseTrackerSwift
//

import SwiftUI

// MARK: - Analytics Service Environment Key

private struct AnalyticsServiceKey: EnvironmentKey {
    static let defaultValue: AnalyticsServiceProtocol = SharedAnalyticsService.instance
}

// MARK: - Currency Service Environment Key

private struct CurrencyServiceKey: EnvironmentKey {
    static let defaultValue: CurrencyServiceProtocol = SharedCurrencyService.instance
}

// MARK: - Permission Service Environment Key

private struct PermissionServiceKey: EnvironmentKey {
    static let defaultValue: PermissionServiceProtocol = SharedPermissionService.instance
}

// MARK: - Default Budget Service Environment Key

private struct DefaultBudgetServiceKey: EnvironmentKey {
    static let defaultValue: DefaultBudgetServiceProtocol = DefaultBudgetService.instance
}

// MARK: - EnvironmentValues Extension

extension EnvironmentValues {
    var analyticsService: AnalyticsServiceProtocol {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }

    var currencyService: CurrencyServiceProtocol {
        get { self[CurrencyServiceKey.self] }
        set { self[CurrencyServiceKey.self] = newValue }
    }

    var permissionService: PermissionServiceProtocol {
        get { self[PermissionServiceKey.self] }
        set { self[PermissionServiceKey.self] = newValue }
    }

    var defaultBudgetService: DefaultBudgetServiceProtocol {
        get { self[DefaultBudgetServiceKey.self] }
        set { self[DefaultBudgetServiceKey.self] = newValue }
    }
}
