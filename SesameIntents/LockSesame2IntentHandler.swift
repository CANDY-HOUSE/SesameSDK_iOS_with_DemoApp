//
//  LockSesame2IntentHandler.swift
//  SesameIntents
//
//  Created by Wayne Hsiao on 2020/9/29.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Intents
import SesameSDK

class LockSesame2IntentHandler: NSObject, LockSesame2IntentHandling {
    var completion: ((LockSesame2IntentResponse) -> Void)!
    var originDelegate: CHSesame2Delegate?
    
    func resolveName(for intent: LockSesame2Intent, with completion: @escaping (INStringResolutionResult) -> Void) {
        
        var foundNames = [String]()
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesame2s):
                for sesame2 in sesame2s.data {
                    let sesame2Name = Sesame2Store.shared.getSesame2Property(sesame2)?.name ?? sesame2.deviceId.uuidString
                    if let intentName = intent.name,
                        sesame2Name.lowercased().contains(intentName.lowercased()) {
                        foundNames.append(sesame2Name)
                    }
                }
                if foundNames.isEmpty {
                    completion(INStringResolutionResult.confirmationRequired(with: intent.name))
                } else if foundNames.count == 1 {
                    completion(INStringResolutionResult.success(with: foundNames.first!))
                } else {
                    completion(INStringResolutionResult.disambiguation(with: foundNames))
                }
                
            case .failure(_):
                completion(INStringResolutionResult.confirmationRequired(with: intent.name))
            }
        }
    }
    
    func handle(intent: LockSesame2Intent, completion: @escaping (LockSesame2IntentResponse) -> Void) {
        self.completion = completion
        CHBleManager.shared.enableScan { _ in
            guard let sesame2Name = intent.name else {
                let response = LockSesame2IntentResponse(code: .failure, userActivity: nil)
                completion(response)
                return
            }
            self.readyToLlock(sesame2Name)
        }
    }
    
    func readyToLlock(_ sesame2Name: String) {
        var isFound: Bool = false
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesame2s):
                for sesame2 in sesame2s.data {
                    self.originDelegate = sesame2.delegate
                    
                    let foundSesame2Name = Sesame2Store.shared.getSesame2Property(sesame2)?.name ?? sesame2.deviceId.uuidString
                    
                    if foundSesame2Name.lowercased() == sesame2Name.lowercased() {
                        sesame2.delegate = self
                        isFound = true
                        break
                    }
                }
            case .failure(_):
                let response = LockSesame2IntentResponse(code: .failure, userActivity: nil)
                self.completion(response)
            }
        }
        if !isFound {
            let response = LockSesame2IntentResponse(code: .failure, userActivity: nil)
            self.completion(response)
        }
    }
}

extension LockSesame2IntentHandler: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status,shadowStatus: CHSesame2ShadowStatus?) {
        
        if status == .receivedBle {
            device.connect(){ _ in }
        }
        
        if status.loginStatus() == .logined,
            device.intention == .idle,
            device.mechStatus?.isInUnlockRange == true {
            device.lock { _ in
                self.lockCompletedForSesame2(device)
            }
        } else if status.loginStatus() == .logined,
            device.intention == .idle,
            device.mechStatus?.isInLockRange == true {
            lockCompletedForSesame2(device)
        }
    }
    
    func lockCompletedForSesame2(_ sesame2: CHSesame2) {
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesame2sData):
                for sesame2 in sesame2sData.data {
                    sesame2.delegate = self.originDelegate
                }
            case .failure(_):
                break
            }
        }
        
        CHBleManager.shared.disableScan { _ in }
        CHBleManager.shared.disConnectAll { _ in }
        let sesame2Name = Sesame2Store.shared.getSesame2Property(sesame2)?.name ?? sesame2.deviceId.uuidString
        let response = LockSesame2IntentResponse.success(name: sesame2Name)
        self.completion(response)
        self.completion = nil
    }
    
    public func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        
    }
}
