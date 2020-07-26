//
//  SignUpViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/23.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import AWSMobileClient

public protocol SignUpViewModelDelegate {
    func backTapped()
}

public final class SignUpViewModel: ViewModel {
    public enum SignUpViewError: Error {
        case unknow
    }
    public enum SignUpType {
        case newUser, unconfirmedUser
    }
    
    public var statusUpdated: ViewStatusHandler?
    public var delegate: SignUpViewModelDelegate?
    public var confirmationCodeSendDestination: String? {
        signUpResult?.codeDeliveryDetails?.destination
    }
    public var confirmationCodeSendAlertTitle = "Code Sent"
    public var confirmationCodeSendAlertMessage: String {
        if let confirmationCodeSendDestination = confirmationCodeSendDestination {
            return "Code resent to \(confirmationCodeSendDestination)"
        } else {
            return "Code resent"
        }
    }
    
    private var signUpResult: SignUpResult? {
        didSet {
            if signUpResult?.signUpConfirmationState == .confirmed {
                self.signUpType = .newUser
            } else {
                self.signUpType = .unconfirmedUser
            }
        }
    }
    
    private(set) var backButtonImage = "icons_filled_close"
    private(set) var mailLabelText = "co.candyhouse.sesame-sdk-test-app.Email".localized
    private(set) var firstNameLabelText = "co.candyhouse.sesame-sdk-test-app.FirstName".localized
    private(set) var lastNameLabelText = "co.candyhouse.sesame-sdk-test-app.LastName".localized
    private(set) var passwordLabelText = "co.candyhouse.sesame-sdk-test-app.Password".localized
    private(set) var confirmationCodeLabelText = "co.candyhouse.sesame-sdk-test-app.VerificationCode".localized
    private(set) var signUpButtonTitle = "co.candyhouse.sesame-sdk-test-app.SignUp".localized
    private(set) var confirmationButtonTtitle = "co.candyhouse.sesame-sdk-test-app.VerificationCode".localized
    private(set) var resendEmailButtonTitle = "co.candyhouse.sesame-sdk-test-app.Re-sendVerificationCode".localized
    
    private(set) var email: String
    private(set) var password: String
    private(set) var signUpType: SignUpType
    
    init(email: String, password: String, signUpType: SignUpType = .newUser) {
        self.email = email
        self.password = password
        self.signUpType = signUpType
    }
    
    public func backTapped() {
        delegate?.backTapped()
    }
    
    public func signUpTapped(password: String,
                             email: String,
                             givenName: String,
                             familyName: String) {
        self.password = password
        self.email = email
        
        let userAttributes: [String: String] = [
            "email": email,
            "given_name": givenName,
            "family_name": familyName
        ]
        
        AWSMobileClient
            .default()
            .signUp(username: email,
                    password: password,
                    userAttributes: userAttributes) { result, error in
                            if let error = error as? AWSMobileClientError {
                                L.d(error.errorDescription())
                                self.statusUpdated?(.finished(.failure(error)))
                            } else if let result = result {
                                self.signUpResult = result
                                self.statusUpdated?(.finished(.success(result)))
                            } else {
                                self.statusUpdated?(.finished(.failure(SignUpViewError.unknow)))
                            }
        }
    }
    
    public func confirmUserTapped(email: String, confirmationCode: String) {
        self.email = email
        
        AWSMobileClient
            .default()
            .confirmSignUp(username: email,
                           confirmationCode: confirmationCode) { signUpResult, error in
                            if let error = error {
                                self.statusUpdated?(.finished(.failure(error)))
                            } else if let signUpResult = signUpResult {
                                self.signUpResult = signUpResult
                                self.statusUpdated?(.finished(.success(signUpResult.signUpConfirmationState)))
                            }
        }
    }
    
    public func reSendEmailTapped(email: String) {
        self.email = email
        
        AWSMobileClient
            .default()
            .resendSignUpCode(username: email) { signUpResult, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.statusUpdated?(.finished(.failure(error)))
                    } else if let result = signUpResult {
                        self.signUpResult = result
                        self.statusUpdated?(.finished(.success(result)))
                    } else {
                        self.statusUpdated?(.finished(.failure(SignUpViewError.unknow)))
                    }
                }
        }
    }
    
    public func hideNewUserContent() -> Bool {
        signUpType != .newUser
    }
    
    public func hideUnconfirmedUserContent() -> Bool {
        signUpType != .unconfirmedUser
    }
}
