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
    private(set) var logInButtonTitle = "co.candyhouse.sesame-sdk-test-app.LogIn".localized
    private(set) var nameLabelText = "co.candyhouse.sesame-sdk-test-app.Email".localized
    private(set) var passwordLabelText = "co.candyhouse.sesame-sdk-test-app.Password".localized
    private(set) var signUpButtonTitle = "co.candyhouse.sesame-sdk-test-app.SignUp".localized
    private(set) var forgotPasswordButtonTitle = "co.candyhouse.sesame-sdk-test-app.ForgotPassword".localized
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
