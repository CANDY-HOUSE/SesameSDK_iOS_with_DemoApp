//
//  CHRemoteNanoDelegate.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

public protocol CHRemoteNanoDelegate: AnyObject {
    func onTriggerDelaySecondReceived(device: CHSesameConnector, setting: CHRemoteBaseTriggerSettings)
}

public extension  CHRemoteNanoDelegate  {
    func onTriggerDelaySecondReceived(device: CHSesameConnector, setting: CHRemoteBaseTriggerSettings) {}
}
