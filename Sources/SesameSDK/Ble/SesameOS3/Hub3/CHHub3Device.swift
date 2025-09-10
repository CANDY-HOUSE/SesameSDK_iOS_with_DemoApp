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
    
    var hub3Brightness: UInt8 = 255
    
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
    
    func setHub3Brightness(brightness: UInt8, result: @escaping CHResult<UInt8>) {
        if (!self.isBleAvailable(result)) { return }
        L.d("[hub3][setHub3Brightness]",brightness)
        sendCommand(.init(.OPS_CONTROL, brightness.data)) { payload in
            if payload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input:brightness)))
            } else {
                result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
            }
        }
    }
    
    var sesame2Keys = [String: String]() {
        didSet {
            (self.delegate as? CHWifiModule2Delegate)?.onSesame2KeysChanged(device: self, sesame2keys: sesame2Keys)
        }
    }
    
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
    
    var progressTimer: Timer? = nil
    var progress: (current: UInt8, target: UInt8) = (current: 0, target: 0)

    override func onGattSesamePublish(_ payload: SesameOS3PublishPayload) {
        super.onGattSesamePublish(payload)
        onGattHub3Publish(payload)
    }
    
    func goIOT() {
#if os(iOS)
        getHub3StatusFromIot()
        subscribeRemoteOTAProgress()
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
        if let ver = result.v, ver.count > 0 {
            updateComplete(newVer: ver)
        }
        self.mechStatus = CHWifiModule2NetworkStatus(isAPWork: networkStatus?.isAPWork,
                                                        isNetwork: networkStatus?.isNetwork,
                                                        isIoTWork: result.isConnected,
                                                        isBindingAPWork: false,
                                                        isConnectingNetwork: false,
                                                        isConnectingIoT: false)
        if CHBluetoothCenter.shared.scanning == .bleClose() ||
            self.deviceStatus.loginStatus == .unlogined {
            self.sesame2Keys = result.sesame2Keys
        }
        (self.delegate as? CHWifiModule2Delegate)?.onSesame2KeysChanged(device: self, sesame2keys: self.sesame2Keys)
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

        let request = CHAPICallObject(.post, "/device/v1/sesame5/\(self.deviceId.uuidString)", [
            "t":advertisement!.productType!.rawValue,
            "pk":self.mSesameToken!.toHexString()
        ] as [String : Any])
//        L.d("[ss5][register] ==>")
        CHAccountManager
            .shared
            .API(request: request) { response in
                switch response {
                case .success(_):
//                    L.d("[ss5][register][ok <==]")
//                    L.d("[ss5][register][ble] ==>]")
                    self.sendCommand(.init(.registration, payload), isCipher: .plaintext) { response in
//                        L.d("[ss5][register][ble] <==]")
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
                    L.d("[ss5]register error",error)
                    result(.failure(error))
                    self.disconnect(){_ in}
                }
            }
    }
    
    /// 更新固件
    /// - Parameter result: 返回 peripheral
    func updateFirmware(result: @escaping CHResult<CBPeripheral?>) {
        if (!self.isBleAvailable()) {
            // 远程 OTA
            CHAccountManager.shared.API(request: .init(.post, "/device/v2/hub3/\(deviceId.uuidString)/firmware")) { response in
                switch response {
                case .success(_):
                    result(.success(.init(input: nil)))
                case .failure(let error):
                    result(.failure(error))
                }
            }
            return
        }
        L.d("Hub3 开始 ota 升级")
        sendCommand(.init(SesameItemCode.moveTo)) { response in
            result(.success(.init(input: nil)))
        }
    }
}

// Infrared 紅外處理
extension CHHub3Device {
    
