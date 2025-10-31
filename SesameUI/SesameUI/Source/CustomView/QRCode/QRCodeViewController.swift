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
    @IBOutlet weak var introductionDetailLabel: UILabel!
    
    // MARK: - Data Model
    private var device: CHDevice!
    private var user: CHUser!
    private var keyLevel: Int!
    private var qrCodeType: QRcodeType!
    private var qrCodeString: String?
    private var dismissHandler: (()->Void)?

    // MARK: - Life Cycle
    public override func viewDidLoad() {
        introductionDetailLabel.textColor = .secondaryLabelColor
        introductionLabel.textColor = .secondaryLabelColor
        super.viewDidLoad()
        view.backgroundColor = .white
        switch qrCodeType {
        case .matter:
            setupMatterViews()
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
    
    
    @objc func presentShareViewController(sender: UIView) {
        var imageName = ""
        if self.qrCodeType == .sesameKey || self.qrCodeType == .matter {
            imageName = "/\(self.device.deviceName).png"
        } else {
            imageName = "/\(self.user.subId.uuidString).png"
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

// MARK: for matter
extension QRCodeViewController {
    static func instanceWithMatterPairingCode(_ device: CHDevice, dismissHandler: (()->Void)? = nil) -> QRCodeViewController {
        let myQRCodeViewController = QRCodeViewController(nibName: "QRCodeViewController", bundle: nil)
        myQRCodeViewController.qrCodeType = .matter
        myQRCodeViewController.device = device
        myQRCodeViewController.dismissHandler = dismissHandler
        myQRCodeViewController.hidesBottomBarWhenPushed = true
        return myQRCodeViewController
    }
    
    func setupMatterViews() {
        introductionLabel.numberOfLines = 0
        deviceNameLabel.text = ""
        introductionLabel.text = ""
        introductionDetailLabel.text = ""
        generateMatterPairingQRCode { [weak self] yesOrNo in
            guard let self = self, yesOrNo else { return }
            self.deviceNameLabel.copyHandler = {
                return self.deviceNameLabel.text
            }
        }
        openPairingMode()
    }
    
    func generateMatterPairingQRCode(completion: @escaping (Bool) -> Void ) {
        guard let device = device as? CHHub3 else { return }
        ViewHelper.showLoadingInView(view: self.qrCodeImageView)
        device.getMatterParingCode { [weak self] result in
            guard let self = self else { return }
            executeOnMainThread {
                if case let .success(payload) = result {
                    ViewHelper.hideLoadingView(view: self.qrCodeImageView)
                    self.showShareButton()
                    self.deviceNameLabel.text = String(data: Data(payload.data.manualCode), encoding: .utf8)
                    self.qrCodeImageView.image = UIImage.generateQRCode(String(data: Data(payload.data.qrCode), encoding: .utf8)!, nil, .black)
                    completion(true)
                } else {
                    if case let .failure(err) = result {
                        self.view.makeToast(err.errorDescription())
                    }
                    completion(false)
                }
            }
        }
    }
    
    func openPairingMode() {
        guard let device = device as? CHHub3 else { return }
        device.openMatterPairingWindow { [weak self] result in
            guard let self = self else { return }
            executeOnMainThread {
                if case let .failure(err) = result {
                    self.view.makeToast(err.errorDescription())
                } else {
                    var period = 15
#if DEBUG
                    period = 3
#endif
                    self.introductionLabel.text = String(format: "co.candyhouse.hub3.matterPairingHint".localized, arguments: ["\(period)"])
                }
            }
        }
    }
}
