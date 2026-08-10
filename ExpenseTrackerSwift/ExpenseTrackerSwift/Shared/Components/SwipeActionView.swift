import SwiftUI

// MARK: - Swipe Action Configuration

struct SwipeAction: Identifiable {
    let id = UUID()
    let label: String
    let systemImage: String
    let tint: Color
    let role: ButtonRole?
    let action: () -> Void

    init(label: String, systemImage: String, tint: Color, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.label = label
        self.systemImage = systemImage
        self.tint = tint
        self.role = role
        self.action = action
    }
}

// MARK: - SwipeActionView

/// A reusable swipe-action wrapper for use in ScrollView + LazyVStack contexts.
/// Reveals trailing action buttons on left-swipe. Snaps open or closed based on drag threshold.
struct SwipeActionView<Content: View>: View {
    let trailingActions: [SwipeAction]
    let onTap: (() -> Void)?
    @ViewBuilder let content: Content

    @State private var offset: CGFloat = 0
    @State private var dragStartOffset: CGFloat = 0

    private let actionButtonWidth: CGFloat = 72
    private let snapThreshold: CGFloat = 0.4

    private var totalActionWidth: CGFloat {
        CGFloat(trailingActions.count) * actionButtonWidth
    }

    init(
        trailingActions: [SwipeAction],
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.trailingActions = trailingActions
        self.onTap = onTap
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Action buttons behind the row
            if offset < 0 {
                trailingActionsView
            }

            // Main content, shifted horizontally
            content
                .offset(x: offset)
                .contentShape(Rectangle())
                .onTapGesture {
                    if offset < 0 {
                        // If row is open, tapping resets row back to normal list view
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            offset = 0
                            dragStartOffset = 0
                        }
                    } else {
                        // Only trigger row action when row is closed and tapped
                        onTap?()
                    }
                }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onChanged { value in
                    let horizontalDrag = value.translation.width
                    let verticalDrag = value.translation.height

                    // Only respond if drag is predominantly horizontal
                    guard abs(horizontalDrag) > abs(verticalDrag) * 1.5 else { return }

                    let translation = horizontalDrag + dragStartOffset
                    if translation < 0 {
                        let limit = totalActionWidth * 1.2
                        offset = max(-limit, translation)
                    } else {
                        offset = min(0, translation)
                    }
                }
                .onEnded { value in
                    let horizontalDrag = value.translation.width
                    let verticalDrag = value.translation.height
                    
                    // Ignore vertical drag releases when row was not swiped open
                    guard abs(horizontalDrag) > abs(verticalDrag) || offset != 0 else { return }

                    let velocity = value.predictedEndTranslation.width - value.translation.width
                    let draggedPastThreshold = (-offset) >= (totalActionWidth * snapThreshold)
                    let isQuickSwipe = velocity < -300 && value.translation.width < -10

                    if draggedPastThreshold || isQuickSwipe {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            offset = -totalActionWidth
                        }
                        dragStartOffset = -totalActionWidth
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            offset = 0
                            dragStartOffset = 0
                        }
                    }
                }
        )
        .clipped()
    }

    // MARK: - Trailing Actions

    @ViewBuilder
    private var trailingActionsView: some View {
        HStack(spacing: 0) {
            ForEach(trailingActions) { swipeAction in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        offset = 0
                        dragStartOffset = 0
                    }
                    swipeAction.action()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: swipeAction.systemImage)
                            .font(.system(size: 16, weight: .semibold))
                        Text(swipeAction.label)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .frame(width: actionButtonWidth)
                    .frame(maxHeight: .infinity)
                    .background(swipeAction.tint)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("swipe_action_\(swipeAction.label.lowercased())")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
    }
}
