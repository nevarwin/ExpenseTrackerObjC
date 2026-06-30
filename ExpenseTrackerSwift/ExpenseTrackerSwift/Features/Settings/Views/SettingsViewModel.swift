//  
//  SettingsViewModel.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import Foundation

@MainActor
final class SettingsViewModel: NSObject, ObservableObject {

    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?

    @Published var samples: [SettingsSample]?
    @Published var latestCreatedSample: SettingsSample?
    @Published var someTextFieldValue: String = ""

    let model: SettingsModelProtocol

    init(model: SettingsModelProtocol) {
        self.model = model
    }

}

extension SettingsViewModel {

    func onAppear() async {
        defer {
            isProcessing = false
        }
        isProcessing = true
        do {
            try await Task.sleep(nanoseconds: 3000000000)
            samples = try await model.getSamples()
        } catch {
            errorMessage = "\(error)"
        }
    }

    func createSampleButtonTapped() async {
        defer {
            isProcessing = false
        }
        isProcessing = true
        do {
            latestCreatedSample = try await model.createSample(value: someTextFieldValue)
        } catch {
            errorMessage = "\(error)"
        }
    }

}
