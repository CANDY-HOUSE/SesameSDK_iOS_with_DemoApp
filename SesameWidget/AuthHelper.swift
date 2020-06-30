//
//  SignInHelper.swift
//  locker
//
//  Created by YuHan Hsiao on 2020/5/11.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import AWSMobileClient

final class CHAuthHelper {
    static let shared = CHAuthHelper()
    
    public typealias WidgetInitCallback = (Bool) -> Void
    
    public func initialize(isLoggedIn: WidgetInitCallback? = nil) {
        AWSMobileClient.default().initialize { (userState, error) in
            if let userState = userState {
                switch userState {
                case .signedIn:
                    isLoggedIn?(true)
                default:
                    isLoggedIn?(false)
                }
            } else {
                isLoggedIn?(false)
            }
        }
        
        AWSMobileClient.default().addUserStateListener(self) { (userState, info) in
            switch (userState) {
            case .guest:
                L.d("🧕","user is in guest mode.")
            case .signedOut:
                L.d("🧕","user signed out")
            case .signedIn:
                L.d("🧕","user is signed in.")
            case .signedOutUserPoolsTokenInvalid:
                L.d("🧕","need to login again.")
            case .signedOutFederatedTokensInvalid:
                L.d("🧕","user logged in via federation, but currently needs new tokens")
            default:
                L.d("🧕","unsupported")
            }
        }
    }
    
    public func signOut() {
        AWSMobileClient.default().signOut()
    }
    
    public func signIn(username: String,
                       password: String,
                       completeHandler: @escaping (Bool)->Void) {
        AWSMobileClient
            .default()
            .signIn(username: username,
                    password: password) { result, error in
                        guard let _ = result else {
                            completeHandler(false)
                            return
                        }
                        CHUIKeychainManager.shared.setWidgetNeedSignIn(false)
                        CHAuthHelper.shared.signatureSigner()
                        completeHandler(true)
        }
    }
    
    func signatureSigner() {
//        CHAccountManager.shared.login(identityProvider: AWSMobileClient.default())
    }
}
