//
//  MTAppVersion.swift
//  
//
//  Created by Dhanushkumar Kanagaraj on 03/10/22.
//

import SwiftUI
import UIKit

// FIXME: - Enum name is started in CAPS, check if it is OKAY for constant
public enum kAppVersion {
    public static let versionKey = "CFBundleShortVersionString"
    public static let alertIntervalKey = "AlertInterval"
    
    public static let iTunesURL = "itms-apps://itunes.apple.com/app/id"
    public static let OSType = "ios"
    
    public static let OSVersion = UIDevice.current.systemVersion
    
    public static let defaultAlertInterval: TimeInterval = 86400 // 1 Day -> (24 * 60 * 60)
}

public enum VersionState: String {
    case none = "none"
    case normal = "normal"
    case force = "force"
}

public class MTAppVersion: ObservableObject {
    /// App's ID from the App Store
    var appID: String?
    /// The App versioning URL path as `String`
    var URLPath: String?
    /// Subsequent alert interval time
    var alertInterval: TimeInterval = kAppVersion.defaultAlertInterval
    var headers: [MTHeader] = []
    var alertMessage: String = ""
    var appType: String?
    
    @Published public var showAlert: VersionState = .none
    
    // MARK: - Initialisers methods
    /// Initialisation method with appID and app version url string
    public init(appID: String,
                appType: String? = nil,
                URLPath: String,
                alertInterval: TimeInterval = kAppVersion.defaultAlertInterval,
                headers: [MTHeader] = []) {
        self.appID = appID
        self.appType = appType
        self.URLPath = URLPath
        self.alertInterval = alertInterval
        self.headers = headers
    }
    
    // MARK: - Custom methods
    
    /// Open the App in iTunes for update
    public func openInAppStore() {
        let appID = appID ?? ""
        if let iTunesURL: URL = URL(string: [kAppVersion.iTunesURL, appID].joined()) {
            guard UIApplication.shared.canOpenURL(iTunesURL) else { return }
            UIApplication.shared.open(iTunesURL, options: [:], completionHandler: nil)
        }
    }
    
    /// Check for app versioning
    public func checkAppVersioning() {
        guard let url = getAppVersioningURL() else {
            return
        }
        print("🔸 AppVersion URL - ", url)
        var request = URLRequest(url: url)
        for header in getHeaders() {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error == nil, let responseData = data { // Success
                do {
                    let version = try JSONDecoder().decode(MTVersion.self, from: responseData)
                    
                    guard let status = version.versionStatus.status?.lowercased() else {
                        print("Could not get status from JSON")
                        return
                    }
                    
                    let statusType = VersionState(rawValue: status) ?? .none
                    let message = version.versionStatus.message ?? ""
                    self.showAlert(for: statusType, message: message)
                    print("🔸 AppVersion ", statusType)
                } catch {
                    print("error trying to convert data to JSON")
                    return
                }
                
            } else { // Failure
                print("Error on App version check : \(error?.localizedDescription ?? "")")
            }
        }
        task.resume()
    }
    
    func getAppVersioningURL() -> URL? {
        guard let appVersioningPath = URLPath else {
            return nil
        }
        var urlComponents = URLComponents(string: appVersioningPath)
        let appVersionNumber = "\(UIApplication.appVersion ?? "")"
        
        // Add params
        let appVersion = URLQueryItem(name: "app_version", value: appVersionNumber)
        let platform = URLQueryItem(name: "platform", value: kAppVersion.OSType)
        let osVersion = URLQueryItem(name: "os_version", value: kAppVersion.OSVersion)
        if let appType {
            urlComponents?.queryItems?.append(URLQueryItem(name: "app_type", value: appType))
        }
        
        // TODO: - Check with mentor / backend team if device model is needed
        urlComponents?.queryItems = [appVersion, platform, osVersion]
        
        return urlComponents?.url
    }
    
    func getHeaders() -> [MTHeader] {
        headers
    }
}

// MARK: - Extensions

public extension MTAppVersion {
    // MARK: - Alert Methods
    func shouldDisplayAlert() -> Bool {
        if let alertDisplayedAt: Date = alertDisplayedAt() as Date? {
            let currentDate = Date()
            let displayedAlertInterval = currentDate.timeIntervalSince(alertDisplayedAt)
            
            if displayedAlertInterval < 0 || displayedAlertInterval <= alertInterval {
                return false
            } else {
                return true
            }
        } else {
            return true
        }
    }
    
