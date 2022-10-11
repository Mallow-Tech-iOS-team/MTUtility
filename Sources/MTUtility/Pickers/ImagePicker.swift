//
//  ImagePicker.swift
//  
//
//  Created by Dhanushkumar Kanagaraj on 11/10/22.
//

import SwiftUI
import UIKit

/*
 From iOS 16, use `PhotosPicker` - https://developer.apple.com/documentation/photokit/photospicker/
 */

@available(iOS, deprecated: 16.0, message: "Use PhotosPicker instead")
public struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        
        return imagePicker
    }
    
    public func updateUIViewController(_ uiViewController: UIImagePickerController,
                                       context: Context) {
        // Do Nothing
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
 
extension ImagePicker {
    public class Coordinator: NSObject, UIImagePickerControllerDelegate,
                              UINavigationControllerDelegate {
        var parent: ImagePicker
        
        public init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        public func imagePickerController(_ picker: UIImagePickerController,
                                          didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
