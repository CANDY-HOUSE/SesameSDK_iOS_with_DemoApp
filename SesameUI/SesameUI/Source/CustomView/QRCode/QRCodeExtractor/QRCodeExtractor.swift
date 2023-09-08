//
//  QRCodeScanner.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/29.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

class QRCodeExtractor: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    static let shared = QRCodeExtractor()
    
    var completionHandler: ((Result<String, Error>)->Void)?
    
    func extractQRCodeFromImage(_ qrcodeImagg: UIImage) -> String {
        let detector: CIDetector = CIDetector(ofType: CIDetectorTypeQRCode,
                                              context: nil,
                                              options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
        let ciImage: CIImage = CIImage(image: qrcodeImagg)!
        var qrCodeLink = ""
        
        let features = detector.features(in: ciImage)
        for feature in features as! [CIQRCodeFeature] {
            qrCodeLink += feature.messageString!
        }
        return qrCodeLink
    }
    
    func presentImagePicker(_ presentingViewController: UIViewController, completionHandler: @escaping (Result<String, Error>)->Void) {
        self.completionHandler = completionHandler
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = false
        pickerController.mediaTypes = ["public.image", "public.movie"]
        pickerController.sourceType = .photoLibrary
        pickerController.navigationBar.isTranslucent = false
        pickerController.navigationBar.barTintColor = .white
        
        presentingViewController.present(pickerController, animated: true, completion: nil)
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let qrcodeImg = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.originalImage.rawValue)] as? UIImage {
            DispatchQueue.main.async {
                self.completionHandler?(.success(self.extractQRCodeFromImage(qrcodeImg)))
            }
        } else {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(NSError.retrieveQRCodeError))
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
}
