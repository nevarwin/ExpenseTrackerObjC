//
//  SharedPermissionService.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 7/30/26.
//

import Foundation
import Photos
import UIKit

// MARK: - Protocol

protocol PermissionServiceProtocol: AnyObject {
    func openSettings()
    func checkPhotoLibraryPermission(completion: @escaping (PHAuthorizationStatus) -> Void)
}

// MARK: - Service

final class SharedPermissionService: PermissionServiceProtocol {

    private static var _instance: SharedPermissionService?

    static var instance: SharedPermissionService {
        guard let instance = _instance else {
            fatalError("Please configure SharedPermissionService first.")
        }
        return instance
    }

    static func configure() {
        guard _instance == nil else { return }
        _instance = SharedPermissionService()
    }

    private init() {}

    /// Opens the System Settings app for the current application.
    func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    /// Checks the photo library authorization status.
    func checkPhotoLibraryPermission(completion: @escaping (PHAuthorizationStatus) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus)
                }
            }
        } else {
            completion(status)
        }
    }
}
