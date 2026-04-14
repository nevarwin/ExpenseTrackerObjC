import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Background gradient for a premium feel
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        title: "Track Your Expenses",
                        description: "Easily track your expenses on a monthly, daily, or weekly basis to stay on top of your finances.",
                        imageName: "calendar",
                        imageColor: .blue
                    )
                    .tag(0)
                    
                    OnboardingPageView(
                        title: "Instant Import",
                        description: "Turn your specific Excel tracking templates into a powerful mobile app experience with a single tap.",
                        imageName: "tablecells.fill",
                        imageColor: .green
                    )
                    .tag(1)
                    
                    OnboardingPageView(
                        title: "Ready to Start?",
                        description: "Take control of your money and reach your financial goals faster.",
                        imageName: "sparkles",
                        imageColor: .purple
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut, value: currentPage)
                
                Button(action: {
                    if currentPage < 2 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        // Complete onboarding
                        hasCompletedOnboarding = true
                    }
                }) {
                    Text(currentPage < 2 ? String(localized: "Next") : String(localized: "Get Started"))
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
            Color.blue // Base color for glass tint
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.8))
                .shadow(radius: 5)
        }
    }
}

#Preview {
    OnboardingView()
}
