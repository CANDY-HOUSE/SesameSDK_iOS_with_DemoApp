//
//  CHSesameBasePro.swift
//  SesameSDK
//
//  Created by CANDY HOUSE on 2025/4/6.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
public protocol CHSesameBasePro: CHDevice, CHSesameConnector, CHMechanicalSettingsCapable, CHRemoteNanoCapable {
    var sesame2Keys: [String: String] { get set }
    var mechSetting: CHSesameBaseMechSettings? { get set }
    var triggerDelaySetting: CHRemoteBaseTriggerSettings? { get set }
    var delegateManager: CHDelegateManager { get }
    var radarPayload: Data { get set }
    
    // 方法
    func registerFingerPrintDelegate()
    func registerPassCodeDelegate()
    func registerPalmDelegate()
    func registerFaceDelegate()
    func goIOT()
}
