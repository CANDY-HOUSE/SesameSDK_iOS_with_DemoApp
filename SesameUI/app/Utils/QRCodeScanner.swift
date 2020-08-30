//
//  QRCodeScanner.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/29.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

class QRCodeScanner: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    static let shared = QRCodeScanner()
    
    var completionHandler: ((Result<String, Error>)->Void)?

//    func retrieveQRCodeFromImage(_ qrCodeImage: UIImage) {
//
//    }
    
    func retrieveQRCodeFromPhotoLibraryWithPresenter(_ presentingViewController: UIViewController, completionHandler: @escaping (Result<String, Error>)->Void) {
        self.completionHandler = completionHandler
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = false
        pickerController.mediaTypes = ["public.image", "public.movie"]
        pickerController.sourceType = .photoLibrary
        presentingViewController.present(pickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let qrcodeImg = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.originalImage.rawValue)] as? UIImage {
            let detector: CIDetector = CIDetector(ofType: CIDetectorTypeQRCode,
                                                  context: nil,
                                                  options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
            let ciImage: CIImage = CIImage(image:qrcodeImg)!
            var qrCodeLink = ""
            
            let features = detector.features(in: ciImage)
            for feature in features as! [CIQRCodeFeature] {
                qrCodeLink += feature.messageString!
            }
            DispatchQueue.main.async {
                self.completionHandler?(.success(qrCodeLink))
            }
        } else {
            L.d("Something went wrong")
            let error = NSError(domain: "", code: 0, userInfo: ["message": "Retrieve QR code failed"])
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
}
