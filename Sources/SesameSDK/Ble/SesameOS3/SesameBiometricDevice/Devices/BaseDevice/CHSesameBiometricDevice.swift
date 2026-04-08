//
//  CHSesameBiometricDevice.swift
//  SesameSDK
//
//  Created by frey Mac on 2026/4/3.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum BiometricCapability: CaseIterable {
    case card
    case fingerPrint
    case passCode
    case palm
    case face
}

public enum BiometricDeviceType {
    case openSensor
    case openSensor2
    case remote
    case remoteNano
    case sesameTouch
    case sesameTouchPro
    case sesameFace
    case sesameFacePro
    case sesameFaceAI
    case sesameFaceProAI
}

public protocol CHSesameBiometricDevice:
    CHDevice,
    CHSesameConnector,
    CHMechanicalSettingsCapable,
    CHRemoteNanoCapable {

    var deviceType: BiometricDeviceType { get }
    var supportedCapabilities: Set<BiometricCapability> { get }

    var sesame2Keys: [String: String] { get set }
    var mechSetting: CHSesameBaseMechSettings? { get set }
    var triggerDelaySetting: CHRemoteBaseTriggerSettings? { get set }
    var radarPayload: Data { get set }

    func goIOT()
}
