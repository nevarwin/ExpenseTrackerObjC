import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var currencyManager = CurrencyManager()
    @State private var budgetViewModel: BudgetViewModel?
    @State private var isFABExpanded = false  // Controls FAB menu open/close
    
    @Query(filter: #Predicate<Budget> { $0.isActive == true })
    private var activeBudgets: [Budget]
    
    var body: some View {
        Group {
            if let viewModel = budgetViewModel {
                ZStack(alignment: .bottomTrailing) {
                    
                    TabView {
                        HomeView(viewModel: viewModel)
                            .tabItem {
                                Label("Home", systemImage: "house.fill")
                            }
                        
                        BudgetListView(viewModel: viewModel)
                            .tabItem {
                                Label("Budgets", systemImage: "creditcard.fill")
                            }
                        
                        TransactionListView()
                            .tabItem {
                                Label("Transactions", systemImage: "list.bullet")
                            }
                    }
                    
                    // Dimmed background when FAB is open
                    if isFABExpanded {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    isFABExpanded = false
                                }
                            }
                    }
                    
                    // FAB Stack
                    VStack(alignment: .trailing, spacing: 16) {
                        
                        // Action buttons (visible when expanded)
                        if isFABExpanded {
                            FABActionButton(
                                title: "Import PDF",
                                systemImage: "doc.text",
                                color: .orange
                            ) {
                                /* Action 3 */
                                withAnimation(.spring()) { isFABExpanded = false }
                            }
                            
                            FABActionButton(
                                title: "Add Budget",
                                systemImage: "minus.circle",
                                color: .red
                            ) {
                                /* Action 2 */
                                withAnimation(.spring()) { isFABExpanded = false }
                            }
                            
                            FABActionButton(
                                title: "Add Transaction",
                                systemImage: "plus.circle",
                                color: .green
                            ) {
                                /* Action 1 */
                                withAnimation(.spring()) { isFABExpanded = false }
                            }
                        }
                        
                        // Main FAB button
                        Button {
                            withAnimation(.spring()) {
                                isFABExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: isFABExpanded ? "xmark" : "plus")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                .rotationEffect(.degrees(isFABExpanded ? 45 : 0))
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 90) // Sits above the tab bar
                }
            } else {
                ProgressView()
                    .onAppear {
                        modelContext.autosaveEnabled = false
                        let vm = BudgetViewModel(modelContext: modelContext)
                        vm.loadBudgets()
                        self.budgetViewModel = vm
                    }
            }
        }
        .environmentObject(currencyManager)
    }
}

// Reusable FAB Action Button
struct FABMainButton: View {
    @Binding var isFABExpanded: Bool
    @State private var isPressed = false        // Tracks press scale effect
    @State private var showRipple = false       // Long press ripple feedback
    
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onDoubleTap: () -> Void
    
    var body: some View {
        ZStack {
            // Ripple ring (long press visual feedback)
            Circle()
                .stroke(Color.accentColor.opacity(0.4), lineWidth: 3)
                .frame(width: showRipple ? 90 : 60, height: showRipple ? 90 : 60)
                .opacity(showRipple ? 0 : 1)
                .animation(.easeOut(duration: 0.5), value: showRipple)
            
            // Main button
            Image(systemName: isFABExpanded ? "xmark" : "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                .rotationEffect(.degrees(isFABExpanded ? 45 : 0))
                .scaleEffect(isPressed ? 0.88 : 1.0)
                .animation(.spring(response: 0.3), value: isPressed)
        }
        // Double tap gesture
        .onTapGesture(count: 2) {
            triggerHaptic(.medium)
            onDoubleTap()
        }
        // Single tap gesture
        .onTapGesture(count: 1) {
            triggerHaptic(.light)
            onTap()
        }
        // Long press gesture
        .onLongPressGesture(minimumDuration: 0.5) {
            // On long press confirmed
            triggerHaptic(.heavy)
            showRipple = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showRipple = false
            }
            onLongPress()
        } onPressingChanged: { isPressing in
            // Scale feedback while pressing
            withAnimation(.spring(response: 0.3)) {
                isPressed = isPressing
            }
        }
    }
    
    // Haptic feedback helper
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// FAB Action Button
struct FABActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                
                Image(systemName: systemImage)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .clipShape(Circle())
                    .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 3)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
}
