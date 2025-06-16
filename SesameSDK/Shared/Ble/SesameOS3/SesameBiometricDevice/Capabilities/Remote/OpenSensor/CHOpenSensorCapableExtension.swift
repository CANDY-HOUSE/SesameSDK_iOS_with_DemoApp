//
//  CHOpenSensorCapableExtension.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

extension CHOpenSensorCapable where Self: CHSesameOS3 {
     func goIoTWithOpenSensor() {
        let topic = "opensensor/\(deviceId.uuidString)"
        CHIoTManager.shared.subscribeTopic(topic) { [weak self] data in
            guard let self = self else { return }
            
            let state = try! JSONDecoder().decode(OpenSensorData.self, from: data)
            let mechState = OpensensorMechStatus.fromData(state)
            self.mechStatus = mechState
        }
        
        getLatestState { [weak self] response in
            let mechState = (response != nil) ? OpensensorMechStatus.fromData(response!) : nil
            self?.mechStatus = mechState
        }
    }
    
    func getLatestState(result: @escaping (OpenSensorData?) -> Void) {
        CHAccountManager.shared.API(request: .init(.get, "/device/v2/opensensor/\(deviceId.uuidString)/history")) { response in
            switch response {
            case .success(let data):
                do {
                    let state = try JSONDecoder().decode(OpenSensorData.self, from: data!)
                    result(state)
                } catch {
                    result(nil)
                }
            case .failure(let error):
                result(nil)
                L.d("getLatestState", error)
            }
        }
    }
}
