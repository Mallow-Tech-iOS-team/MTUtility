//
//  MTAlert.swift
//  
//
//  Created by Dhanushkumar Kanagaraj on 13/10/22.
//

import Foundation
import SwiftUI

// MARK: - Alert Manager
public final class MTAlertManager {
    public static let shared = MTAlertManager()
    
    public private(set) var currentErrorAlerts: [LocalizedError] = []
    public private(set) var currentActionableAlerts: [MTAlert] = []
    
    // MARK: - Custom Methods
    public func appendErrorAlert(error: LocalizedError) {
        currentErrorAlerts.append(error)
    }
    
    public func appendActionableAlerts(actionableAlert: MTAlert) {
        currentActionableAlerts.append(actionableAlert)
    }
    
    public func isAlreadyPresentingAlert() -> Bool {
        !(currentErrorAlerts.isEmpty && currentActionableAlerts.isEmpty)
    }
    
    public func isAlreadyPresenting(in alertFrom: String) -> Bool {
        currentActionableAlerts.first?.alertFrom == alertFrom
    }
    
    public func isAlreadyPresenting<T: LocalizedError & Equatable>(of errorAlert: T?) -> Bool {
        guard let firstCurrentErrorAlerts = currentErrorAlerts.first, let errorAlert else { return false }
        return type(of: errorAlert.self) == type(of: firstCurrentErrorAlerts.self)
    }
    
    public func resetAlerts() {
        currentErrorAlerts = []
        currentActionableAlerts = []
    }
}

// MARK: - Protocol
public protocol MTAlertActionProtocol: Sendable {
    var alertAction: MTAlert? { get }
}

public protocol MTActionableAlert: ObservableObject, Sendable {
    associatedtype ActionableAlert: MTAlertActionProtocol
    
    @MainActor var alert: ActionableAlert? { get set }
    
    func leftAlertAction() async
    func rightAlertAction() async
}

extension MTActionableAlert {
    public func leftAlertAction() async {
        // Do Nothing
    }
    
    public func rightAlertAction() async {
        // Do Nothing
    }
    
    @MainActor
    public func updateAlert(_ alert: ActionableAlert) async {
        self.alert = alert
    }
}

// MARK: - Model
public struct MTAlert: @unchecked Sendable, Equatable {
    public let title: LocalizedStringKey?
    public let message: LocalizedStringKey?
    public let leftButtonText: LocalizedStringKey?
    public let rightButtonText: LocalizedStringKey?
    public let alertFrom: String
    
    // MARK: - Initialiser
    public init(title: LocalizedStringKey?,
                message: LocalizedStringKey?,
                leftButtonText: LocalizedStringKey?,
                rightButtonText: LocalizedStringKey?,
                alertFrom: String = #fileID) {
        self.title = title
        self.message = message
        self.leftButtonText = leftButtonText
        self.rightButtonText = rightButtonText
        self.alertFrom = alertFrom
    }
}

public struct MTEmptyAlertAction: MTAlertActionProtocol {
    public var alertAction: MTAlert?
}

