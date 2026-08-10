//
//  CategoryIconBadge.swift
//  ExpenseTrackerSwift
//

import SwiftUI

struct CategoryIconBadge: View {
    let iconName: String
    var tintColor: Color = Color.emeraldPrimary
    var backgroundColor: Color = Color.appLightGray
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = AppRow.iconSize

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: iconSize, height: iconSize)
            
            Image(systemName: iconName)
                .foregroundStyle(tintColor)
                .font(.system(size: iconSize * 0.4, weight: .semibold, design: .rounded))
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        CategoryIconBadge(iconName: "bag.fill")
        CategoryIconBadge(iconName: "creditcard.fill", tintColor: .blue)
        CategoryIconBadge(iconName: "car.fill", tintColor: .orange)
    }
    .padding()
}
