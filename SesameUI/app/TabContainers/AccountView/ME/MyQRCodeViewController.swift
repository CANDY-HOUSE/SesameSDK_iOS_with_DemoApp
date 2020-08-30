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

        familyNameLabel.text = viewModel.familyName
        givenNameLabel.text = viewModel.givenName
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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share",
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
        
        qrImg.image = UIImage.generateQRCode(qrCode, UIImage.makeLetterAvatar(withUsername: viewModel.deviceName ?? ""), .black)
        hintLabel.text = "Scan this QR code to share \(viewModel.deviceName ?? "")".localized
    }
    
    public func generateInvitationCode() {
        DispatchQueue.main.async {
            ViewHelper.showLoadingInView(view: self.view)
        }
    }
    
    @objc func share(sender: UIView) {
        let objectsToShare = [qrImg.image]
        let activityViewController = UIActivityViewController(activityItems: objectsToShare as [Any], applicationActivities: nil)
        let excludedActivities: [UIActivity.ActivityType] = [
            UIActivity.ActivityType.postToTwitter,
            UIActivity.ActivityType.postToFacebook,
            UIActivity.ActivityType.postToWeibo,
            UIActivity.ActivityType.message,
            UIActivity.ActivityType.mail,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.copyToPasteboard,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToTencentWeibo
        ]
        activityViewController.excludedActivityTypes = excludedActivities
        activityViewController.completionWithItemsHandler = { activity, success, items, error in
            
        }
        present(activityViewController, animated: true, completion: nil)
    }
}
