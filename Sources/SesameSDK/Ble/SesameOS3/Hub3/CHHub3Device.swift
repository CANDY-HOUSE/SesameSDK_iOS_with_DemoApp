//
//  CHHub3Device.swift
//  SesameSDK
//
//  Created by eddy on 2023/12/26.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

class CHHub3Device: CHSesameOS3, CHHub3, CHDeviceUtil {
    var sesame2Keys: [String : String] = [:]
    /// 繼電器是否開啟（true=打開，false=關閉）
    var isRelayOn: Bool = false
    
    var mechSetting: CHWifiModule2MechSettings? = CHWifiModule2MechSettings()
    
    var advertisement: BleAdv? {
        didSet {
            guard let advertisement = advertisement else {
                deviceStatus = .noBleSignal()
                return
            }
            setAdv(advertisement)
        }
    }

    override func onGattSesamePublish(_ payload: SesameOS3PublishPayload) {
        super.onGattSesamePublish(payload)
        onGattHub3Publish(payload)
    }

}

// register
extension CHHub3Device {
    
    /// 登录
    /// - Parameter token: 用戶token
    func login(token: String? = nil) {
        guard let sesame2KeyData = sesame2KeyData, let sessionToken = mSesameToken else { return }
        self.deviceStatus = .bleLogining()
        let sessionAuth: Data = token?.hexStringtoData() ?? CC.CMAC.AESCMAC(sessionToken, key: sesame2KeyData.secretKey.hexStringtoData())
        self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString,sessionKey: sessionAuth,sessionToken:("00"+sessionToken.toHexString()).hexStringtoData())
        self.commandQueue = DispatchQueue(label: deviceId.uuidString, qos: .userInitiated)
        sendCommand(.init(.login, sessionAuth[0...3]), isCipher: .plaintext) { [weak self] res in
            guard let self = self else { return }
            self.deviceStatus = .unlocked()
        }
    }
    
    public func register(result: @escaping CHResult<CHEmpty>) {
        registerWithDevicePublicKey(result: result)
    }
}

extension CHHub3Device {
    
    func updateFirmware(result: @escaping CHResult<CBPeripheral?>) {
        sendCommand(.init(SesameItemCode.moveTo)) { response in
            result(.success(.init(input: nil)))
        }
    }
    
    func scanWifiSSID(result: @escaping CHResult<CHEmpty>) {
        if (!self.isBleAvailable(result)) { return }
        L.d("[hub3][scanWifiSSID]")
        sendCommand(.init(SesameItemCode.HUB3_ITEM_CODE_WIFI_SSID)) { payload in
            if payload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input:CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
            }
        }
    }
    
    func connectWifi(result: @escaping (CHResult<CHEmpty>)) {
        result(.success(CHResultStateBLE(input:CHEmpty())))
    }
    
    func setWifiSSID(_ ssid: String, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(SesameItemCode.HUB3_UPDATE_WIFI_SSID, ssid.data(using: .utf8))) { payload in
            if payload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input:CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
            }
        }
    }
    
    func setWifiPassword(_ password: String, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(SesameItemCode.HUB3_ITEM_CODE_WIFI_PASSWORD, password.data(using: .utf8))) { payload in
            if payload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input:CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
            }
        }
    }

}
