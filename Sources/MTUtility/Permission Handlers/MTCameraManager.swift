//
//  MTCameraManager.swift
//  
//
//  Created by Dhanushkumar Kanagaraj on 10/10/22.
//

import AVFoundation

public class MTCameraManager {
    static let shared: MTCameraManager = MTCameraManager()
    
    public init() { }
    
    public func checkPermissions(for type: AVMediaType) async -> Result<Bool, MTPermissionError> {
        switch AVCaptureDevice.authorizationStatus(for: type) {
            case .notDetermined:
                guard await AVCaptureDevice.requestAccess(for: .video) else {
                    return .failure(.camera(.deniedOnRequestAccess))
                }
                return .success(true)
            case .restricted:
                return .failure(.camera(.restrictedAuthorisation))
            case .denied:
                return .failure(.camera(.deniedAuthorisation))
            case .authorized:
                return .success(true)
            @unknown default:
                return .failure(.camera(.unknownAuthorisation))
        }
    }
}

extension MTCameraManager {
    public enum Error: LocalizedError {
        case deniedOnRequestAccess
        case deniedAuthorisation
        case restrictedAuthorisation
        case unknownAuthorisation
        
        public var errorDescription: String? {
            switch self {
                case .deniedOnRequestAccess:
                    return "Camera access denied"
                case .deniedAuthorisation:
                    return "Camera access denied"
                case .restrictedAuthorisation:
                    return "Restricted camera access"
                case .unknownAuthorisation:
                    return "Unknown authorisation status for capture device"
            }
        }
        
        public var recoverySuggestion: String? {
            return "Allow the application to access your device camera!"
        }
    }
}
