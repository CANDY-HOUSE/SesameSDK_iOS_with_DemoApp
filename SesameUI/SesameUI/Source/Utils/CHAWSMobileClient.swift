//
//  CHMobileClient.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/08/11.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import Foundation
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
    var name: String?
    var email: String?
}

extension CHAWSMobileClient {
    private enum Constant {
        static let email = "email"
        static let name = "name"
        static let sub = "sub"
    }
    
    // MARK: - SignUp
    func signUpWithEmail(_ email: String, _ result: @escaping ((SignUpResult?, Error?) -> Void)) {
        CHAWSManager.signUp(username: email, password: "dummypwk", attributes: [Constant.email: email], completion: result)
    }
    
    // MARK: - SignIn
    func signInWithEmail(_ email: String) {
        CHAWSManager.signIn(username: email, password: "dummypwk") { signInState, error in
            if let signInState {
                self.delegate?.signInStatusDidChanged(signInState)
            }
            if let error = error {
                self.delegate?.signInCompleteHandler(.failure(error))
            }
        }
    }
    
    // MARK: - Verify
    func verifySMS(_ sms: String, ofEmail email: String) {
        CHAWSManager.confirmSignIn(challengeResponse: sms) { signInState, error in
            if let signInState {
                self.delegate?.signInStatusDidChanged(signInState)
            }
            if let error = error {
                if let authError = error as? CHAuthError, case .invalidState = authError {
                    self.signInWithEmail(email)
                    let error = CHAuthError.notAuthorized("Incorrect username or password.")
                    self.delegate?.signInCompleteHandler(.failure(error))
                } else if let authError = error as? CHAuthError, case .notAuthorized = authError {
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
        subId = nil
        name = nil
        email = nil
        CHAWSManager.signOut(completion: completeHandler)
    }

    func getSubId(_ handler: @escaping (String?)->Void) {
        if let subId = subId {
            handler(subId)
        } else {
            CHAWSManager.userSub { subId in
                self.subId = subId
                handler(subId)
            }
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

    public func updateName(_ nickname: String, _ result: @escaping (Result<String, Error>) -> Void) {
        CHAWSManager.updateUserAttribute(key: Constant.name, value: nickname) { error in
            if let error = error {
                result(.failure(error))
            } else {
                self.name = nickname
                UserDefaults.standard.setValue(nickname, forKey: Constant.name)
                result(.success(nickname))
            }
        }
    }
    // todo [cognitol] 這裡這樣調用會浪費大量 cognito 傳輸
    
    @discardableResult
    public func getName(_ result: @escaping (Result<String?, Error>) -> Void, isCachingEnabled: Bool = true) -> String {
        if isCachingEnabled,let nickName = name {
            result(.success(nickName))
            return nickName
        }
        CHAWSManager.fetchUserAttributes { attributesResult in
            switch attributesResult {
            case .failure(let error):
                result(.failure(error))
            case .success(let attributes):
                // MARK: 更新缓存的昵称
                self.name = attributes[Constant.name]
                
                UserDefaults.standard.setValue(attributes[Constant.name], forKey: Constant.name)
                UserDefaults.standard.setValue(attributes[Constant.email], forKey: Constant.email)
                result(.success(attributes[Constant.name]))
            }
        }
        return UserDefaults.standard.string(forKey: Constant.name) ?? "User"
    }

    @discardableResult
    public func getEmail(_ result:@escaping (Result<String?, Error>) -> Void) -> String {
        if let email = email {
            result(.success(email))
            return email
        }
        CHAWSManager.fetchUserAttributes { attributesResult in
            switch attributesResult {
            case .failure(let error):
                result(.failure(error))
            case .success(let attributes):
                let emailFromAtt = attributes[Constant.email]
                UserDefaults.standard.setValue(attributes[Constant.name], forKey: Constant.name)
                UserDefaults.standard.setValue(emailFromAtt, forKey: Constant.email)
                self.email = emailFromAtt
                result(.success(attributes[Constant.email]))
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