    /// Show respective app versioning alert to the user based on the status received from the server
    internal func showAlert(for status: VersionState, message: String) {
        alertMessage = message
        Task { @MainActor in
            switch status {
                case .none:
                    showAlert = .none
                case .force:
                    showAlert = .force
                case .normal:
                    if shouldDisplayAlert() {
                        showAlert = .normal
                    }
            }
        }
    }
}

extension MTAppVersion {
    // MARK: - User default methods
    /// Save the date and time when we got `none` response from backend for app versioning check
    func updateDisplayedAlertTime() {
        UserDefaults.standard.set(Date(), forKey: kAppVersion.alertIntervalKey)
        UserDefaults.standard.synchronize()
    }
    
    /// Get the date and time details at when we show optional update alert
    func alertDisplayedAt() -> Date? {
        let alertDisplayedAt = UserDefaults.standard.object(forKey: kAppVersion.alertIntervalKey) as? Date
        return alertDisplayedAt
    }
}

public extension UIApplication {
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: kAppVersion.versionKey) as? String
    }
}

// MARK: - Models

struct MTVersion: Codable {
    let versionStatus: MTVersionStatus
    
    enum CodingKeys: String, CodingKey {
        case versionStatus = "version_status"
    }
}

struct MTVersionStatus: Codable {
    let status: String?
    let message: String?
}

public struct MTHeader: Codable {
    public let key: String
    public let value: String
    
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

// MARK: - SwiftUI Views

public extension View {
    @MainActor
    func appVersionAlert(with appVersion: MTAppVersion) -> some View {
        let message = appVersion.alertMessage
        var primaryButtonTitle: String = ""
        var secondaryButtonTitle: String = ""
         switch appVersion.showAlert {
            case .none:
                break
            case .normal:
                primaryButtonTitle = "Update"
                secondaryButtonTitle = "Later"
            case .force:
                primaryButtonTitle = "Update"
        }
        
        if #available(iOS 15.0, *) {
            return alert(Text(""),
                         isPresented: .constant(appVersion.showAlert != .none)) {
                switch appVersion.showAlert {
                case .none:
                    EmptyView() // Alert won't be presented in None
                case .normal:
                    Button(secondaryButtonTitle) {
                        appVersion.updateDisplayedAlertTime()
                        appVersion.showAlert = .none
                    }
                    Button(primaryButtonTitle) {
                        appVersion.openInAppStore()
                        appVersion.showAlert = .none
                    }
                case .force:
                    Button(primaryButtonTitle) {
                        appVersion.openInAppStore()
                        appVersion.showAlert = .none
                    }
                }
            } message: {
                Text(message)
            }
        } else {
            return alert(isPresented: .constant(appVersion.showAlert != .none)) {
                switch appVersion.showAlert {
                    case .none:
                        return Alert(title: Text("")) // Alert won't be presented in None
                    case .normal:
                        return Alert(title: Text(""),
                              message: Text(message),
                              primaryButton: .default(Text(primaryButtonTitle), action: {
                            appVersion.openInAppStore()
                            appVersion.showAlert = .none
                        }),
                              secondaryButton: .default(Text(secondaryButtonTitle), action: {
                            appVersion.updateDisplayedAlertTime()
                            appVersion.showAlert = .none
                        }))
                    case .force:
                        return Alert(title: Text(""),
                              message: Text(message),
                              dismissButton: .default(Text(primaryButtonTitle), action: {
                            appVersion.openInAppStore()
                            appVersion.showAlert = .none
                        }))
                }
            }
        }

    }
}

#warning("Move this to Readme for documentation")

struct MyView: View {
    @StateObject var appVersion = MTAppVersion(appID: "app_ID", URLPath: "https://www.urlpath.com")
    @State var selectedImage: UIImage? = nil
    @State var showPicker: Bool = false {
        didSet {
            list.append("Hola - \(showPicker)")
        }
    }
    @State var list: [String] = []
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        VStack{
            Text("Dummy Text")
            List(list, id: \.self) { val in
                Text(val)
            }
            Button("Image Picker") {
                showPicker = true
            }
            .sheet(isPresented: $showPicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
            }
        }
        .appVersionAlert(with: appVersion)
        .onChange(of: scenePhase) { scenePhase in
            switch scenePhase {
                case .active:
                    // Check the app versioning when app becomes ACTIVE
                    appVersion.checkAppVersioning()
                default:
                    break
            }
        }
    }
}

struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        MyView()
    }
}
