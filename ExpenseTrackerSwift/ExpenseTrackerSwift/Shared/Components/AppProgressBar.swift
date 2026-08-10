//
//  AppProgressBar.swift
//  ExpenseTrackerSwift
//

import SwiftUI

struct AppProgressBar: View {
    let progress: Double
    var isOverBudget: Bool = false
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = AppRow.progressBarHeight

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.appLightGray)
                    .frame(height: height)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                isOverBudget ? Color.red : Color.emeraldPrimary,
                                isOverBudget ? Color.orange : Color.emeraldPrimary.opacity(0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(geometry.size.width * max(0, min(progress, 1.0)), geometry.size.width)), height: height)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 16) {
        AppProgressBar(progress: 0.65)
        AppProgressBar(progress: 1.15, isOverBudget: true)
    }
    .padding()
}
