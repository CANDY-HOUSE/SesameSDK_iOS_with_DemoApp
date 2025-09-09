//
//  CHHub3Device+IR.swift
//  SesameSDK
//
//  Created by eddy on 2024/8/28.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
extension CHHub3Device {
  
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
}