    func getVersionTag(result: @escaping (CHResult<String>))  {
        if(!isBleAvailable(result)){return}
        sendCommand(.init(.versionTag)) { (response) in
            if response.cmdResultCode == .success {
                let versionTag = String(data: response.data, encoding: .utf8) ?? ""
                L.d("[hub3][getVersionTag =>]",versionTag)
                result(.success(CHResultStateNetworks(input: "B:\(versionTag)")))
            } else {
                result(.failure(self.errorFromResultCode(response.cmdResultCode)))
            }
        }
        CHAccountManager.shared.API(request: .init(.get, "/device/v1/version")) { response in
            if case .success(let data) = response {
                guard let conf = try? JSONSerialization.jsonObject(with: data!) as? [String: Any] else { return }
                if let data = conf["data"] as? [String: Any],
                   let versionTag = data["hub3"] {
                    result(.success(CHResultStateNetworks(input: "N:\(versionTag)")))
                }
            }
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
    
    func insertSesame(_ device: CHDevice, result: @escaping CHResult<CHEmpty>) {}
    
    func insertSesame(_ device: CHDevice, nickName: String, matterProductModel: MatterProductModel, result: @escaping CHResult<CHEmpty>) {
        if (!self.isBleAvailable(result)) { return }
        let noDashUUID = device.deviceId.uuidString.replacingOccurrences(of: "-", with: "", options: [], range: nil)
        let noDashUUIDData = noDashUUID.hexStringtoData()
        let ssmSecKa = device.getKey()!.secretKey.hexStringtoData()
        let matter = UInt8(device.productModel.rawValue).data + matterProductModel.rawValue.data
        let nickName = Data([UInt8(nickName.bytes.count)]) + nickName.bytes
        sendCommand(.init(.addSesame,noDashUUIDData + ssmSecKa + nickName + matter)) { (response) in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    
    func removeSesame(tag: String, result: @escaping CHResult<CHEmpty>) {
        if (!self.isBleAvailable(result)) { return }
        L.d("[hub3][removeSesame]",tag)
        let noDashUUID = tag.replacingOccurrences(of: "-", with: "", options: [], range: nil)
        sendCommand(.init(.removeSesame,noDashUUID.hexStringtoData())) { (response) in
            result(.success(CHResultStateNetworks(input: CHEmpty())))
        }
    }
    
    func getMatterParingCode(result: @escaping CHResult<CHHub3MatterSettings>) {
        if (!self.isBleAvailable(result)) { return }
        L.d("[hub3][getMatterParingCode]")
        sendCommand(.init(SesameItemCode.HUB3_MATTER_PAIRING_CODE)) { payload in
            if payload.cmdResultCode == .success, let resp = CHHub3MatterSettings.fromData(payload.data) {
                result(.success(CHResultStateBLE(input: resp)))
            } else {
                result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
            }
        }
    }
    
    func openMatterPairingWindow(result: @escaping CHResult<CHEmpty>) {
        if (!self.isBleAvailable(result)) { return }
        L.d("[hub3][openMatterPairingWindow]")
        sendCommand(.init(SesameItemCode.HUB3_MATTER_PAIRING_WINDOW)) { payload in
            if payload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input:CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
            }
        }
    }
    
    private func subscribeRemoteOTAProgress() {
        let topic = "hub3/ota/\(deviceId.uuidString.uppercased())/progress" // hub3/ota/00000000-055A-FD81-0D00-D432048D8781/progress
        L.d("eddy", "[hub3] getOtaProgress 訂閱主題:$topic")
        CHIoTManager.shared.subscribeTopic(topic) { [self] data in
            DispatchQueue.main.async { [self] in
                updateFirmwareProgress(data)
            }
        }
    }
    
    private func getHub3StatusFromIot() {
        CHAccountManager.shared.API(request: .init(.get, "/device/v2/hub3/\(deviceId.uuidString)/status")) { [self] response in
            switch response {
            case .success(let resultData):
                guard let data = resultData else {
                    return
                }
                let hub3Status = try! JSONDecoder().decode(Hub3Status.self, from: data)
                updateMechSettingStatusAndKeys(hub3Status)
                L.d("response string", hub3Status)
            case .failure(let error):
                L.d("getHub3StatusFromIot error", error)
            }
        }
    }
}
