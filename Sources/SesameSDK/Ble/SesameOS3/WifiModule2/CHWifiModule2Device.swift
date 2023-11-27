//
//  CHWifiModule2Device.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/8/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

final class CHWifiModule2Device: CHBaseDevice, CHWifiModule2, CHDeviceUtil {
    func login(token: String? = nil) {
        guard let wifiModule2Token = wifiModule2Token,
              let secretKeyData = sesame2KeyData?.secretKey.hexStringtoData() else {
            return
        }
        deviceStatus = .bleLogining()
        commandQueue = DispatchQueue(label: "wm2-history", qos: .userInitiated)
        self.cipher = SesameOS3BleCipher(name: self.deviceId!.uuidString, sessionKey: secretKeyData,  sessionToken: wifiModule2Token)
        sendCommand(.init(.loginWM2, CC.CMAC.AESCMAC(wifiModule2Token, key: secretKeyData)), isCipher: .plaintext) { _ in}
    }

    var sesame2Keys = [String: String]() {
        didSet {
            (self.delegate as? CHWifiModule2Delegate)?.onSesame2KeysChanged(device: self, sesame2keys: sesame2Keys)
        }
    }
    
    var cipher: SesameOS3BleCipher?
    var deviceIR: String {
        let noDashUUID = deviceId.uuidString.replacingOccurrences(of: "-", with: "")
        return String(noDashUUID.prefix(24))
    }

    var isConnectedToIoT: Bool? = nil {
        didSet {
            if isConnectedToIoT != oldValue {
//                let networkStatus = (self.mechStatus as? CHWifiModule2NetworkStatus)
                self.mechStatus = CHWifiModule2NetworkStatus(isAPWork: isConnectedToIoT,
                                           isNetwork: isConnectedToIoT,
                                           isIoTWork: isConnectedToIoT,
                                           isBindingAPWork: false,
                                           isConnectingNetwork: false,
                                           isConnectingIoT: false)
            }
        }
    }
    
    var iotShadowName: String {
        deviceId.uuidString.substring(with: 24..<36)
    }

    var mechSetting: CHWifiModule2MechSettings? = CHWifiModule2MechSettings()

    var wifiModule2Token: Data?
    
    var advertisement: BleAdv? {
        didSet{
            guard let advertisement = advertisement  else {
                deviceStatus = .noBleSignal()
                return
            }
            setAdv(advertisement)

            if deviceStatus == .noBleSignal() || deviceStatus == .busy() {
                if advertisement.isConnectable == true {
                    deviceStatus = .receivedBle()
                } else {
                    deviceStatus = .busy()
                }
            } else if deviceStatus == .bleConnecting() {
                if advertisement.isConnectable == false {
                    deviceStatus = .busy()
                }
            }
        }
    }
    
    // MARK: - getVersionTag
    func getVersionTag(result: @escaping CHResult<String>) {
        if self.checkBle(result) { return }
        
        sendCommand(.init(.versionTag), isCipher: .plaintext) { response in
            if response.cmdResultCode == .success {
                let versionTag = String(data: response.data, encoding: .utf8) ?? ""
                result(.success(.init(input: versionTag)))
            } else {
                result(.failure(NSError.getVersionTagFailed))
            }
        }
    }

    // MARK: - checkBleState
    func checkBleState<T>(_ result: @escaping (CHResult<T>)) -> Bool  {
        var isOK = true
        if CHBluetoothCenter.shared.centralManager.state == .unauthorized {
            result(.failure(NSError.bleUnauthorized))
            isOK = false
        }
        
        if CHBluetoothCenter.shared.centralManager.state == .poweredOff {
            result(.failure(NSError.blePoweredOff))
            isOK = false
        }
        
        if deviceStatus.loginStatus == .unlogined {
            result(.failure(NSError.deviceNotLoggedIn))
            isOK = false
        }
        
        return isOK

    }
    
//    deinit {
//#if os(iOS)
//        CHIoTManager.shared.unsubscribeWifiModule2Shadow(self)
//#endif
//    }
}

extension CHWifiModule2Device {
    // MARK: - getSesame2s
    //    func getCHDevices(result: @escaping CHResult<CHEmpty>) {
    //        //        L.d("wm2", "sdk", "returen sesame2Keys")
    //        (self.delegate as? CHWifiModule2Delegate)?.onSesame2KeysChanged(device: self, sesame2keys: sesame2Keys)
    //        result(.success(.init(input: CHEmpty())))
    //    }
    
