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
}
