//
//  MyQrVc.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/11.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public class Sesame2QRCodeViewController: CHBaseViewController {
    // MARK: - UI Components
    @IBOutlet weak var qrCodeContainerView: UIView!
    @IBOutlet weak var sesame2NameLabel: UILabel!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var introductionLabel: UILabel!
    
    // MARK: - Data Model
    var sesame2: CHSesame2!

    // MARK: - Life Cycle
    public override func viewDidLoad() {
        super.viewDidLoad()

        let device = Sesame2Store.shared.getSesame2Property(sesame2)
        let deviceName = device?.name ?? sesame2.deviceId.uuidString
        
        sesame2NameLabel.text = deviceName
        
        generateQRCode()
        
        let shareButton = UIBarButtonItem(title: "",
                                          style: .plain,
                                          target: self,
                                          action: #selector(presentShareViewController(sender:)))
        shareButton.image = UIImage.SVGImage(named: "icons_outlined_share")
        navigationItem.rightBarButtonItem = shareButton
    }
    
    // MARK: - Methods
    public func generateQRCode() {
        guard let qrCode = sesame2.sesame2QRCodeURL()
            else {
                return
        }
        
        let circleAppIcon = UIImage.CHUIImage(named: "AppIcon")!.circleImage()
        qrCodeImageView.image = UIImage.generateQRCode(qrCode,
                                                       circleAppIcon!,
                                                       .black)
        introductionLabel.text = "co.candyhouse.sesame-sdk-test-app.AddKeyByScan".localized
    }
    
    @objc func presentShareViewController(sender: UIView) {
        DispatchQueue.main.async {
            let device = Sesame2Store.shared.getSesame2Property(self.sesame2)
            let deviceName = device?.name ?? self.sesame2.deviceId.uuidString
            let imageName = "/\(deviceName).png"
            var documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                             .userDomainMask, true)[0]
            documentsDirectoryPath += imageName
            
            let renderer = UIGraphicsImageRenderer(bounds: self.qrCodeContainerView.bounds)
            let image = renderer.image { rendererContext in
                self.qrCodeContainerView.layer.render(in: rendererContext.cgContext)
            }
            
            try! image.pngData()!.write(to: URL(fileURLWithPath: documentsDirectoryPath))
            let fileURL = URL(fileURLWithPath: documentsDirectoryPath)
            let objectsToShare = [fileURL]
            
            let activityViewController = UIActivityViewController(activityItems: objectsToShare as [Any], applicationActivities: nil)
            activityViewController.excludedActivityTypes = [.assignToContact,
                                                            .openInIBooks,
                                                            .addToReadingList]
            activityViewController.completionWithItemsHandler = { activity, success, items, error in
                
            }
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.popoverPresentationController?.permittedArrowDirections = .up
            activityViewController.popoverPresentationController?.sourceRect = .init(x: self.view.bounds.maxX,
                                                                                     y: 60,
                                                                                     width: 0,
                                                                                     height: 0)
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
}

// MARK: - Designated Initializer
extension Sesame2QRCodeViewController {
    static func instanceWithSesame2(_ sesame2: CHSesame2) -> Sesame2QRCodeViewController {
        let myQRCodeViewController = Sesame2QRCodeViewController(nibName: "Sesame2QRCodeViewController", bundle: nil)
        myQRCodeViewController.sesame2 = sesame2
        return myQRCodeViewController
    }
}
