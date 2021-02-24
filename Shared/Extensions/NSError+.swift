//
//  ErrorMessage.swift
//  sesame-sdk-test-app
//
//  Created by Wayne Hsiao on 2020/5/3.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension Error {
    
    public func errorDescription() -> String {
        #if os(iOS)
        
        if #available(iOS 12.0, *) {
            return (self as NSError).errorDescription()
        } else {
            return localizedDescription
        }
        
        #else
        return (self as NSError).errorDescriptionForStatus()
        #endif
    }
    
}

extension NSError {
    
    static let noDeviceError = NSError(domain: "sesameUI", code: 0, userInfo: ["message": "no device"])
    
    static let getUserInfoError = NSError(domain: "sesameUI", code: 0, userInfo: ["message": "get user info failed"])
    
    static let retrieveQRCodeError = NSError(domain: "sesameUI", code: 0, userInfo: ["message": "Retrieve QR code failed"])
    
    static let angleTooCloseError = NSError(domain: "sesameUI", code: 0, userInfo: ["message": "co.candyhouse.sesame2.TooClose".localized])
    
    static let verificationCodeError = NSError(domain: "sesameUI", code: 0, userInfo: ["message": "Incorrect verification code"])
    
    static let signInFailedError = NSError(domain: "sesameUI", code: 0, userInfo: ["message": "SignIn failed"])
    
    static let invalidQRCode = NSError(domain: "SesameUI", code: 0, userInfo: ["message": "Invalid QR Code"])
    
    static let noSubId = NSError(domain: "SesameUI", code: 0, userInfo: ["message": "No sub id"])
    
    #if os(iOS)
    public func errorDescription() -> String {
        guard let message = (self as NSError).userInfo["message"] as? String else {
            return localizedDescription
        }
//        let domain = (self as NSError).domain
//        let statusCode = (self as NSError).code
        return message
    }
    #endif
    
    func errorDescriptionForStatus() -> String {
        switch code {
        case 403:
            return "No API Key"
        case 400:
            return "Bad request"
        case 404:
            return "Not found"
        case 502:
            return "Unknown error"
        case 401:
            return "Token error"
        case 480:
            return "Data parse failed"
        case 204:
            return "No content"
        case -1009:
            return "No network"
        default:
            return "Unknow"
        }
    }
}
