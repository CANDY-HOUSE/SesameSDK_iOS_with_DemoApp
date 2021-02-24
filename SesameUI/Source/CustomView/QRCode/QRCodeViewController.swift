//
//  QRCodeViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/10/16.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public class QRCodeViewController: CHBaseViewController {
    
    // MARK: - UI Components
    @IBOutlet weak var qrCodeContainerView: UIView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var introductionLabel: UILabel!
    
    // MARK: - Data Model
    private var device: CHDevice!
    private var qrCodeType: QRcodeType!
    private var qrCodeString: String?
    
    private var dismissHandler: (()->Void)?

    // MARK: - Life Cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        switch qrCodeType {
        case .sk:
            generateDeviceQRCode()
            deviceNameLabel.text = device.deviceName
            showShareButton()
        case .friend:
            break
        default:
            break
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissHandler?()
    }
    
    // MARK: - Methods
    func showShareButton() {
        let shareButton = UIBarButtonItem(title: "",
                                          style: .plain,
                                          target: self,
                                          action: #selector(self.presentShareViewController(sender:)))
        shareButton.image = UIImage.SVGImage(named: "icons_outlined_share")
        self.navigationItem.rightBarButtonItem = shareButton
    }
    
    func generateDeviceQRCode() {
        
        if ((device is CHSesame2) || (device is CHSesameBot) || (device is  CHSesameBike)) {
            introductionLabel.text = "co.candyhouse.sesame2.AddKeyByScan".localized
        } else if device is CHWifiModule2 {
            introductionLabel.text = "co.candyhouse.sesame2.AddWifiModule2KeyByScan".localized
        }
        
        let circleAppIcon = UIImage.CHUIImage(named: "AppIcon")!.circleImage()
        
        if let qrCodeString = qrCodeString {
            self.qrCodeImageView.image = UIImage.generateQRCode(qrCodeString,
                                                                circleAppIcon!,
                                                                .black)
        } else {
            ViewHelper.showLoadingInView(view: self.qrCodeImageView)
            device.qrCode { qrCodeURL in
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.qrCodeImageView)
                    if let qrCodeURL = qrCodeURL {
                        self.qrCodeImageView.image = UIImage.generateQRCode(qrCodeURL,
                                                                       circleAppIcon!,
                                                                       .black)
                    }
                }
            }
        }
    }
    
    @objc func presentShareViewController(sender: UIView) {
        var imageName = ""
        if self.qrCodeType == .sk {
            imageName = "/\(self.device.deviceName).png"
        }
        
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

// MARK: - Designated Initializer
extension QRCodeViewController {
    static func instanceWithCHDevice(_ device: CHDevice, qrCode: String, dismissHandler: (()->Void)? = nil) -> QRCodeViewController {
        let myQRCodeViewController = QRCodeViewController(nibName: "QRCodeViewController", bundle: nil)
        myQRCodeViewController.device = device
        myQRCodeViewController.qrCodeType = .sk
        myQRCodeViewController.qrCodeString = qrCode
        myQRCodeViewController.dismissHandler = dismissHandler
        return myQRCodeViewController
    }
    
    static func instanceWithCHDevice(_ device: CHDevice, dismissHandler: (()->Void)? = nil) -> QRCodeViewController {
        let myQRCodeViewController = QRCodeViewController(nibName: "QRCodeViewController", bundle: nil)
        myQRCodeViewController.device = device
        myQRCodeViewController.qrCodeType = .sk
        myQRCodeViewController.dismissHandler = dismissHandler
        return myQRCodeViewController
    }
    
    static func instanceWithUser(_ dismissHandler: (()->Void)? = nil) -> QRCodeViewController {
        let myQRCodeViewController = QRCodeViewController(nibName: "QRCodeViewController", bundle: nil)
        myQRCodeViewController.qrCodeType = .friend
        myQRCodeViewController.dismissHandler = dismissHandler
        myQRCodeViewController.hidesBottomBarWhenPushed = true
        return myQRCodeViewController
    }
}
