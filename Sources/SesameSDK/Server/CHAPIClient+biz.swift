//
//  Untitled.swift
//  SesameWatchKitSDK
//
//  Created by eddy on 2026/1/4.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation

public extension CHAPIClient {
    
    // MARK: Device
    /// 获取網路鑰匙
    func getCHUserKeys(_ result: @escaping CHResult<[[String: Any]]>) {
        API(request: .init(.get, "/device/list")) { getResult in
            switch getResult {
            case .success(let data):
                do {
                    guard let data = data,
                          let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                        result(.failure(NSError(domain: "CHAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])))
                        return
                    }
                    let userDeviceIds = jsonArray.compactMap { $0["deviceUUID"] as? String }
                    CHDeviceManager.shared.getCHDevices { getResult in
                        if case let .success(localDevices) = getResult {
                            for localDevice in localDevices.data where !userDeviceIds.contains(localDevice.deviceId.uuidString) {
                                localDevice.dropKey { _ in }
                            }
                        }
                    }
                    let keys = jsonArray.compactMap { dict -> CHDeviceKey? in
                        guard let deviceUUIDString = dict["deviceUUID"] as? String,
                              let deviceUUID = UUID(uuidString: deviceUUIDString),
                              let deviceModel = dict["deviceModel"] as? String,
                              let keyIndex = dict["keyIndex"] as? String,
                              let secretKey = dict["secretKey"] as? String,
                              let sesame2PublicKey = dict["sesame2PublicKey"] as? String else {
                            return nil
                        }
                        return CHDeviceKey(
                            deviceUUID: deviceUUID,
                            deviceModel: deviceModel,
                            historyTag: nil,
                            keyIndex: keyIndex,
                            secretKey: secretKey,
                            sesame2PublicKey: sesame2PublicKey
                        )
                    }
                    CHDeviceManager.shared.receiveCHDeviceKeys(keys) { _ in }
                    result(.success(CHResultStateNetworks(input: jsonArray)))
                } catch let error {
                    L.d(error.localizedDescription)
                    result(.failure(error))
                }
            case .failure(let error):
                result(.failure(error))
                L.d(error)
            }
        }
    }
    
    /// 发送網路鑰匙
    func postCHUserKeys(_ jsonData: Data, _ result: @escaping CHResult<NSNull>) {
        L.d("postCHUserKeys")
        API(request: .init(.post, "/device", jsonData)) { uploadResult in
            switch uploadResult {
            case .success(let data):
                guard let data = data,
                      let jsonArray = try! JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                    result(.failure(NSError(domain: "CHAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])))
                    return
                }
                let keys = jsonArray.compactMap { dict -> CHDeviceKey? in
                    guard let deviceUUIDString = dict["deviceUUID"] as? String,
                          let deviceUUID = UUID(uuidString: deviceUUIDString),
                          let deviceModel = dict["deviceModel"] as? String,
                          let keyIndex = dict["keyIndex"] as? String,
                          let secretKey = dict["secretKey"] as? String,
                          let sesame2PublicKey = dict["sesame2PublicKey"] as? String else {
                        return nil
                    }
                    return CHDeviceKey(
                        deviceUUID: deviceUUID,
                        deviceModel: deviceModel,
                        historyTag: nil,
                        keyIndex: keyIndex,
                        secretKey: secretKey,
                        sesame2PublicKey: sesame2PublicKey
                    )
                }
                CHDeviceManager.shared.receiveCHDeviceKeys(keys) { _ in }
                result(.success(.init(input: NSNull())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    /// 更新網路鑰匙
    func putCHUserKey(_ jsonData: Data, _ result: @escaping CHResult<NSNull>) {
        L.d("putCHUserKey")
        CHDeviceManager.shared.getCHDevices { getResult in
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
    func deleteCHUserKey(_ jsonData: Data, _ handler: ((Result<NSNull, Error>) -> Void)?=nil) {
        API(request: .init(.delete, "/device", jsonData)) { result in
            switch result {
            case .success(_):
                handler?(.success(NSNull()))
            case .failure(let error):
                handler?(.failure(error))
            }
        }
    }
    // MARK: Friend
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

    /// 上传用户 Token
    func uploadUserDeviceToken(_ result: @escaping CHResult<NSNull>){
        L.d("[noti][uploadUserDeviceToken]")
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
    
    /// 移除用户 Token
    func disableNotification(deviceId: String, token: String, name: String, result: @escaping CHResult<CHEmpty>) {
        API(request: .init(.delete, "/device/v1/token", ["token": token, "deviceId": deviceId, "name": name])) { deleteResult in
            switch deleteResult {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    /// 获取网页链接
    struct scenePayload: Codable {
        var scene: String
        var token: String?
        var extInfo: [String: String]? = nil
    }
    
    func getWebUrlByScene(scene: String, extInfo: [String: String]?, jwtToken: String?, _ result: @escaping CHResult<String>){
        let requestParam = scenePayload(scene: scene, token: jwtToken, extInfo: extInfo)
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
    
    // MARK: GPS
    func postCHDeviceIno(_ jsonData: Data, _ result: @escaping CHResult<Any>) {
        API(request: .init(.post, "/device/infor", jsonData)) { uploadResult in
            switch uploadResult {
            case .success(_):
                result(.success(.init(input: "")))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    // MARK: Notification
    /// 订阅 SNS 主题
    /// - Parameters:
    ///   - topicName: 主题名称
    ///   - pushToken: APNs token (iOS) 或 FCM token (Android)
    ///   - platform: 平台类型 (ios, ios_sandbox, android)
    ///   - completion: 完成回调
    func subscribeToSNSTopic(
        topicName: String,
        pushToken: String,
        platform: String,
        completion: @escaping (Bool) -> Void
    ) {
        let parameters: [String: Any] = [
            "action": "subscribeToTopic",
            "topicName": topicName,
            "pushToken": pushToken,
            "platform": platform
        ]
        let payload = try! JSONSerialization.data(withJSONObject: parameters)
        API(request: .init(.post, "/device/v1/subscribe", payload)) { response in
            switch response {
            case .success(let data):
                if let jsonObj = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any],
                   let bodyString = jsonObj["body"] as? String,
                   bodyString.contains("\"success\":true") {
                    completion(true)
                } else {
                    completion(false)
                }
            case .failure(let error):
                L.d("sf", "Subscribe error: \(error)")
                completion(false)
            }
        }
    }
    
    // MARK: - IoT
    /// 获取设备影子数据 (watchOS)
    func getCHDeviceShadow(deviceId: String, result: @escaping CHResult<Data>) {
        API(request: .init(.get, "/device/v1/sesame2/\(deviceId)")) { apiResult in
            switch apiResult {
            case .success(let data):
                if let data = data {
                    result(.success(.init(input: data)))
                } else {
                    result(.failure(NSError.noDataError))
                }
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    /// 发送IoT命令到设备
    func sendIoTCommand(deviceId: String, command: Int8, history: String, sign: String, result: @escaping CHResult<CHEmpty>) {
        let parameter = [
            "cmd": command,
            "history": history,
            "sign": sign
        ] as [String : Any]
        API(request: .init(.post, "/device/v1/iot/sesame2/\(deviceId)", parameter)) { apiResult in
            if case let .failure(error) = apiResult {
                result(.failure(error))
            } else {
                result(.success(.init(input: .init())))
            }
        }
    }
    
    // MARK: - Battery
    /// 上传电池数据
    func postBatteryData(deviceId: String, payload: String, result: @escaping CHResult<CHEmpty>) {
        API(request: .init(.post, "/device/v1/sesame5/\(deviceId)/battery", ["payload": payload])) { res in
            switch res {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    // MARK: - History
    /// 上传历史记录
    func postHistory(deviceId: String, payload: String, t: String, result: @escaping CHResult<CHEmpty>) {
        API(request: .init(.post, "/device/v1/sesame2/historys", ["s":deviceId, "v": payload, "t": t] as [String : Any])) { response in
            switch response {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    // MARK: - Sign
    /// 访客钥匙签名
    func signDeviceToken(deviceId: String, token: String, secretKey: String, result: @escaping CHResult<String>) {
        API(request: .init(.post, "/device/v1/sesame2/sign", ["deviceId": deviceId, "token": token, "secretKey": secretKey])) { serverResult in
            switch serverResult {
            case .success(let data):
                if let data = data, let signedToken = String(data: data, encoding: .utf8) {
                    result(.success(.init(input: signedToken)))
                } else {
                    result(.failure(NSError.noDataError))
                }
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    // MARK: - Hub3
    /// 获取Hub3状态
    func getHub3Status(deviceId: String, result: @escaping CHResult<Data>) {
        API(request: .init(.get, "/device/v1/wifi_module/\(deviceId)/status")) { response in
            switch response {
            case .success(let data):
                if let data = data {
                    result(.success(.init(input: data)))
                } else {
                    result(.failure(NSError.noDataError))
                }
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    // MARK: - Biometric/Credential
    /// 生物识别数据操作 (通用)
    func biometricsOperation(payload: Data, result: @escaping CHResult<Data>) {
        API(request: .init(.post, "/device/v1/biometrics", payload)) { response in
            switch response {
            case .success(let data):
                if let data = data {
                    result(.success(.init(input: data)))
                } else {
                    result(.failure(NSError.noDataError))
                }
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    /// 注册设备
    func registerDevice(deviceId: String, productType: Int, publicKey: String, result: @escaping CHResult<CHEmpty>) {
        API(request: .init(.post, "/device/v1/sesame5/\(deviceId)", ["t": productType, "pk": publicKey] as [String : Any])) { response in
            switch response {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    /// 上传固件版本号
    func postFirmwareVersion(deviceId: String, versionTag: String, result: @escaping CHResult<CHEmpty>) {
        API(request: .init(.post, "/device/v1/sesame5/\(deviceId)/fwVer", ["versionTag": versionTag])) { response in
            switch response {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
}
