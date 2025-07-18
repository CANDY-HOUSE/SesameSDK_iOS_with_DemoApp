//
//  CHHub3Device+IR.swift
//  SesameSDK
//
//  Created by eddy on 2024/8/28.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
extension CHHub3Device {
    
    func postIRDevice(_ payload: IRDevicePayload, _ result: @escaping CHResult<CHEmpty>) {
        let jsonData = try! JSONEncoder().encode(payload)
        CHAccountManager.shared.API(request: .init(.post, "/device/v2/ir/\(deviceId.uuidString)", jsonData)) { [self] resposne in
            switch resposne {
            case .success(let data):
                L.d("遥控器已创建")
                let remotes = try! JSONDecoder().decode([IRRemote].self, from: data!)
                self.irRemotes = remotes
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func updateIRDevice(_ payload: [String: String], _ result: @escaping CHResult<CHEmpty>) {
        let jsonData = try! JSONEncoder().encode(payload)
        CHAccountManager.shared.API(request: .init(.put, "/device/v2/ir/\(deviceId.uuidString)", jsonData)) { resposne in
            switch resposne {
            case .success(_):
                L.d("遥控器状态已更新")
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func getIRDeviceKeysByUid(_ uuid: String, _ result: @escaping CHResult<[CHHub3IRCode]>) {
        guard !uuid.isEmpty else { return }
        let queryParams = ["uuid": uuid]
        CHAccountManager.shared.API(request: .init(.get, "/device/v2/ir/\(deviceId.uuidString)/keys/", queryParameters: queryParams)) { resposne in
            switch resposne {
            case .success(let data):
                let codes = try! JSONDecoder().decode([CHHub3IRCode].self, from: data!)
                result(.success(.init(input: codes)))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func deleteIRDevice(_ uuid: String, _ result: @escaping CHResult<CHEmpty>) {
        let payload = [
            "uuid": uuid
        ]
        let data = try! JSONEncoder().encode(payload)
        CHAccountManager.shared.API(request: .init(.delete, "/device/v2/ir/\(deviceId.uuidString)", data)) { resposne in
            switch resposne {
            case .success(_):
                L.d("delete success")
                self.irRemotes.removeAll(where: { $0.uuid == uuid })
                result(.success(.init(input: .init())))
            case .failure(let error):
                L.d("delete error")
                result(.failure(error))
            }
        }
    }
    
    func irCodeDelete(uuid: String, keyUUID: String, result: @escaping CHResult<CHEmpty>) {
        let data = ["uuid": uuid, "keyUUID": keyUUID]
        let send = try! JSONEncoder().encode(data)
        CHAccountManager.shared.API(request: .init(.delete, "/device/v2/ir/\(deviceId.uuidString)/keys", send)) { uploadResult in
            switch uploadResult {
            case .success(_):
                L.d("删除按键成功", uuid, keyUUID)
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func emitIRCode(_ code: String, irDeviceUUID: String, result: @escaping CHResult<CHEmpty>) {
        let keyName = code.hasPrefix("300") ? "hxd" : "learned"
        let data = [keyName: code, "operation": "emit", "irDeviceUUID": irDeviceUUID]
        L.d("emitIRCode", data)
        let send = try! JSONEncoder().encode(data)
        CHAccountManager.shared.API(request: .init(.post, "/device/v2/ir/\(deviceId.uuidString)/send", send)) { uploadResult in
            switch uploadResult {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func irCodeChange(uid: String, keyUUID: String, name: String, result: @escaping CHResult<CHEmpty>) {
        let send = try! JSONEncoder().encode([
            "uuid": uid,
            "keyUUID": keyUUID,
            "name": name
        ])
        CHAccountManager.shared.API(request: .init(.put, "/device/v2/ir/\(deviceId.uuidString)/keys", send)) { uploadResult in
            switch uploadResult {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func fetchIRDevices(_ result: @escaping CHResult<[IRRemote]>) {
        CHAccountManager.shared.API(request: .init(.get, "/device/v2/ir/\(deviceId.uuidString)")) { resposne in
            switch resposne {
            case .success(let data):
                let remotes = try! JSONDecoder().decode([IRRemote].self, from: data!)
                self.irRemotes = remotes
                result(.success(.init(input: remotes)))
                L.d("红外获取成功", remotes)
                break
            case .failure(let error):
                L.d("红外获取失败")
                result(.failure(error))
                break
            }
        }
    }
    
    
    func subscribeLearnData(result: @escaping CHResult<Data>) {
        let topic = "hub3/\(deviceId.uuidString.uppercased())/ir/learned/data"
        L.d("CHHub3Device", "[hub3] subscribeLearnData 訂閱主題:$topic")
        CHIoTManager.shared.subscribeTopic(topic) { [self] data in
            L.d("CHHub3Device", "[hub3] subscribeLearnData 收到資料: \(data.toHexLog())")
            self.unsubscribeLearnData() // 收到資料後取消訂閱
            guard let data = data as? Data else {
                L.d("CHHub3Device", "[hub3] getOtaProgress 收到資料格式錯誤")
                return
            }
            result(.success(CHResultStateNetworks(input: Data(data))))
        }
    }
    
    func unsubscribeLearnData() {
        let topic = "hub3/\(deviceId.uuidString.uppercased())/ir/learned/data"
        CHIoTManager.shared.unsubscribeTopic(topic)
    }
    
    
    
    
    func addLearnData(data:Data, hub3DeviceUUID: String, irDataNameUUID:String, irDeviceUUID:String, keyUUID: String, result: @escaping CHResult<CHEmpty>) {
 
        let payload:[String: Any] = [
            "IrDataNameUUID": irDataNameUUID,
            "DataLength": data.count,
            "Esp32c3LearnedIrDataHexString": data.toHexString(),
            "TimeStamp": Int64(Date().timeIntervalSince1970 * 1000),
            "Hub3DeviceUUID": hub3DeviceUUID,
            "irDeviceUUID": irDeviceUUID,
            "keyUUID": keyUUID
        ]
        let send = try! JSONSerialization.data(withJSONObject: payload, options: [])
        
        CHAccountManager.shared.API(request: .init(.post, "/device/v2/ir/hub3_learned_ir_data", send)) { onResult in
            switch onResult {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
}
