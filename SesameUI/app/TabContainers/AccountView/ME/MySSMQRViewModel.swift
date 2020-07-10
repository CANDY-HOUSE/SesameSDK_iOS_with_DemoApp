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

    private var ssm: CHSesame2?
    private(set) var familyName: String?
    private(set) var givenName: String?
    private(set) var mail: String?
    private(set) var qrCodeType: QRcodeType
    
    public private(set) var hintLabelText = "Scan this QR code to add me on your contact".localStr
    
    public init(familyName: String? = nil,
                givenName: String? = nil,
                mail: String? = nil,
                ssm: CHSesame2?,
                qrCodeType: QRcodeType) {
        self.familyName = familyName
        self.givenName = givenName
        self.mail = mail
        self.ssm = ssm
        self.qrCodeType = qrCodeType
    }
    
    public var ssmQRCode: String? {
        ssm?.ssmQRCodeURL()
    }
    
    public var deviceName: String? {
        ssm?.deviceId!.uuidString
    }
}