@available(iOS 15.0, *)
extension View {
    // MARK: - Actionable Alert
    @MainActor
    public func alert<T: MTAlertActionProtocol>(bindingAlert: Binding<T?>,
                                                leftButtonAction: @escaping () async -> Void,
                                                rightButtonAction: @escaping () async -> Void) -> some View {
        let alertAction = bindingAlert.wrappedValue?.alertAction
        return alert(Text(alertAction?.title ?? ""),
                     isPresented: .constant(bindingAlert.wrappedValue != nil)) {
            if let leftButtonText = alertAction?.leftButtonText {
                Button(leftButtonText) {
                    Task { @MainActor in
                        // Alert is removed immediately after the button is tapped
                        MTAlertManager.shared.resetAlerts()
                        await leftButtonAction()
                        // Updating the alert value only after the action is performed
                        bindingAlert.wrappedValue = nil
                    }
                }
            }
            if let rightButtonText = alertAction?.rightButtonText {
                Button(rightButtonText) {
                    Task { @MainActor in
                        // Alert is removed immediately after the button is tapped
                        MTAlertManager.shared.resetAlerts()
                        await rightButtonAction()
                        // Updating the alert value only after the action is performed
                        bindingAlert.wrappedValue = nil
                    }
                }
            }
        } message: {
            Text(alertAction?.message ?? "")
        }
        // FIXME: - Temporary solution for the below mentioned problem
        // When an alert is already presented, we can't show new alert as it is system behaviour.
        // And the state of the current alert's variable is also not changed. Due to this after the
        // presented alert is dismissed, when a new alert of same type occurs, the alert won't be
        // shown. Because the value is not changed and SwiftUI can't recognise and won't refresh the view
        .onChange(of: alertAction) { alertAction in
            let isAlreadyPresenting = MTAlertManager.shared.isAlreadyPresentingAlert()
            switch isAlreadyPresenting {
            case true:
                // When alert type of same binding variable is updated instead of nil, Fallback
                guard !MTAlertManager.shared.isAlreadyPresenting(in: alertAction?.alertFrom ?? "") else { return }
                // If some other alert is presenting already, cancel the current alert and update its state
                if alertAction != nil {
                    bindingAlert.wrappedValue = nil
                }
            case false:
                if let alertAction {
                    MTAlertManager.shared.appendActionableAlerts(actionableAlert: alertAction)
                }
            }
        }
    }
}
 
extension View {
    // MARK: - Error Alert
    public func errorAlert<T: LocalizedError & Equatable>(error: Binding<T?>,
                                                          buttonTitle: String = "OK") -> some View {
        let localisedError = error.wrappedValue
        if #available(iOS 15.0, *) {
            return alert(
                isPresented: .constant(localisedError != nil),
                error: localisedError
            ) { _ in
                Button(buttonTitle) {
                    MTAlertManager.shared.resetAlerts()
                    error.wrappedValue = nil
                }
            } message: { error in
                Text(error.recoverySuggestion ?? "")
            }
            // FIXME: - Temporary solution for the below mentioned problem
            // When an alert is already presented, we can't show new alert as it is system behaviour.
            // And the state of the current alert's variable is also not changed. Due to this after the
            // presented alert is dismissed, when a new alert of same type occurs, the alert won't be
            // shown. Because the value is not changed and SwiftUI can't recognise and won't refresh the view
            .onChange(of: localisedError) { localisedError in
                let isAlreadyPresenting = MTAlertManager.shared.isAlreadyPresentingAlert()
                switch isAlreadyPresenting {
                case true:
                    // When error alert type of same binding variable is updated instead of nil, Fallback
                    guard !MTAlertManager.shared.isAlreadyPresenting(of: localisedError) else { return }
                    // If some other alert is presenting already, cancel the current alert and update its state
                    if localisedError != nil {
                        error.wrappedValue = nil
                    }
                case false:
                    if let localisedError {
                        MTAlertManager.shared.appendErrorAlert(error: localisedError)
                    }
                }
            }
        } else {
            return alert(isPresented: .constant(localisedError != nil)) {
                Alert(title: Text(localisedError?.errorDescription ?? ""),
                      message: Text(localisedError?.recoverySuggestion ?? ""),
                      dismissButton: .cancel(Text(buttonTitle)) {
                    error.wrappedValue = nil
                    // MARK: - Update the error alert if handled the on Change
//                    MTAlertManager.shared.removeLastErrorAlert()
                })
            }
            // FIXME: - Build fails while adding this code, Check and attend the 
//            .onChange(of: localisedError) { localisedError in
//                let isAlreadyPresenting = MTAlertManager.shared.isAlreadyPresentingAlert()
//                switch isAlreadyPresenting {
//                    case true:
//                        // If some other alert is presenting already, cancel the current alert and update its state
//                        if localisedError != nil {
//                            error.wrappedValue = nil
//                        }
//                    case false:
//                        if let localisedError {
//                            MTAlertManager.shared.appendErrorAlert(error: localisedError)
//                        }
//                }
//            }
        }
    }
}
