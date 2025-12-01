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
