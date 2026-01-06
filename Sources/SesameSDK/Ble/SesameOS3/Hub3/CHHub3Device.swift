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
    var status: Hub3Status = Hub3Status(
        eventType: "disconnected",
        ssks: "",
        v: "",
        hub3LastFirmwareVer: "",
        timestamp: 0,
        ts: 0,
        wifi_ssid: "",
        wifi_password: ""
    )
    
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
    
    func goIOT() {
#if os(iOS)
        getHub3StatusFromIot()
        CHIoTManager.shared.subscribeWifiModule2Shadow(self) { result in
            switch result {
            case .success(let result):
                self.wifiModule2ShadowCompleteHandler(result: result.data)
            case .failure(let error):
                L.d(error)
            }
        }
#endif
    }
    
    private func wifiModule2ShadowCompleteHandler(result: WifiModuleShadow) {
        let networkStatus = (self.mechStatus as? CHWifiModule2NetworkStatus)
        self.mechStatus = CHWifiModule2NetworkStatus(isAPWork: networkStatus?.isAPWork,
                                                        isNetwork: networkStatus?.isNetwork,
                                                        isIoTWork: result.isConnected,
                                                        isBindingAPWork: false,
                                                        isConnectingNetwork: false,
                                                        isConnectingIoT: false)
    }
    
    deinit {
#if os(iOS)
        CHIoTManager.shared.unsubscribeWifiModule2Shadow(self)
#endif
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
    
    public func register(result: @escaping CHResult<CHEmpty>)  {
        if deviceStatus != .readyToRegister() {
            result(.failure(NSError.deviceStatusNotReadyToRegister))
            return
        }
        deviceStatus = .registering()

        let date = Date()
        var timestamp: UInt32 = UInt32(date.timeIntervalSince1970)
        let timestampData = Data(bytes: &timestamp,count: MemoryLayout.size(ofValue: timestamp))
        let payload = Data(appKeyPair.publicKey)+timestampData
        self.commandQueue = DispatchQueue(label:deviceId.uuidString, qos: .userInitiated)

        CHAPIClient.shared.registerDevice(
            deviceId: self.deviceId.uuidString,
            productType: Int(advertisement!.productType!.rawValue),
            publicKey: self.mSesameToken!.toHexString()
        ) { response in
            switch response {
            case .success(_):
                self.sendCommand(.init(.registration, payload), isCipher: .plaintext) { response in
                    let ecdhSecretPre16 = Data(self.appKeyPair.ecdh(remotePublicKey: response.data[0...63].bytes))[0...15]
                    let sessionAuth = CC.CMAC.AESCMAC(self.mSesameToken!, key: ecdhSecretPre16)

                    self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString,
                                         sessionKey: sessionAuth,
                                                       sessionToken: ("00\(self.mSesameToken!.toHexString())").hexStringtoData())

                    self.sesame2KeyData = CHDeviceKey(// 建立設備
                        deviceUUID: self.deviceId,
                        deviceModel: self.productModel.deviceModel(),
                        historyTag: nil,
                        keyIndex: "0000",
                        secretKey: ecdhSecretPre16.toHexString(),
                        sesame2PublicKey: self.mSesameToken!.toHexString()
                    )
                    self.isRegistered = true // 設定為已註冊
                    self.goIOT()
                    CHDeviceCenter.shared.appendDevice(self.sesame2KeyData!) // 存到SDK層的DB中
                    self.deviceStatus = .unlocked()
                    result(.success(CHResultStateNetworks(input: CHEmpty())))
                }
            case .failure(let error):
                L.d("[ss5]register error", error)
                result(.failure(error))
                self.disconnect(){_ in}
            }
        }
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
        L.d("[hub3][setWifiSSID]", ssid)
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
        L.d("[hub3][setWifiPassword]", password)
        sendCommand(.init(SesameItemCode.HUB3_ITEM_CODE_WIFI_PASSWORD, password.data(using: .utf8))) { payload in
            if payload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input:CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
            }
        }
    }
    
    private func getHub3StatusFromIot() {
        CHAPIClient.shared.getHub3Status(deviceId: deviceId.uuidString) { [self] response in
            switch response {
            case .success(let data):
                let hub3Status = try! JSONDecoder().decode(Hub3Status.self, from: data.data)
                updateMechSettingStatusAndKeys(hub3Status)
                L.d("response string", hub3Status)
            case .failure(let error):
                L.d("getHub3StatusFromIot error", error)
            }
        }
    }
}
