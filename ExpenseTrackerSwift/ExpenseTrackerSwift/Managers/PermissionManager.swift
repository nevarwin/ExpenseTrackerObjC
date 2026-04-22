import Foundation
import Photos
import UIKit

final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    private init() {}
    
    /// Opens the System Settings app for the current application.
    func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    /// Checks the photo library authorization status.
    /// Note: PhotosPicker (SwiftUI) handles picking without full library access, 
    /// but this is useful if we need to check if the user has explicitly blocked the app.
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
