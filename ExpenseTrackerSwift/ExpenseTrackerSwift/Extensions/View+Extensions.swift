import SwiftUI

struct CardStyle: ViewModifier {
    var backgroundColor: Color = .white
    var padding: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func cardStyle(backgroundColor: Color = .white, padding: CGFloat = 16) -> some View {
        modifier(CardStyle(backgroundColor: backgroundColor, padding: padding))
    }
    
    func headerStyle() -> some View {
        self.font(.system(.title2, design: .rounded).weight(.bold))
            .foregroundStyle(Color.appPrimary)
    }
    
    func subheaderStyle() -> some View {
        self.font(.system(.subheadline, design: .rounded).weight(.medium))
            .foregroundStyle(Color.appSecondary)
    }
}
