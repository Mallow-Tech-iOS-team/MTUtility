//
//  MTPermission.swift
//  
//
//  Created by Dhanushkumar Kanagaraj on 07/10/22.
//

import SwiftUI

public enum MTPermissionError: LocalizedError {
    case camera(MTCameraManager.Error)
    case pushNotification(MTNotificationManager.Error)
}

extension MTPermissionError {
    public var errorDescription: String? {
        switch self {
            case let .camera(error):
                return error.errorDescription
            case let .pushNotification(error):
                return error.errorDescription
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
            case let .camera(error):
                return error.recoverySuggestion
            case let .pushNotification(error):
                return error.recoverySuggestion
        }
    }
}

// MARK: - Permission Alert

extension View {
    /// Shows the `setting` navigation alert for updating the permissions
    /// - Parameter error: takes the localised error and display the alert from error
    /// - Returns: alert if the binding has value
    public func permissionAlert(error: Binding<LocalizedError?>) -> some View {
        let localisedError = error.wrappedValue as? MTPermissionError
        if #available(iOS 15.0, *) {
            return alert(isPresented: .constant(localisedError != nil), error: localisedError) { _ in
                Button("Cancel") {
                    error.wrappedValue = nil
                }
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:])
                        error.wrappedValue = nil
                    } else {
                        error.wrappedValue = nil
                    }
                }
            } message: { error in
                Text(error.recoverySuggestion ?? "")
            }
        } else {
            return alert(isPresented: .constant(localisedError != nil)) {
                Alert(title: Text(localisedError?.errorDescription ?? ""),
                      message: Text(localisedError?.recoverySuggestion ?? ""),
                      primaryButton: .default(Text("Cancel"), action: {
                    error.wrappedValue = nil
                }),
                      secondaryButton: .default(Text("Settings"), action: {
                    if let url = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:])
                        error.wrappedValue = nil
                    } else {
                        error.wrappedValue = nil
                    }
                }))
            }
        }
    }
}

//
//public extension View {
//    func openCamera(isPresented: Binding<Bool>,
//                    onSuccess: @escaping () -> some View) -> some View {
//            let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
//        return self
////        } else {
////            return self
////        }
////        switch status {
////            case .notDetermined:
////                AVCaptureDevice.requestAccess(for: .video) { status in
////                    onSuccess()
////                }
////                return onSuccess()
////            case .authorized:
////                return onSuccess()
////            default:
////                return onSuccess()
////        }
//    }
//}
//
//struct OpenCamera: View {
//    var body: some View {
//        Text("Camera Opened")
//    }
//}
//
//struct MyView: View {
//    @State var present: Bool = false
//    @State var test = "sdsd"
//
//    var body: some View {
//        VStack{
//            Text(test)
////                .appVersionAlert(with: appVersion)
//
//            Button("dsf sdf dsf") {
////                appVersion.mockVersionAlert()
//            }
////            .openCamera(isPresented: $present) {
////                EmptyView()
////            }
//        }
//    }
//}
//
//struct MyView_Previews: PreviewProvider {
//    static var previews: some View {
//        MyView()
//    }
//}
