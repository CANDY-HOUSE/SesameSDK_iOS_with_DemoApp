//
//  LoginViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/23.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import AWSMobileClient
import SesameSDK

public protocol LogInViewModelDelegate {
    func forgotPasswordTapped(email: String)
    func signUpTapped(email: String, password: String, signUpType: SignUpViewModel.SignUpType)
    func dismissTapped()
}

public final class LogInViewModel: ViewModel {
    enum SingInError: Error {
        case userNamePasswordError
        case notConfirmed
        case unknow
    }
    
    public var statusUpdated: ViewStatusHandler?
    public var delegate: LogInViewModelDelegate?
    
    private(set) var logInImage = "loginlogo"
    private(set) var subLogInImage = "loginsubhint"
    private(set) var logInButtonTitle = "Log In".localStr
    private(set) var nameLabelText = "Email".localStr
    private(set) var passwordLabelText = "Password".localStr
    private(set) var signUpButtonTitle = "Sign up".localStr
    private(set) var forgotPasswordButtonTitle = "Forgot password".localStr
    private(set) var closeImage = "icons_filled_close"
    private(set) var signUpType: SignUpViewModel.SignUpType?
    
    public func logInDidPressed(userName: String, password: String) {
        statusUpdated?(.loading)
        
        AWSMobileClient.default().signIn(username: userName,
                                         password: password,
                                         validationData:nil) { result, error in
            if let error = error  {
                if let awsError = error as? AWSMobileClientError {
                    switch awsError {
                    case .userNotConfirmed(message: _):
                        self.signUpType = .unconfirmedUser
                        self.statusUpdated?(.finished(.failure(awsError)))
                    default:
                        self.statusUpdated?(.finished(.failure(awsError)))
                    }
                }
            } else {
                L.d("帳號密碼登入成功")
                DispatchQueue.main.async {
                    CHUIKeychainManager.shared.setUsername(userName,
                                                           password: password)
                    // TODO: should be move to `checkNameAndBindCHServer`, waiting for `CHAccountManager.shared.updateMyProfile` to be fixed.
                    self.statusUpdated?(.finished(.success("")))
                    self.checkNameAndBindCHServer()
                }
            }
        }
    }
    
    func checkNameAndBindCHServer() {
            AWSMobileClient.default().getUserAttributes { userAttributes, error in

                if let error = error {
                    L.d(error.errorDescription())
                } else if let userAttributes = userAttributes {
                    do {
                        let user = try User.userFromAttributes(userAttributes)
//                        CHAccountManager.shared.updateMyProfile(
//                            first_name:user.givenName,
//                            last_name:user.familyName
//                        ) { result in
//                            switch result {
//                            case .success(let candyUUID):
//                                L.d(candyUUID.data as Any)
//                                self.statusUpdated?(.finished(.success(true)))
//                            case .failure(let error):
//                                L.d(ErrorMessage.descriptionFromError(error: error))
//                                self.statusUpdated?(.finished(.failure(error)))
//                            }
//                        }
                    } catch {
                        L.d(error.errorDescription())
                        self.statusUpdated?(.finished(.failure(error)))
                    }
                } else {
                    L.d("All Null")
                    self.statusUpdated?(.finished(.failure(SingInError.unknow)))
                }
            }
        }
    
    public func forgotPasswordTapped(email: String) {
        delegate?.forgotPasswordTapped(email: email)
    }
    
    public func signUpTapped(email: String, password: String) {
        delegate?.signUpTapped(email: email,
                               password: password,
                               signUpType: signUpType ?? .newUser)
    }
    
    public func dismissTapped() {
        delegate?.dismissTapped()
    }
}
