//
//  AppProgressBar.swift
//  ExpenseTrackerSwift
//

import SwiftUI

struct AppProgressBar: View {
    enum Status {
        case healthy
        case warning
        case critical
    }

    let progress: Double
    var isOverBudget: Bool = false
    var status: Status? = nil
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = AppRow.progressBarHeight

    private var effectiveStatus: Status {
        if let status = status {
            return status
        }
        return isOverBudget ? .critical : .healthy
    }

    private var gradientColors: [Color] {
        switch effectiveStatus {
        case .healthy:
            return [Color.emeraldPrimary, Color.emeraldPrimary.opacity(0.7)]
        case .warning:
            return [Color.orange, Color.orange.opacity(0.7)]
        case .critical:
            return [Color.red, Color.orange]
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.appLightGray)
                    .frame(height: height)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
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
        AppProgressBar(progress: 0.65, status: .healthy)
        AppProgressBar(progress: 0.85, status: .warning)
        AppProgressBar(progress: 1.15, status: .critical)
    }
    .padding()
}
