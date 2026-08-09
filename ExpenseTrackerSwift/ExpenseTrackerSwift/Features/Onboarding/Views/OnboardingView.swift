//  
//  OnboardingView.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import SwiftUI

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    
    var body: some View {
        ZStack {
            // Background gradient for an Emerald glass feel
            LinearGradient(
                colors: [Color.emeraldPrimary.opacity(0.15), Color.emeraldPrimary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                TabView(selection: $viewModel.currentPage) {
                    OnboardingPageView(
                        title: "Track Your Expenses",
                        description: "Easily track your expenses on a monthly, daily, or weekly basis to stay on top of your finances.",
                        imageName: "calendar",
                        imageColor: .emeraldPrimary
                    )
                    .tag(0)
                    
                    OnboardingPageView(
                        title: "Instant Import",
                        description: "Turn your specific Excel tracking templates into a powerful mobile app experience with a single tap.",
                        imageName: "tablecells.fill",
                        imageColor: .emeraldPrimary
                    )
                    .tag(1)
                    
                    OnboardingPageView(
                        title: "Ready to Start?",
                        description: "Take control of your money and reach your financial goals faster.",
                        imageName: "sparkles",
                        imageColor: .emeraldPrimary
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut, value: viewModel.currentPage)
                
                Button(action: {
                    viewModel.nextPage()
                }) {
                    Text(!viewModel.isLastPage ? String(localized: "Next") : String(localized: "Get Started"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            glassBackground
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
    
    // Abstracting the background view for readability and Liquid Glass fallback
    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 26, *) {
            Color.emeraldPrimary // Base color for glass tint
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.emeraldPrimary)
                .shadow(radius: 5)
        }
    }
}

#Preview {
    OnboardingView()
}
