//
//  MyQRViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/21.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

public final class MyQRViewModel: ViewModel {
    public var statusUpdated: ViewStatusHandler?

    private var sesame2: CHSesame2?
    private(set) var familyName: String?
    private(set) var givenName: String?
    private(set) var mail: String?
    private(set) var qrCodeType: QRcodeType
    
    public private(set) var hintLabelText = "co.candyhouse.sesame-sdk-test-app.AddFriendByScan".localized
    
    public init(familyName: String? = nil,
                givenName: String? = nil,
                mail: String? = nil,
                sesame2: CHSesame2?,
                qrCodeType: QRcodeType) {
        self.familyName = familyName
        self.givenName = givenName
        self.mail = mail
        self.sesame2 = sesame2
        self.qrCodeType = qrCodeType
    }
    
    public var sesame2QRCode: String? {
        sesame2?.sesame2QRCodeURL()
    }
    
    public var deviceName: String? {
        sesame2?.deviceId!.uuidString
    }
}
