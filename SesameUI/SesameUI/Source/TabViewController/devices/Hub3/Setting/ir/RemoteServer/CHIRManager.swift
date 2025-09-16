//
//  CHIRManager.swift
//  SesameUI
//
//  Created by wuying on 2025/9/4.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
import SesameSDK

#if os(iOS)
import AWSCore
import AWSAPIGateway
import AWSIoT
#endif
import Foundation



public class CHIRManager {
    
    public static let shared:CHIRManager! = CHIRManager()
    
    
    func irCodeEmit(hub3DeviceId: String, code: String, irDeviceUUID: String, irType:Int, result: @escaping CHResult<CHEmpty>) {
        let keyName = code.hasPrefix("300") ? "hxd" : "learned"
//        let data = [keyName: code, "operation": "emit", "irDeviceUUID": irDeviceUUID]
        
        let operation = code.hasPrefix("300") ? "remoteEmit" : "learnEmit"
        let data = ["operation": operation, "data": code, "irDeviceUUID": irDeviceUUID, "irType": String(irType)]
        let send = try! JSONEncoder().encode(data)
        
        CHAccountManager.shared.publicAPI(request: .init(.post, "/device/v2/ir/\(hub3DeviceId)/send", send)) { uploadResult in
            switch uploadResult {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func postIRDevice(_ hub3DeviceId: String, _ payload: IRDevicePayload, _ result: @escaping CHResult<CHEmpty>) {
        let jsonData = try! JSONEncoder().encode(payload)
        CHAccountManager.shared.publicAPI(request: .init(.post, "/device/v2/ir/\(hub3DeviceId)", jsonData)) { [self] resposne in
            switch resposne {
            case .success(let data):
                L.d("遥控器已创建")
                let remotes = try! JSONDecoder().decode([IRRemote].self, from: data!)
                result(.success(.init(input: .init())))
                // TODO 把遥控器添加至列表中 ：self.irRemotes = remotes
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func updateIRDevice(hub3DeviceId: String, _ payload: [String: String], _ result: @escaping CHResult<CHEmpty>) {
        let jsonData = try! JSONEncoder().encode(payload)
        CHAccountManager.shared.publicAPI(request: .init(.put, "/device/v2/ir/\(hub3DeviceId)", jsonData)) { resposne in
            switch resposne {
            case .success(_):
                L.d("遥控器状态已更新")
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func getIRDeviceKeysByUid(_ hub3DeviceId: String, _ uuid: String, _ result: @escaping CHResult<[IRCode]>) {
        guard !uuid.isEmpty else { return }
        let queryParams = ["uuid": uuid]
        CHAccountManager.shared.publicAPI(request: .init(.get, "/device/v2/ir/\(hub3DeviceId)/keys/", queryParameters: queryParams)) { resposne in
            switch resposne {
            case .success(let data):
                let codes = try! JSONDecoder().decode([IRCode].self, from: data!)
                result(.success(.init(input: codes)))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func irCodeDelete(hub3DeviceId: String, uuid: String, keyUUID: String, result: @escaping CHResult<CHEmpty>) {
        let data = ["uuid": uuid, "keyUUID": keyUUID]
        let send = try! JSONEncoder().encode(data)
        CHAccountManager.shared.publicAPI(request: .init(.delete, "/device/v2/ir/\(hub3DeviceId)/keys", send)) { uploadResult in
            switch uploadResult {
            case .success(_):
                L.d("删除按键成功", uuid, keyUUID)
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func irCodeChange(hub3DeviceId: String, uuid: String, keyUUID: String, name: String, result: @escaping CHResult<CHEmpty>) {
        let send = try! JSONEncoder().encode([
            "uuid": uuid,
            "keyUUID": keyUUID,
            "name": name
        ])
        CHAccountManager.shared.publicAPI(request: .init(.put, "/device/v2/ir/\(hub3DeviceId)/keys", send)) { uploadResult in
            switch uploadResult {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    
    func subscribeTopic(topic: String, result: @escaping CHResult<Data>) {
        L.d("CHHub3Device", "[hub3] subscribeTopic \(topic)")
        CHAccountManager.shared.subscribeTopic(topic: topic) { sdkResult in
            result(sdkResult.map { CHResultStateNetworks(input: $0.data) })
        }
    }
    
    func unsubscribeTopic(topic: String) {
//        let topic = "hub3/\(deviceId.uuidString.uppercased())/ir/learned/data"
        CHAccountManager.shared.unsubscribeTopic(topic: topic)
    }
    
    func irModeSet(hub3DeviceId: String, mode: UInt8, result: @escaping CHResult<CHEmpty>) {
        let send = try! JSONEncoder().encode([
            "data": String(mode),
            "operation": "modeSet"
        ])
        
        CHAccountManager.shared.publicAPI(request: .init(.put, "/device/v2/ir/\(hub3DeviceId)/mode", send)) { uploadResult in
            switch uploadResult {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func irModeGet(hub3DeviceId: String, result: @escaping CHResult<CHEmpty>) {
        let send = try! JSONEncoder().encode([
            "operation": "modeGet"
        ])
        CHAccountManager.shared.publicAPI(request: .init(.put, "/device/v2/ir/\(hub3DeviceId)/mode", send)) { uploadResult in
            switch uploadResult {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
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
        
        CHAccountManager.shared.publicAPI(request: .init(.post, "/device/v2/ir/hub3_learned_ir_data", send)) { onResult in
            switch onResult {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func fetchRemoteList(irType: Int, _ result: @escaping CHResult<[IRRemote]>) {
        let queryParams = ["type": irType]
        CHAccountManager.shared.publicAPI(request: .init(.get, "/device/v2/ir/remote", queryParameters: queryParams)) { resposne in
            switch resposne {
            case .success(let data):
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    guard let dataArray = json?["data"] as? [[String: Any]] else {
                        throw NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data field found"])
                    }
                    let dataArrayData = try JSONSerialization.data(withJSONObject: dataArray, options: [])
                    let codes = try JSONDecoder().decode([IRRemote].self, from: dataArrayData)
                    result(.success(.init(input: codes)))
                } catch {
                    L.e("fetchRemoteList", "Decode error: \(error)")
                    result(.failure(error))
                }
                
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func matchIrCode(data: Data, type: Int, brandName: String, result: @escaping CHResult<[MatchIRRemote]>) {
        if data.count < 20 {
            result(.failure(NSError(domain: "MatchIrCode", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid data length: \(data.count)"])))
            return
        }
        
        let payload: [String: Any] = [
            "irWave": data.toHexString(),
            "irWaveLength": data.count,
            "type": type,
            "brandName": brandName
        ]
        guard let requestData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            result(.failure(NSError(domain: "MatchIrCode", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request data"])))
            return
        }
        
        
        CHAccountManager.shared.publicAPI(request: .init(.post, "/device/v2/ir/hub3_match_ir_code", requestData)) { onResult in
            switch onResult {
            case .success(let responseData):
                guard let data = responseData else {
                    result(.failure(NSError(domain: "MatchIrCode", code: -3, userInfo: [NSLocalizedDescriptionKey: "No response data"])))
                    return
                }
                do {
                    let matchRemotes = try self.parseJsonToIrRemoteWithMatchList(data: data, type: type)
                    result(.success(.init(input: matchRemotes)))
                } catch {
                    result(.failure(error))
                }
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    private func parseJsonToIrRemoteWithMatchList(data: Data, type: Int) throws -> [MatchIRRemote] {
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
        }
        
        guard let resultArray = jsonObject["result"] as? [[String: Any]] else {
            // 如果没有 result 字段或者为空，返回空数组
            return []
        }
        
        var matchRemotes: [MatchIRRemote] = []
        
        for element in resultArray {
            guard let controlType = element["controlType"] as? [String: Any] else {
                continue
            }
            
            let model = controlType["model"] as? String ?? ""
            let alias = controlType["alias"] as? String ?? ""
            let direction = controlType["direction"] as? String ?? ""
            let brandCode = element["companyCode"] as? Int ?? -1
            let bestMatchPercentage = element["bestMatchPercentage"] as? Double ?? 0.0
            
            // 格式化匹配百分比
            let matchPercent = String(format: "%.2f%%", bestMatchPercentage)
            
            // 创建 IRRemote
            let irRemote = IRRemote(
                uuid: UUID().uuidString.uppercased(),
                alias: alias,
                model: model,
                type: type,
                timestamp: Int(Date().timeIntervalSince1970 * 1000), // 毫秒时间戳
                state: nil,
                code: brandCode,
                direction: direction
            )
            
            // 创建 MatchIRRemote
            let matchRemote = MatchIRRemote(matchPercent: matchPercent, remote: irRemote)
            matchRemotes.append(matchRemote)
        }
        
        return matchRemotes
    }
    
    func fetchIRDevices(_ hub3DeviceId: String, _ result: @escaping CHResult<[IRRemote]>) {
        CHAccountManager.shared.publicAPI(request: .init(.get, "/device/v2/ir/\(hub3DeviceId)")) { resposne in
            switch resposne {
            case .success(let data):
                let remotes = try! JSONDecoder().decode([IRRemote].self, from: data!)
                IRRemoteRepository.shared.setRemotes(key: hub3DeviceId, remotes: remotes)
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
    
    func deleteIRDevice(_ hub3DeviceId: String, _ uuid: String, _ result: @escaping CHResult<CHEmpty>) {
        let payload = [
            "uuid": uuid
        ]
        let data = try! JSONEncoder().encode(payload)
        CHAccountManager.shared.publicAPI(request: .init(.delete, "/device/v2/ir/\(hub3DeviceId)", data)) { resposne in
            switch resposne {
            case .success(_):
                L.d("delete success")
                IRRemoteRepository.shared.removeRemote(key: hub3DeviceId, remoteUUID: uuid)
                result(.success(.init(input: .init())))
            case .failure(let error):
                L.d("delete error")
                result(.failure(error))
            }
        }
    }
    
    
    
}
