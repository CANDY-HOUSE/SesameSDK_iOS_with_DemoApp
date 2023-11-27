//
//  CHWifiModule2.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/8/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol CHWifiModule2Delegate: CHDeviceStatusDelegate,CHSesameConnectorDelegate {
    func onAPSettingChanged(device: CHWifiModule2, settings: CHWifiModule2MechSettings)
    func onSesame2KeysChanged(device: CHWifiModule2, sesame2keys: [String: String])
    func onOTAProgress(device: CHWifiModule2, percent: UInt8)
    func onScanWifiSID(device: CHWifiModule2, ssid: CHSSID)
}

public extension CHWifiModule2Delegate {
    func onAPSettingChanged(device: CHWifiModule2, settings: CHWifiModule2MechSettings){}
    func onOTAProgress(device: CHWifiModule2, percent: UInt8) {}
    func onScanWifiSID(device: CHWifiModule2, ssid: CHSSID) {}
}

public protocol CHWifiModule2: CHDevice,CHSesameConnector {
    var mechSetting: CHWifiModule2MechSettings? { get }
    func scanWifiSSID(result: @escaping CHResult<CHEmpty>)
    func connectWifi(result: @escaping (CHResult<CHEmpty>))
    func setWifiSSID(_ ssid: String, result: @escaping (CHResult<CHEmpty>))
    func setWifiPassword(_ password: String, result: @escaping (CHResult<CHEmpty>))
}

extension CHWifiModule2 {
    func createGuestKey(result: @escaping CHResult<String>) {}
    func sign(token: String, result: @escaping CHResult<String>) {}
    func getGuestKeys(result: @escaping CHResult<[CHGuestKey]>) {}
    func removeGuestKey(_ fakeKey: String, result: @escaping CHResult<CHEmpty>) {}
    func updateGuestKey(_ guestKeyId: String, name: String, result: @escaping CHResult<CHEmpty>) {}
}


public class CHWifiModule2MechSettings {
    public internal(set) var wifiSSID: String?
    public internal(set) var wifiPassword: String?
}

public struct CHWifiModule2NetworkStatus:CHSesameProtocolMechStatus {

    public func getBatteryVoltage() -> Float {
        return 0
    }

    public var isAPWork: Bool?
    public var isNetwork: Bool?
    public var isIoTWork: Bool?
    public var isBindingAPWork: Bool
    public var isConnectingNetwork: Bool
    public var isConnectingIoT: Bool

    init(isAPWork: Bool? = nil, isNetwork: Bool? = nil, isIoTWork: Bool? = nil, isBindingAPWork: Bool, isConnectingNetwork: Bool, isConnectingIoT: Bool) {
        self.isAPWork = isAPWork
        self.isNetwork = isNetwork
        self.isIoTWork = isIoTWork
        self.isBindingAPWork = isBindingAPWork
        self.isConnectingNetwork = isConnectingNetwork
        self.isConnectingIoT = isConnectingIoT
    }
}


