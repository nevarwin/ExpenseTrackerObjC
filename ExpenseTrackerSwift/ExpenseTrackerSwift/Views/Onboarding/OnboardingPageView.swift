import SwiftUI

struct OnboardingPageView: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let imageName: String
    let imageColor: Color
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(imageColor.gradient)
                .padding(40)
                .accessibilityHidden(true)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer() // Extra spacer to push content up slightly
        }
    }
}

#Preview {
    OnboardingPageView(
        title: "Track Expenses",
        description: "Easily track your expenses on a monthly, daily, or weekly basis.",
        imageName: "chart.bar.fill",
        imageColor: .blue
    )
}
