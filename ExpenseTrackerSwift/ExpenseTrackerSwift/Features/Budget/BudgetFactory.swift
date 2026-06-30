//  
//  BudgetFactory.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import Foundation
import SwiftUI

@MainActor
final class BudgetFactory {

    static func make() -> UIViewController {
        let view = BudgetListView()
        return UIHostingController(rootView: view)
    }

}
