//
//  CHMechanicalSettingsCapable.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


public protocol CHMechanicalSettingsCapable: CHDevice ,CHSesameConnector {
    var mechSetting: CHSesameBaseMechSettings? { get }
    var triggerDelaySetting: CHRemoteBaseTriggerSettings? { get }
}
