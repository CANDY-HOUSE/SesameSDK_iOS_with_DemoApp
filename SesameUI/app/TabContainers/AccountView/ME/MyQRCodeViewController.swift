//
//  MyQrVc.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/11.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public class MyQRCodeViewController: CHBaseViewController {
    
    @IBOutlet weak var qrCodeContainerView: UIView!
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var headImg: UIImageView!
    @IBOutlet weak var familyNameLabel: UILabel!
    @IBOutlet weak var givenNameLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var qrImg: UIImageView!
    
    var viewModel: MyQRViewModel!
    
    var sesame2: CHSesame2?

    public override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "MyQRViewModel should not be nil")

//        familyNameLabel.text = viewModel.familyName
        givenNameLabel.text = viewModel.deviceName
        mailLabel.text  = viewModel.mail
        mailLabel.adjustsFontSizeToFitWidth = true
        
        if let givenName = viewModel.givenName {
            headImg.image = UIImage.makeLetterAvatar(withUsername: givenName)
        }
        
        switch viewModel.qrCodeType {
        case .shareKey:
            generateShareKeyCode()

        default:
            generateInvitationCode()
            hintLabel.text = viewModel.hintLabelText
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: viewModel.shareText,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(share(sender:)))
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarTintColor(navigationBarTintColor.current)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setupNavigationBarTintColor(navigationBarTintColor.previous)
    }
    
    public func generateShareKeyCode() {
        //todo  let qrCode = sesame2.getkey()
        guard let qrCode = viewModel.sesame2QRCode
            else {
                return
        }
        
        let appIcon = UIImage(named: "AppIcon")!
        UIGraphicsBeginImageContextWithOptions(appIcon.size, false, appIcon.scale)
        let rect = CGRect(origin: .zero, size: appIcon.size)
        UIBezierPath(roundedRect: rect, cornerRadius: appIcon.size.height/2).addClip()
        appIcon.draw(in: rect)
        let circleAppIcon = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        qrImg.image = UIImage.generateQRCode(qrCode,
                                             circleAppIcon!,
                                             .black)
        hintLabel.text = "co.candyhouse.sesame-sdk-test-app.AddKeyByScan".localized
    }
    
    public func generateInvitationCode() {
        DispatchQueue.main.async {
            ViewHelper.showLoadingInView(view: self.view)
        }
    }
    
    @objc func share(sender: UIView) {
        let imageName = "/\(viewModel.deviceName!).png"
        var documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                         .userDomainMask, true)[0]
        documentsDirectoryPath += imageName
        
        let renderer = UIGraphicsImageRenderer(bounds: qrCodeContainerView.bounds)
        let image = renderer.image { rendererContext in
            qrCodeContainerView.layer.render(in: rendererContext.cgContext)
        }

        try! image.pngData()!.write(to: URL(fileURLWithPath: documentsDirectoryPath))
        let fileURL = URL(fileURLWithPath: documentsDirectoryPath)
        let objectsToShare = [fileURL]
        
        let activityViewController = UIActivityViewController(activityItems: objectsToShare as [Any], applicationActivities: nil)
        let excludedActivities: [UIActivity.ActivityType] = [
            .postToTwitter,
            .postToFacebook,
            .postToWeibo,
            .message,
            .mail,
            .print,
            .copyToPasteboard,
            .assignToContact,
            .saveToCameraRoll,
            .addToReadingList,
            .postToFlickr,
            .postToVimeo,
            .postToTencentWeibo
        ]
        activityViewController.excludedActivityTypes = excludedActivities
        activityViewController.completionWithItemsHandler = { activity, success, items, error in
            
        }
        activityViewController.popoverPresentationController?.sourceView = view
        activityViewController.popoverPresentationController?.permittedArrowDirections = .up
        activityViewController.popoverPresentationController?.sourceRect = .init(x: view.bounds.maxX,
                                                                                 y: 60,
                                                                                 width: 0,
                                                                                 height: 0)
        present(activityViewController, animated: true, completion: nil)
    }
}
