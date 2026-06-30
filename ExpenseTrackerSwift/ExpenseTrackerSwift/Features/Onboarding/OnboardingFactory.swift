//  
//  OnboardingFactory.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import Foundation
import SwiftUI

@MainActor
final class OnboardingFactory {

    static func make() -> UIViewController {
        let view = OnboardingView()
        return UIHostingController(rootView: view)
    }

}
