//
//  Sesame2QRCode.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/29.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

public enum QRcodeType: String {
    case sharedKey
}

enum CHQRKey: String {
    case QREventType = "t"
    case QRValue = "invite"
}
