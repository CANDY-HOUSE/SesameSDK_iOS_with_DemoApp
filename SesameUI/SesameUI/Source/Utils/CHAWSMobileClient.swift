//
//  CHMobileClient.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/08/11.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import Foundation
import AWSMobileClientXCF
import SesameSDK

/// 用戶登出登入變化事件介面
protocol CHUserManagerSignInDelegate: AnyObject {
    func signInCompleteHandler(_ result: Result<NSNull, Error>)
    func signInStatusDidChanged(_ status: SignInState)
}

class CHAWSMobileClient {
    static let shared = CHAWSMobileClient()
    weak var delegate: CHUserManagerSignInDelegate?
    var subId: String?
    var nickName: String?
    var email: String?
}

extension CHAWSMobileClient {
    private enum Constant {
        static let email = "email"
        static let nickname = "nickname"
        static let sub = "sub"
    }
    
    // MARK: - SignUp
    func signUpWithEmail(_ email: String, _ result: @escaping ((SignUpResult?, Error?) -> Void)) {
        AWSMobileClient.default().signUp(username: email,
                                         password: "dummypwk",
                                         userAttributes: ["email": email]) { signUpResult, signUpError in
            result(signUpResult, signUpError)
        }
    }
    
    // MARK: - SignIn
    func signInWithEmail(_ email: String) {
        AWSMobileClient.default().signIn(username: email, password: "dummypwk") { signInResult, error in
            if let signInState = signInResult?.signInState {
                self.delegate?.signInStatusDidChanged(signInState)
            }
            if let error = error {
                self.delegate?.signInCompleteHandler(.failure(error))
            }
        }
    }
    
    // MARK: - Verify
    func verifySMS(_ sms: String, ofEmail email: String) {
        AWSMobileClient.default().confirmSignIn(challengeResponse: sms) { signInResult, error in
            if let signInState = signInResult?.signInState {
                self.delegate?.signInStatusDidChanged(signInState)
            }
            if let error = error {
                if case AWSMobileClientError.invalidState(message: "Please call `signIn` before calling this method.") = error {
                    self.signInWithEmail(email)
                    let error = AWSMobileClientError.notAuthorized(message: "Incorrect username or password.")
                    self.delegate?.signInCompleteHandler(.failure(error))
                } else if case AWSMobileClientError.notAuthorized(message: "Incorrect username or password.") = error {
                    self.signInWithEmail(email)
                    self.delegate?.signInCompleteHandler(.failure(error))
                } else {
                    self.delegate?.signInCompleteHandler(.failure(error))
                }
            } else {
                UserDefaults.standard.setValue(email, forKey: Constant.email)
                self.delegate?.signInCompleteHandler(.success(NSNull()))
            }
        }
    }
    
    // MARK: - SignOut
    func signOut(_ completeHandler: (()->Void)? = nil) {
        AWSMobileClient.default().signOut()
        subId = nil
        nickName = nil
        email = nil
        completeHandler?()
    }

    func getSubId(_ handler: @escaping (String?)->Void) {
        if let subId = subId {
            handler(subId)
        } else {
            self.subId = AWSMobileClient.default().userSub
            handler(self.subId)
        }
    }
    
    public func formatSubuuid(_ subuuid: String) -> Data {
        let cleanSubuuid = subuuid.replacingOccurrences(of: "-", with: "")
        var bytes: [UInt8] = []
        var index = cleanSubuuid.startIndex
        while index < cleanSubuuid.endIndex {
            let nextIndex = cleanSubuuid.index(index, offsetBy: 2, limitedBy: cleanSubuuid.endIndex) ?? cleanSubuuid.endIndex
            let byteString = String(cleanSubuuid[index..<nextIndex])
            if let byte = UInt8(byteString, radix: 16) {
                bytes.append(byte)
            }
            index = nextIndex
        }
        return Data(bytes)
    }

    public func updateNickname(_ nickname: String, _ result: @escaping (Result<String, Error>) -> Void) {
        AWSMobileClient.default().updateUserAttributes(attributeMap: [Constant.nickname: nickname]) { deliverDetails, error in
            if let error = error {
                result(.failure(error))
            } else {
                self.nickName = nickname
                UserDefaults.standard.setValue(nickname, forKey: Constant.nickname)
                result(.success(nickname))
            }
        }
    }
    // todo [cognitol] 這裡這樣調用會浪費大量 cognito 傳輸
    
    @discardableResult
    public func getNickname(_ result: @escaping (Result<String?, Error>) -> Void, isCachingEnabled: Bool = true) -> String {
        if isCachingEnabled,let nickName = nickName {
            result(.success(nickName))
            return nickName
        }
        AWSMobileClient.default().getUserAttributes { attributes, error in
            if let error = error {
                result(.failure(error))
            } else {
                // MARK: 更新缓存的昵称
                self.nickName = attributes?[Constant.nickname]
                
                UserDefaults.standard.setValue(attributes?[Constant.nickname], forKey: Constant.nickname)
                UserDefaults.standard.setValue(attributes?[Constant.email], forKey: Constant.email)
                result(.success(attributes?[Constant.nickname]))
            }
        }
        return UserDefaults.standard.string(forKey: Constant.nickname) ?? "User"
    }

    @discardableResult
    public func getEmail(_ result:@escaping (Result<String?, Error>) -> Void) -> String {
        if let email = email {
            result(.success(email))
            return email
        }
        AWSMobileClient.default().getUserAttributes { attributes, error in
            if let error = error {
                result(.failure(error))
            } else {
                let emailFromAtt = attributes?[Constant.email]
                UserDefaults.standard.setValue(attributes?[Constant.nickname], forKey: Constant.nickname)
                UserDefaults.standard.setValue(emailFromAtt, forKey: Constant.email)
                self.email = emailFromAtt
                result(.success(attributes?[Constant.email]))
            }
        }
        return UserDefaults.standard.string(forKey: Constant.email) ?? ""
    }
}

// MARK: - Device
extension CHAWSMobileClient {
    /// 拿本地鑰匙
    func getLocalUserKeys() -> [CHUserKey] {
        var chUserKeys = [CHUserKey]()
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                chUserKeys = devices.data.map {
                    CHUserKey.fromCHDevice($0)
                }
            }
        }
        return chUserKeys
    }
}
