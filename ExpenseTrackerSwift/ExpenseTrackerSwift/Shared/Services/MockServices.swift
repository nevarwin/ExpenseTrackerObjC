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