    // MARK: - insertSesame2
    func insertSesame2(_ sesame2: CHSesame2, result: @escaping CHResult<CHEmpty>) {
        if (self.checkBle(result)) { return }
        guard let keyData = sesame2.getKey() else {
            return
        }
        
        let noDashUUID = sesame2.deviceId.uuidString.replacingOccurrences(of: "-", with: "", options: [], range: nil)
        var base64Key = noDashUUID.hexStringtoData().base64EncodedString()
        base64Key = base64Key.replacingOccurrences(of: "=", with: "", options: [], range: nil)
        let sesame2IR = base64Key.data(using: .utf8)!
        
        let publicKey = keyData.sesame2PublicKey.hexStringtoData()
        let secretKey = keyData.secretKey.hexStringtoData()
        let deviceId = sesame2.deviceId.uuidString.uppercased().data(using: .utf8)!
        
        let allKey = sesame2IR + publicKey + secretKey + deviceId
        
        sendCommand(.init(.addSesame2, allKey)) { response in
            result(.success(.init(input: CHEmpty())))
        }
    }
    
    // MARK: - insertSesame2 (ss5 + ss5 pro insertSesame)
    func insertSesame(_ device: CHDevice, result: @escaping CHResult<CHEmpty>) {
        L.d("[wm2]添加ssm")
        if (self.checkBle(result)) { return }
        guard let keyData = device.getKey() else {
            return
        }
        
        let noDashUUID = device.deviceId.uuidString.replacingOccurrences(of: "-", with: "", options: [], range: nil)
        var base64Key = noDashUUID.hexStringtoData().base64EncodedString()
        base64Key = base64Key.replacingOccurrences(of: "=", with: "", options: [], range: nil)
        let sesame2IR = base64Key.data(using: .utf8)!
        
        
        var publicKeyData:Data
        if( keyData.deviceModel == "sesame_5" || keyData.deviceModel == "sesame_5_pro"){
            publicKeyData = "41B6D190EBBC1E9FA49E62710D80092784E998649FCA150419D2C70C6573BCA4666481EA47FDD755BB0761AB95EF95C9BD24016D54B14606EB5835541E45F27E".hexStringtoData()
        }else{
            publicKeyData = keyData.sesame2PublicKey.hexStringtoData()
        }
        let secretKeyData = keyData.secretKey.hexStringtoData()
        let deviceId = device.deviceId.uuidString.uppercased().data(using: .utf8)!
        let allKey = sesame2IR + publicKeyData + secretKeyData + deviceId
        
        sendCommand(.init(.addSesame2, allKey)) { response in
            result(.success(.init(input: CHEmpty())))
        }
    }
    
    // MARK: - dropSesame2
    func removeSesame(tag: String, result: @escaping CHResult<CHEmpty>) {
        if (self.checkBle(result)) { return }
        sendCommand(.init(.deleteSesame2, tag.data(using: .utf8))) { cmdResult in
            result(.success(.init(input: CHEmpty())))
        }
    }
    
    // MARK: - setWifiSSID
    func setWifiSSID(_ ssid: String, result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }
        sendCommand(.init(.updateWifiSSID, ssid.data(using: .utf8))) { response in
            result(.success(.init(input: CHEmpty())))
        }
    }
    
    // MARK: - setWifiPassword
    func setWifiPassword(_ password: String, result: @escaping (CHResult<CHEmpty>)) {
        //        self.setWifiPasswordResult = result
        if (self.checkBle(result)) { return }
        sendCommand(.init(.updateWifiPassword, password.data(using: .utf8))) { response in
            result(.success(.init(input: CHEmpty())))
        }
    }
    
    // MARK: - connectWifi
    func connectWifi(result: @escaping (CHResult<CHEmpty>)) {
        if (self.checkBle(result)) { return }
        sendCommand(.init(.connectWifi, "name".data(using: .utf8))) { response in
            result(.success(.init(input: .init())))
        }
    }
    
    func updateFirmware(result: @escaping CHResult<CBPeripheral?>) {
        if (self.checkBle(result)) { return }
        sendCommand(.init(.openOTAServer)) { response in
            result(.success(.init(input: nil)))
        }
    }
    
    func scanWifiSSID(result: @escaping CHResult<CHEmpty>) {
        if (self.checkBle(result)) { return }
        sendCommand(.init(.scanWifiSSID)) { response in
            result(.success(.init(input: CHEmpty())))
        }
    }
    
    func goIOT() {}
}
