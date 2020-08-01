//
//  MeViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import AWSMobileClient
import SesameSDK
import WatchConnectivity

public protocol MeViewModelDelegate {
    func scanViewTapped()
    func newSesameTapped()
    func loginRegisterTapped()
    func showMyQRCodeTappe()
}

public final class MeViewModel: ViewModel {
    public var statusUpdated: ViewStatusHandler?
    public var delegate: MeViewModelDelegate?
    
    private(set) var givenName: String?
    private(set) var familyName: String?
    private(set) var avatarImage: String?
    private(set) var email: String?
    
    private(set) var logoutButtonTitle = "co.candyhouse.sesame-sdk-test-app.LogOut".localized
    private(set) var changeAccountNameText = "co.candyhouse.sesame-sdk-test-app.EditName".localized
    private(set) var rightButtonImage = "icons_outlined_addoutline"
    private(set) var qrCodeIcon = "icons_outlined_qr-code"
    private(set) var logOutButtonTitle = "co.candyhouse.sesame-sdk-test-app.LogOut".localized
    
    var isSignedIn: Bool {
        AWSMobileClient.default().isSignedIn
    }
    
    init() {
        AWSMobileClient.default().addUserStateListener(self) { (status, info) in
            switch status {
            case .signedIn:
                self.statusUpdated?(.update(nil))
            case .signedOut:
                self.statusUpdated?(.update(nil))
            case .guest:
                self.statusUpdated?(.update(nil))
            case .signedOutFederatedTokensInvalid:
                self.statusUpdated?(.update(nil))
            case .signedOutUserPoolsTokenInvalid:
                self.statusUpdated?(.update(nil))
            case .unknown:
                self.statusUpdated?(.update(nil))
            }
        }
    }
    
    func logOutTapped() {
        AWSMobileClient.default().signOut()
        CHUIKeychainManager.shared.setWidgetNeedSignIn(true)
        CHUIKeychainManager.shared.removeUsernameAndPassword()
    }
    
    func modifyAccountNameTapped(lastName: String, firstName: String) {
        let updateUserAttribute = [
            "given_name": firstName,
            "family_name": lastName
        ]
        
        AWSMobileClient.default().updateUserAttributes(attributeMap: updateUserAttribute) { deliveryDetails, error in
            if let error = error {
                self.statusUpdated?(.finished(.failure(error)))
            } else {
                self.statusUpdated?(.finished(.success(true)))
            }
        }
    }
    
    func loginRegisterTapped() {
        delegate?.loginRegisterTapped()
    }
    
    func showQRCodeTapped() {
        delegate?.showMyQRCodeTappe()
    }
}

extension MeViewModel {
    public func popUpMenuTappedOnItem(_ item: PopUpMenuItem) {
        switch item.type {
        case .addFriends:
            break
        case .addDevices:
            delegate?.newSesameTapped()
        case .receiveKey:
            delegate?.scanViewTapped()
        }
    }
    
    public func viewWillAppear() {
        setLoginName()
    }
    
    private func setLoginName() {
        if isSignedIn {
            familyName = UserDefaults.standard.string(forKey: "family_name")
            givenName  = UserDefaults.standard.string(forKey: "given_name")
            avatarImage = givenName
            email = UserDefaults.standard.string(forKey: "email")
            statusUpdated?(.finished(.success(true)))
            
            AWSMobileClient.default().getUserAttributes { userAttributes, error in

                if let error = error {
                    L.d(error.errorDescription())
                    self.statusUpdated?(.finished(.failure(error)))
                } else if let userAttributes = userAttributes {
                    do {
                        let user = try User.userFromAttributes(userAttributes)
                            
                        DispatchQueue.main.async {
                            UserDefaults.standard.setValue(user.familyName, forKey: "family_name")
                            UserDefaults.standard.setValue(user.givenName, forKey: "given_name")
                            UserDefaults.standard.setValue(user.email, forKey: "email")
                            
                            self.familyName = user.familyName
                            self.givenName  = user.givenName
                            self.avatarImage = self.givenName
                            self.email = user.email
                            
                            self.statusUpdated?(.finished(.success(true)))
                            // TODO: `CHAccountManager.shared.updateMyProfile` should be fixed
//                            CHAccountManager.shared.updateMyProfile(
//                                first_name:"\(self.givenName ?? "-")",
//                                last_name:"\(self.familyName ?? "-")"
//                            ) { result in
//                                switch result {
//                                case .success(let candyUUID):
//                                    L.d(candyUUID.data as Any)
//                                    self.statusUpdated?(.finished(.success(true)))
//                                case .failure(let error):
//                                    self.statusUpdated?(.finished(.failure(error)))
//                                    L.d(ErrorMessage.descriptionFromError(error: error))
//                                }
//                            }
                        }
                    
                    } catch {
                        self.statusUpdated?(.finished(.failure(error)))
                        L.d(error.errorDescription())
                    }
                } else {
                    L.d("All Null")
                }
            }
        } else {
            UserDefaults.standard.set("Login", forKey: "family_name")
            UserDefaults.standard.set("Register", forKey: "given_name")
            UserDefaults.standard.set("", forKey: "email")
        }
    }
}
