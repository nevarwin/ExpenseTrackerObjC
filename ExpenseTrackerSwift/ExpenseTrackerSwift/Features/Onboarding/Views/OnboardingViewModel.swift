//
//  OnboardingViewModel.swift
//  ExpenseTrackerSwift
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class OnboardingViewModel {
    var currentPage: Int = 0
    
    @ObservationIgnored
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboardingStorage = false
    
    var hasCompletedOnboarding: Bool {
        get { hasCompletedOnboardingStorage }
        set { hasCompletedOnboardingStorage = newValue }
    }
    
    let totalPages: Int = 3
    
    var isLastPage: Bool {
        currentPage >= totalPages - 1
    }
    
    func nextPage() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboardingStorage = true
    }
}
