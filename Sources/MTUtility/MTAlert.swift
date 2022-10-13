//
//  MTAlert.swift
//  
//
//  Created by Dhanushkumar Kanagaraj on 13/10/22.
//

import SwiftUI

extension View {
    func errorAlert<T: LocalizedError>(error: Binding<T?>,
                                       buttonTitle: String = "OK") -> some View {
        let localisedError = error.wrappedValue
        if #available(iOS 15.0, *) {
            return alert(isPresented: .constant(localisedError != nil), error: localisedError) { _ in
                Button(buttonTitle) {
                    error.wrappedValue = nil
                }
            } message: { error in
                Text(error.recoverySuggestion ?? "")
            }
        } else {
            return alert(isPresented: .constant(localisedError != nil)) {
                Alert(title: Text(localisedError?.errorDescription ?? ""),
                      message: Text(localisedError?.recoverySuggestion ?? ""),
                      dismissButton: .cancel(Text(buttonTitle)) {
                    error.wrappedValue = nil
                })
            }
        }
    }
}
