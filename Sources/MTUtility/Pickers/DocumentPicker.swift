//
//  DocumentPicker.swift
//  
//
//  Created by Dhanushkumar Kanagaraj on 11/10/22.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

public struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var filePath: URL?
    @Environment(\.presentationMode) private var presentationMode
        
    var types: [UTType] = [.jpeg, .png, .pdf]
    
    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController,
                                context: Context) {
        // Do Nothing
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
}

extension DocumentPicker {
    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        public init(_ parent: DocumentPicker){
            self.parent = parent
        }
        
        public func documentPicker(_ controller: UIDocumentPickerViewController,
                            didPickDocumentsAt urls: [URL]) {
            parent.filePath = urls.first
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
