//
//  CHSesameBaseDevice+ Delegate.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/2.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

extension CHSesameBaseDevice {
    
    func getVersionTag(result: @escaping (CHResult<String>))  {
        if(!isBleAvailable(result)){return}
        sendCommand(.init(.versionTag)) { (response) in
            let versionTag = String(data: response.data, encoding: .utf8) ?? ""
            result(.success(CHResultStateNetworks(input: versionTag)))
        }
    }
}
