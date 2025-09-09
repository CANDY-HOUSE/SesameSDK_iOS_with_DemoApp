//
//  CHUserAPIManager.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/08/11.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import Foundation
import AWSCore
import AWSAPIGateway
import AWSMobileClientXCF
import SesameSDK

extension CHUserAPIManager {
    private enum Constant {
        static let email = "email"
        static let nickname = "nickname"
        static let sub = "sub"
//        static let fudosanEmploy = "custom:fudonsan:employ:tag"
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
extension CHUserAPIManager {
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
    
    /// 拿網路鑰匙
    func getCHUserKeys(_ result: @escaping CHResult<[CHUserKey]>) {
        API(request: .init(.get, "/device")) { getResult in
            switch getResult {
            case .success(let data):
                do{
                    let chUserKeyResult = try JSONDecoder().decode([CHUserKey].self, from: data!)
                    let userDeviceIds = chUserKeyResult.map { $0.deviceUUID }
                    // 依據server結果判斷是否有不符合的本地設備，並於本地端刪除
                    CHDeviceManager.shared.getCHDevices { getResult in
                        if case let .success(localDevices) = getResult {
                            for localDevice in localDevices.data where !userDeviceIds.contains(localDevice.deviceId.uuidString) {
                                localDevice.dropKey { _ in }
                            }
                        }
                    }
                    let keys = chUserKeyResult.compactMap { $0.getKey() }
                    CHDeviceManager.shared.receiveCHDeviceKeys(keys) { _ in
                        //[joi todo] 調查
                    }
                    result(.success(.init(input: chUserKeyResult)))
                }catch let error {
                    L.d(error.localizedDescription)
                    result(.failure(error))
                }

            case .failure(let error):
                result(.failure(error))
                L.d(error)
            }
        }
    }
    
