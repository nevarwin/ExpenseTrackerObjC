//  
//  TransactionFactory.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 7/29/26.
//

import Foundation
import SwiftUI

@MainActor
final class TransactionFactory {

    static func make() -> UIViewController {
        let view = TransactionListView()
        return UIHostingController(rootView: view)
    }

}
