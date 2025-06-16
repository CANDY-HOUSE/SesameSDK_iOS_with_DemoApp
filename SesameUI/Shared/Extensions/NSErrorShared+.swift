//
//  ErrorMessage.swift
//  sesame-sdk-test-app
//
//  Created by Wayne Hsiao on 2020/5/3.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
#if os(iOS)
import AWSMobileClientXCF
#else
import SesameWatchKitSDK
#endif

extension Error {
    
    public func errorDescription() -> String {
        #if os(iOS)
        
        if #available(iOS 12.0, *) {
            return "\((self as NSError).code) - \((self as NSError).errorDescription())"
        } else {
            return localizedDescription
        }
        
        #else
        guard let message = (self as NSError).userInfo["message"] as? String else {
            return (self as NSError).errorDescriptionForStatus()
        }
        L.d("message", message)
        return message
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
    
    static let noNetworkError = NSError(domain: "sesameUI", code: 0, userInfo: ["message": "co.candyhouse.sesame2.nonetwork".localized])

    #if os(iOS)
    public func errorDescription() -> String {
        if let error = self as? AWSMobileClientError {
            let printableMessage: String
            switch error {
            case .aliasExists(let message): printableMessage = message
            case .codeDeliveryFailure(let message): printableMessage = message
            case .codeMismatch(let message): printableMessage = message
            case .expiredCode(let message): printableMessage = message
            case .groupExists(let message): printableMessage = message
            case .internalError(let message): printableMessage = message
            case .invalidLambdaResponse(let message): printableMessage = message
            case .invalidOAuthFlow(let message): printableMessage = message
            case .invalidParameter(let message): printableMessage = message
            case .invalidPassword(let message): printableMessage = message
            case .invalidUserPoolConfiguration(let message): printableMessage = message
            case .limitExceeded(let message): printableMessage = message
            case .mfaMethodNotFound(let message): printableMessage = message
            case .notAuthorized(let message): printableMessage = message
            case .passwordResetRequired(let message): printableMessage = message
            case .resourceNotFound(let message): printableMessage = message
            case .scopeDoesNotExist(let message): printableMessage = message
            case .softwareTokenMFANotFound(let message): printableMessage = message
            case .tooManyFailedAttempts(let message): printableMessage = message
            case .tooManyRequests(let message): printableMessage = message
            case .unexpectedLambda(let message): printableMessage = message
            case .userLambdaValidation(let message): printableMessage = message
            case .userNotConfirmed(let message): printableMessage = message
            case .userNotFound(let message): printableMessage = message
            case .usernameExists(let message): printableMessage = message
            case .unknown(let message): printableMessage = message
            case .notSignedIn(let message): printableMessage = message
            case .identityIdUnavailable(let message): printableMessage = message
            case .guestAccessNotAllowed(let message): printableMessage = message
            case .federationProviderExists(let message): printableMessage = message
            case .cognitoIdentityPoolNotConfigured(let message): printableMessage = message
            case .unableToSignIn(let message): printableMessage = message
            case .invalidState(let message): printableMessage = message
            case .userPoolNotConfigured(let message): printableMessage = message
            case .userCancelledSignIn(let message): printableMessage = message
            case .badRequest(let message): printableMessage = message
            case .expiredRefreshToken(let message): printableMessage = message
            case .errorLoadingPage(let message): printableMessage = message
            case .securityFailed(let message): printableMessage = message
            case .idTokenNotIssued(let message): printableMessage = message
            case .idTokenAndAcceessTokenNotIssued(let message): printableMessage = message
            case .invalidConfiguration(let message): printableMessage = message
            case .deviceNotRemembered(let message): printableMessage = message
            @unknown default:
                fatalError()
            }
            return printableMessage.localizedCapitalized
        }
        guard let message = (self as NSError).userInfo["message"] as? String else {
            return localizedDescription
        }
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
