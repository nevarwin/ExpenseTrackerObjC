//
//  ImportLoadingView.swift
//  ExpenseTrackerSwift
//

import SwiftUI

struct ImportLoadingView: View {
    let importType: ImportType
    let progress: ImportProgress
    let result: ImportResult?
    let onCancel: () -> Void
    let onDone: () -> Void
    
    @ScaledMetric private var iconSize: CGFloat = 40
    @ScaledMetric private var titleFontSize: CGFloat = 18
    
    private var isFinished: Bool {
        progress.stage == .completed || progress.stage == .cancelled || (progress.stage != .readingFile(filename: "") && isFailed)
    }
    
    private var isFailed: Bool {
        if case .failed = progress.stage { return true }
        return result?.success == false
    }
    
    private var isCancelled: Bool {
        progress.stage == .cancelled || result?.wasCancelled == true
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Modal Card Container
            VStack(spacing: 20) {
                // Header Icon & Title
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(headerBackgroundColor)
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: headerIconName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(headerIconColor)
                    }
                    
                    Text(headerTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("import_loading_header_title")
                    
                    if let filename = progress.currentFileName, !filename.isEmpty {
                        Text(filename)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.appSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                
                Divider()
                
                // Progress Indicator & Status
                if !isFinished {
                    VStack(spacing: 16) {
                        // Animated Progress Bar
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(progress.stage.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text("\(Int(progress.fractionCompleted * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.appPrimary)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.appSecondary.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.emeraldPrimary)
                                        .frame(width: max(0, geometry.size.width * CGFloat(progress.fractionCompleted)), height: 8)
                                        .animation(.easeInOut(duration: 0.3), value: progress.fractionCompleted)
                                }
                            }
                            .frame(height: 8)
                        }
                        
                        // Status detail description
                        if !progress.statusDetail.isEmpty {
                            Text(progress.statusDetail)
                                .font(.caption)
                                .foregroundStyle(Color.appSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                        
                        // Pipeline stage indicator
                        HStack(spacing: 12) {
                            StageStepView(step: 1, title: "Read", currentStep: progress.stage.stepIndex)
                            StageStepView(step: 2, title: "Parse", currentStep: progress.stage.stepIndex)
                            StageStepView(step: 3, title: "Import", currentStep: progress.stage.stepIndex)
                            StageStepView(step: 4, title: "Save", currentStep: progress.stage.stepIndex)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                } else {
                    // Result Summary Presentation
                    VStack(spacing: 12) {
                        if let res = result {
                            Text(res.message)
                                .font(.subheadline)
                                .foregroundStyle(res.success ? Color.primary : Color.red)
                                .multilineTextAlignment(.center)
                            
                            if res.success {
                                HStack(spacing: 16) {
                                    VStack {
                                        Text("\(res.importedCount)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(Color.appPrimary)
                                        Text("Records")
                                            .font(.caption2)
                                            .foregroundStyle(Color.appSecondary)
                                    }
                                    
                                    Divider()
                                        .frame(height: 30)
                                    
                                    VStack {
                                        Text("\(res.fileCount)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(Color.appPrimary)
                                        Text("Files")
                                            .font(.caption2)
                                            .foregroundStyle(Color.appSecondary)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        } else if isCancelled {
                            Text("The import operation was cancelled. All partial changes were safely rolled back.")
                                .font(.subheadline)
                                .foregroundStyle(Color.appSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                
                Divider()
                
                // Action Buttons
                HStack {
                    if isFinished {
                        Button {
                            onDone()
                        } label: {
                            Text("Done")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.emeraldPrimary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("import_loading_done_button")
                    } else {
                        Button {
                            onCancel()
                        } label: {
                            HStack {
                                Image(systemName: "xmark")
                                Text("Cancel Import")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .disabled(!progress.canCancel)
                        .accessibilityIdentifier("import_loading_cancel_button")
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 32)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityText)
            .accessibilityIdentifier("import_loading_overlay")
        }
    }
    
    // MARK: - Computed Styling Helpers
    
    private var headerTitle: String {
        if isCancelled {
            return "Import Cancelled"
        } else if isFailed {
            return "Import Failed"
        } else if progress.stage == .completed {
            return "Import Successful"
        } else {
            return "Importing \(importType.rawValue)"
        }
    }
    
    private var headerIconName: String {
        if isCancelled {
            return "xmark.circle.fill"
        } else if isFailed {
            return "exclamationmark.triangle.fill"
        } else if progress.stage == .completed {
            return "checkmark.circle.fill"
        } else {
            return importType.iconName
        }
    }
    
    private var headerIconColor: Color {
        if isCancelled {
            return .orange
        } else if isFailed {
            return .red
        } else if progress.stage == .completed {
            return Color.emeraldPrimary
        } else {
            return Color.appPrimary
        }
    }
    
    private var headerBackgroundColor: Color {
        headerIconColor.opacity(0.15)
    }
    
    private var accessibilityText: String {
        if isFinished {
            return "\(headerTitle). \(result?.message ?? "")"
        } else {
            return "\(headerTitle). \(progress.stage.title), \(Int(progress.fractionCompleted * 100))% complete."
        }
    }
}

// MARK: - Subviews

private struct StageStepView: View {
    let step: Int
    let title: String
    let currentStep: Int
    
    private var isCompleted: Bool { step < currentStep }
    private var isCurrent: Bool { step == currentStep }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(stepCircleBackground)
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(step)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(isCurrent ? .white : Color.appSecondary)
                }
            }
            
            Text(title)
                .font(.caption2)
                .fontWeight(isCurrent ? .bold : .regular)
                .foregroundStyle(isCurrent ? Color.primary : Color.appSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var stepCircleBackground: Color {
        if isCompleted {
            return Color.emeraldPrimary
        } else if isCurrent {
            return Color.emeraldPrimary
        } else {
            return Color.appSecondary.opacity(0.2)
        }
    }
}

#Preview {
    ImportLoadingView(
        importType: .transactions,
        progress: ImportProgress(
            stage: .parsingData(filename: "Jan2026.csv", current: 15, total: 50),
            fractionCompleted: 0.3,
            currentFileName: "Jan2026.csv",
            statusDetail: "Parsing record 15 of 50...",
            processedCount: 15,
            totalCount: 50
        ),
        result: nil,
        onCancel: {},
        onDone: {}
    )
}
