import SwiftUI

struct AppCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var borderColor: Color? = nil
    var borderWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .strokeBorder(
                        borderColor ?? (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)),
                        lineWidth: borderWidth
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
    }
}

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var backgroundColor: Color = .appSurface
    var padding: CGFloat = AppSpacing.lg
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 1)
            )
    }
}

// MARK: - Bouncy Button Style

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy in
                    let width = proxy.size.width
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.25),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: width * 1.5)
                    .offset(x: -width + (phase * width * 2))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func appCardStyle(borderColor: Color? = nil, borderWidth: CGFloat = 1) -> some View {
        self.modifier(AppCardModifier(borderColor: borderColor, borderWidth: borderWidth))
    }
    
    func cardStyle(backgroundColor: Color = .appSurface, padding: CGFloat = AppSpacing.lg) -> some View {
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

    func bouncyButtonStyle() -> some View {
        buttonStyle(BouncyButtonStyle())
    }

    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }

    func minTouchTarget(minSize: CGFloat = 44) -> some View {
        frame(minWidth: minSize, minHeight: minSize)
            .contentShape(Rectangle())
    }
}
