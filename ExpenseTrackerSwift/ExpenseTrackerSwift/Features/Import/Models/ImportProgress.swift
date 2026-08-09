//
//  ImportProgress.swift
//  ExpenseTrackerSwift
//

import Foundation

/// Represents the active stage of an import process
enum ImportStage: Equatable {
    case readingFile(filename: String)
    case parsingData(filename: String, current: Int, total: Int?)
    case importingRecords(current: Int, total: Int?)
    case savingDatabase
    case completed
    case cancelled
    case failed(reason: String)
    
    var title: String {
        switch self {
        case .readingFile:
            return "Reading File"
        case .parsingData:
            return "Parsing Data"
        case .importingRecords:
            return "Importing Records"
        case .savingDatabase:
            return "Saving to Database"
        case .completed:
            return "Import Complete"
        case .cancelled:
            return "Import Cancelled"
        case .failed:
            return "Import Failed"
        }
    }
    
    var iconName: String {
        switch self {
        case .readingFile:
            return "doc.text"
        case .parsingData:
            return "gearshape.2.fill"
        case .importingRecords:
            return "square.and.arrow.down.fill"
        case .savingDatabase:
            return "cylinder.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .cancelled:
            return "xmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var stepIndex: Int {
        switch self {
        case .readingFile:
            return 1
        case .parsingData:
            return 2
        case .importingRecords:
            return 3
        case .savingDatabase:
            return 4
        case .completed, .cancelled, .failed:
            return 5
        }
    }
}

/// Progress state payload for import operations
struct ImportProgress: Equatable {
    var stage: ImportStage
    var fractionCompleted: Double
    var currentFileName: String?
    var statusDetail: String
    var processedCount: Int
    var totalCount: Int?
    var canCancel: Bool
    
    init(
        stage: ImportStage = .readingFile(filename: ""),
        fractionCompleted: Double = 0.0,
        currentFileName: String? = nil,
        statusDetail: String = "",
        processedCount: Int = 0,
        totalCount: Int? = nil,
        canCancel: Bool = true
    ) {
        self.stage = stage
        self.fractionCompleted = fractionCompleted
        self.currentFileName = currentFileName
        self.statusDetail = statusDetail
        self.processedCount = processedCount
        self.totalCount = totalCount
        self.canCancel = canCancel
    }
}