    /// 新增網路鑰匙
    func postCHUserKeys(_ keys: [CHUserKey], _ result: @escaping CHResult<[CHUserKey]>) {
        let jsonData = try! JSONEncoder().encode(keys)
        L.d("postCHUserKeys")
        API(request: .init(.post, "/device", jsonData)) { uploadResult in
            switch uploadResult {
            case .success(let data):
                let chUserKeyResult = try! JSONDecoder().decode([CHUserKey].self, from: data!)
                let keys = chUserKeyResult.compactMap {
                    $0.getKey()
                }
                CHDeviceManager.shared.receiveCHDeviceKeys(keys) { result in   
                }
                result(.success(.init(input: chUserKeyResult)))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    /// 更新網路鑰匙
    func putCHUserKey(_ userKey: CHUserKey, _ result: @escaping CHResult<NSNull>) {
        L.d("putCHUserKey")
        CHDeviceManager.shared.getCHDevices { getResult in
            let jsonData = try! JSONEncoder().encode(userKey)
            self.API(request: .init(.put, "/device", jsonData)) { putResult in
                switch putResult {
                case .success(_):
                    result(.success(.init(input: NSNull())))
                case .failure(let error):
                    L.d("putCHUserKey",error)
                    result(.failure(error))
                }
            }
        }
    }
    
    /// 移除用戶網路鑰匙
    func deleteCHUserKey(_ userKey: CHUserKey, _ handler: ((Result<NSNull, Error>) -> Void)?=nil) {
        let jsonText = "\"" + userKey.deviceUUID + "\""
        API(request: .init(.delete, "/device", jsonText.data(using: .utf8))) { result in
            switch result {
            case .success(_):
                handler?(.success(NSNull()))
            case .failure(let error):
                handler?(.failure(error))
            }
        }
    }
    
    /// 設備 members
    func getDeviceMembers(_ deviceId: String, _ result: @escaping CHResult<[CHUser]>) {
        CHDeviceManager.shared.getCHDevices { getResult in
            if case let .success(chDevices) = getResult {
                if let device = chDevices.data.filter({ $0.deviceId.uuidString == deviceId }).first.flatMap({ $0  }) {
                    let queryParams: [AnyHashable : Any] = ["device_id": deviceId, "a": device.getTimeSignature()]
                    self.API(request: .init(.get, "/device/member", queryParameters:queryParams)) { getResult in
                        switch getResult {
                        case .success(let data):
                            let users = try! JSONDecoder().decode([CHUser].self, from: data!)
                            result(.success(.init(input: users)))
                        case .failure(let error):
                            result(.failure(error))
                        }
                    }
                }
            } else {
                result(.failure(NSError.noDeviceError))
            }
        }
    }
}

// MARK: - Friend
extension CHUserAPIManager {
    /// 新增好友
    func postFriend(_ userId: String, _ result: @escaping CHResult<Any>) { //[joi todo]input參數名
        let jsonText = "\"" + userId + "\""
        API(request: .init(.post, "/friend", jsonText.data(using: .utf8))) { uploadResult in
            switch uploadResult {
            case .success(_):
                result(.success(.init(input: "")))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    /// 取得好友
    func getFriends(_ last:String? = nil,_ result: @escaping CHResult<[CHUser]>) { //[joi todo]input參數名
        var queryParams: [AnyHashable: Any] = ["l": 10]
        if let lastValue = last {
            queryParams["p"] = lastValue
        }
        API(request: .init(.get, "/friend",queryParameters:queryParams)) { getFriendsResult in
            switch getFriendsResult {
            case .success(let data):
                let users = try! JSONDecoder().decode([CHUser].self, from: data!)
                result(.success(.init(input: users)))
            case .failure(let error):
                L.d(error)
                result(.failure(error))
            }
        }
    }
    
    /// 刪除好友
    func deleteFriend(_ subId: String, _ result: @escaping CHResult<Any>) { //[joi todo]input參數名
        let jsonText = "\"" + subId + "\""
        API(request: .init(.delete, "/friend", jsonText.data(using: .utf8))) { uploadResult in
            switch uploadResult {
            case .success(_):
                result(.success(.init(input: "")))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    /// 拿朋友鑰匙
    func getUserKeysOfFriend(_ subId: String, _ result: @escaping CHResult<[CHUserKey]>) {
        let queryParams: NSDictionary = ["friend_id": subId]
        API(request: .init(.get, "/friend/device",queryParameters:queryParams as! [AnyHashable : Any])
        ) { uploadResult in
            switch uploadResult {
            case .success(let data):
                let keys = try! JSONDecoder().decode([CHUserKey].self, from: data!)
                result(.success(.init(input: keys)))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    /// 分享鑰匙
    func shareKey(_ userKey: CHUserKey, toFriend subId: String, _ result: @escaping CHResult<NSNull>) {
        let requestParam = shareKeyPayload(sub: subId.lowercased(), key: userKey)
        let jsonData = try! JSONEncoder().encode(requestParam)
        
        API(request: .init(.post, "/friend/device", jsonData)) { uploadResult in
            switch uploadResult {
            case .success(_):
                result(.success(.init(input: NSNull())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    struct shareKeyPayload: Codable {
        let sub: String
        let key: CHUserKey
    }
    
    /// 移除好友鑰匙
    func revokeKey(_ key: String, ofFriend friend: String, _ result: @escaping CHResult<NSNull>) {
        let requestParam = revokeKeyPayload(sub: friend, deviceUUID: key)
        let jsonData = try! JSONEncoder().encode(requestParam)
        
        API(request: .init(.delete, "/friend/device", jsonData)) { uploadResult in
            switch uploadResult {
            case .success(_):
                result(.success(.init(input: NSNull())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    struct revokeKeyPayload: Codable {
        let sub: String
        let deviceUUID: String
    }

    func uploadUserDeviceToken(_ result: @escaping CHResult<NSNull>){
//        L.d("[noti][uploadUserDeviceToken]")
        if let token:String = UserDefaults.standard.string(forKey: "devicePushToken"){
            let jsonText = "\"" + token + "\""
            API(request: .init(.post, "/friend/token", jsonText.data(using: .utf8))) { uploadResult in
                switch uploadResult {
                case .success(_):
                    result(.success(.init(input: NSNull())))
                case .failure(let error):
                    result(.failure(error))
                }
            }
        }
    }
    
    struct scenePayload: Codable {
        var scene: String
        var token: String?
        var extInfo: [String: String]? = nil
    }
    func getWebUrlByScene(scene: String, extInfo: [String: String]?, _ result: @escaping CHResult<String>){
        let sendRequest: (String?) -> Void = {[self] token in
            let requestParam = scenePayload(scene: scene, token: token, extInfo: extInfo)
            let jsonData = try! JSONEncoder().encode(requestParam)
            API(request: .init(.post, "/web_route", jsonData)){ uploadResult in
                switch uploadResult {
                case .success(let data):
                    if let jsonData = data,
                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let urlString = json["url"] as? String {
                        result(.success(.init(input: urlString)))
                    } else {
                        result(.failure(NSError(domain: "ParseError", code: -1)))
                    }
                case .failure(let error):
                    result(.failure(error))
                }
            }
        }
        if AWSMobileClient.default().isSignedIn {
            AWSMobileClient.default().getTokens { (tokens, error) in
                if let error = error {
                    result(.failure(error))
                    return
                }
                
                let jwtToken = tokens?.idToken?.tokenString
                sendRequest(jwtToken)
            }
        } else {
            sendRequest(nil)
        }
    }

}
