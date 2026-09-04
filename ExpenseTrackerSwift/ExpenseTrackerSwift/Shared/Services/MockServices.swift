//
//  MockServices.swift
//  ExpenseTrackerSwift
//

import Foundation
import Photos
import Combine

// MARK: - Mock Analytics Service

final class MockAnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    private(set) var trackedEvents: [(name: String, properties: [String: Any]?)] = []
    private(set) var trackedScreens: [(name: String, properties: [String: Any]?)] = []
    private(set) var isSetupCalled = false
    private(set) var isEnabledState = true

    func setup() {
        isSetupCalled = true
    }

    func setEnabled(_ enabled: Bool) {
        isEnabledState = enabled
    }

    func trackScreen(_ screenName: String, properties: [String: Any]? = nil) {
        trackedScreens.append((name: screenName, properties: properties))
    }

    func trackEvent(_ eventName: String, properties: [String: Any]? = nil) {
        trackedEvents.append((name: eventName, properties: properties))
    }
}

// MARK: - Mock Currency Service

final class MockCurrencyService: CurrencyServiceProtocol {
    var currencyCode: String = "USD"
    var availableCurrencies: [String] = ["USD", "EUR", "GBP", "PHP"]
    var currencySymbol: String { "$" }
}

// MARK: - Mock Permission Service

final class MockPermissionService: PermissionServiceProtocol {
    var mockStatus: PHAuthorizationStatus = .authorized
    private(set) var isOpenSettingsCalled = false

    func openSettings() {
        isOpenSettingsCalled = true
    }

    func checkPhotoLibraryPermission(completion: @escaping (PHAuthorizationStatus) -> Void) {
        completion(mockStatus)
    }
}

// MARK: - Mock Default Budget Service

final class MockDefaultBudgetService: DefaultBudgetServiceProtocol {
    var defaultBudgetID: UUID?
    private(set) var setDefaultCalledWith: Budget?
    private(set) var clearDefaultCalled = false

    init(defaultBudgetID: UUID? = nil) {
        self.defaultBudgetID = defaultBudgetID
    }

    func isDefault(budget: Budget) -> Bool {
        return budget.id == defaultBudgetID
    }

    func setDefault(budget: Budget) {
        defaultBudgetID = budget.id
        setDefaultCalledWith = budget
    }

    func clearDefault() {
        defaultBudgetID = nil
        clearDefaultCalled = true
    }

    func resolveDefaultBudget(from activeBudgets: [Budget]) -> Budget? {
        if let id = defaultBudgetID,
           let found = activeBudgets.first(where: { $0.id == id && $0.isActive }) {
            return found
        }
        return activeBudgets.first(where: { $0.isActive })
    }
}
