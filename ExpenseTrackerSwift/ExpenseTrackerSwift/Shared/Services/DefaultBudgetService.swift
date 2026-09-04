//
//  DefaultBudgetService.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 9/5/26.
//

import SwiftUI
import Combine

// MARK: - Protocol

protocol DefaultBudgetServiceProtocol: AnyObject {
    var defaultBudgetID: UUID? { get set }
    func isDefault(budget: Budget) -> Bool
    func setDefault(budget: Budget)
    func clearDefault()
    func resolveDefaultBudget(from activeBudgets: [Budget]) -> Budget?
}

// MARK: - Service

final class DefaultBudgetService: DefaultBudgetServiceProtocol, ObservableObject {

    private static var _instance: DefaultBudgetService?

    static var instance: DefaultBudgetService {
        if let instance = _instance {
            return instance
        }
        let instance = DefaultBudgetService()
        _instance = instance
        return instance
    }

    static func configure() {
        guard _instance == nil else { return }
        _instance = DefaultBudgetService()
    }

    private let userDefaultsKey = "defaultTransactionBudgetID"
    private let userDefaults: UserDefaults

    @Published var defaultBudgetID: UUID? {
        didSet {
            if let id = defaultBudgetID {
                userDefaults.set(id.uuidString, forKey: userDefaultsKey)
            } else {
                userDefaults.removeObject(forKey: userDefaultsKey)
            }
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let savedString = userDefaults.string(forKey: userDefaultsKey),
           let uuid = UUID(uuidString: savedString) {
            self.defaultBudgetID = uuid
        } else {
            self.defaultBudgetID = nil
        }
    }

    func isDefault(budget: Budget) -> Bool {
        return budget.id == defaultBudgetID
    }

    func setDefault(budget: Budget) {
        defaultBudgetID = budget.id
    }

    func clearDefault() {
        defaultBudgetID = nil
    }

    func resolveDefaultBudget(from activeBudgets: [Budget]) -> Budget? {
        if let id = defaultBudgetID,
           let found = activeBudgets.first(where: { $0.id == id && $0.isActive }) {
            return found
        }
        return activeBudgets.first(where: { $0.isActive })
    }
}
