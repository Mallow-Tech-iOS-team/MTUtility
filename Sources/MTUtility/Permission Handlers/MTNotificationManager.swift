//
//  MTNotificationManager.swift
//  
//
//  Created by Dhanushkumar Kanagaraj on 07/02/23.
//

import NotificationCenter

public class MTNotificationManager {
    public static let shared: MTNotificationManager = MTNotificationManager()
    
    public init() { }
    
    // MARK: - Custom Methods
    @MainActor
    public func requestAuthorization(for delegate: any UNUserNotificationCenterDelegate) {
        let userNotification = UNUserNotificationCenter.current()
        userNotification.delegate = delegate
        userNotification.requestAuthorization(options: [.sound, .badge, .alert]) { status, _ in
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    @MainActor
    public func configurePushNotification(for delegate: any UNUserNotificationCenterDelegate) async throws {
        let notification = await UNUserNotificationCenter.current().notificationSettings()
        switch notification.authorizationStatus {
            case .notDetermined:
                requestAuthorization(for: delegate)
            case .denied:
                throw MTPermissionError.pushNotification(.deniedAuthorisation)
            case .authorized:
                requestAuthorization(for: delegate)
            case .provisional, .ephemeral:
                // we are not using these in Miton, so throwing error for this
                // FIXME: - Check and handle Provisional and Ephemeral
                throw MTPermissionError.pushNotification(.unknownAuthorisation)
            @unknown default:
                throw MTPermissionError.pushNotification(.unknownAuthorisation)
        }
    }
}

extension MTNotificationManager {
    public enum Error: LocalizedError {
        case deniedAuthorisation
        case unknownAuthorisation
        
        public var errorDescription: String? {
            switch self {
                case .deniedAuthorisation:
                    return "Notification access denied"
                case .unknownAuthorisation:
                    return "Unknown authorisation status for Notification"
            }
        }
        
        public var recoverySuggestion: String? {
            return "Allow the application to receive Push Notifications!"
        }
    }
}
