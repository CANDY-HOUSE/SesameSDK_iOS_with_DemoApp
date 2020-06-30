//
//  MyQrVc.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/11.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import UIKit
import SesameSDK

public class MyQRCodeViewController: CHBaseVC {
    
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var headImg: UIImageView!
    @IBOutlet weak var familyNameLabel: UILabel!
    @IBOutlet weak var givenNameLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var qrImg: UIImageView!
    
    var qrCodeType: QRcodeType?

    var familyName:String?
    var givenName:String?
    var mail:String?
    
    var ssm: CHSesameBleInterface?

    public override func viewDidLoad() {
        super.viewDidLoad()

        familyNameLabel.text = familyName
        givenNameLabel.text = givenName
        mailLabel.text  = mail
        mailLabel.adjustsFontSizeToFitWidth = true
        if let givenName = givenName {
            headImg.image = UIImage.makeLetterAvatar(withUsername: givenName)
        }
        
        switch qrCodeType {
        case .shareKey:
            generateShareKeyCode()

        case .none:
            generateInvitationCode()
            hintLabel.text = "Scan this QR code to add me on your contact".localStr
        }
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
        //todo  let qrCode = ssm.getkey()
        guard let ssm = ssm,
            let qrCode = ssm.encodedQRCode()
            else {
                return
        }
        
        qrImg.image = UIImage.generateQRCode(qrCode, UIImage.makeLetterAvatar(withUsername: ssm.originalDeviceName), .black)
        hintLabel.text = "Scan this QR code to share \(ssm.originalDeviceName)".localStr
    }
    
    public func generateInvitationCode() {
        DispatchQueue.main.async {
            ViewHelper.showLoadingInView(view: self.view)
        }
        
        CHAccountManager.shared.getInvitation() { result in
            DispatchQueue.main.async {
                ViewHelper.hideLoadingView(view: self.view)
            }
            
            switch result {
            case .success(let invitation):
                DispatchQueue.main.async {
                    self.qrImg.image = UIImage.generateQRCode(invitation.data.absoluteString, UIImage.makeLetterAvatar(withUsername: self.givenName ?? ""), .black)
                }
            case .failure(let error):
                L.d(ErrorMessage.descriptionFromError(error: error))
                DispatchQueue.main.async {
                    self.view.makeToast(ErrorMessage.descriptionFromError(error: error))
                }
            }
        }
    }
}
