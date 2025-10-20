//
//  CHDevice.swift
//  SesameSDK
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol CHDeviceStatusDelegate: AnyObject {
    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus, shadowStatus: CHDeviceStatus?)
    func onMechStatus(device: CHDevice)
}
public extension CHDeviceStatusDelegate {
    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus, shadowStatus: CHDeviceStatus?) {}
    func onMechStatus(device: CHDevice) {}
}

// MARK: - CHDevice
public protocol CHDeviceStatusAndKeysDelegate: CHDeviceStatusDelegate, CHWifiModule2Delegate {}
public protocol CHDevice: AnyObject {
    var delegate: CHDeviceStatusDelegate? { get set }
    var multicastDelegate: CHMulticastDelegate<CHDeviceStatusAndKeysDelegate> { get set }
    var rssi: NSNumber? { get }
    var deviceId: UUID! { get }
    var isRegistered: Bool { get }
    var txPowerLevel: Int? { get }
    var productModel: CHProductModel! { get }
    var deviceStatus: CHDeviceStatus { get set}
    var deviceShadowStatus: CHDeviceStatus? { get set}
    func getKey() -> CHDeviceKey?
    func connect(result: @escaping (CHResult<CHEmpty>))
    func dropKey(result: @escaping (CHResult<CHEmpty>))
    func disconnect(result: @escaping (CHResult<CHEmpty>))
    func getVersionTag(result: @escaping (CHResult<String>))
    func updateFirmware(result: @escaping CHResult<CBPeripheral?>)
    var mechStatus: CHSesameProtocolMechStatus? { get set}
    func getTimeSignature() -> String
//    #if os(iOS)
    func reset(result: @escaping CHResult<CHEmpty>)
    func register(result: @escaping CHResult<CHEmpty>)
    func createGuestKey(result: @escaping CHResult<String>)
//    #endif
}

public extension CHDevice {
    func getKey() -> CHDeviceKey? { return ( self as? CHDeviceUtil)?.sesame2KeyData?.copy()  as? CHDeviceKey }

    func getFirZip() -> URL {
        var filePrefix = ""
        switch productModel! {
        case .sesame2:
            filePrefix = "sesame_2"
        case .sesame4:
            filePrefix = "sesame_4"
        case .sesame5:
            filePrefix = "sesame5_"
        case .sesame5Pro:
            filePrefix = "sesame5pro_"
        case .wifiModule2: break
        case .sesameBot:
            filePrefix = "sesamebot1"
        case .sesameBot2:
            filePrefix = "sesamebot2"
        case .bikeLock:
            filePrefix = "sesamebike1"
        case .bikeLock2:
            filePrefix = "sesamebike2"
        case .openSensor:
            filePrefix = "opensensor1"
        case .sesameTouchPro:
            filePrefix = "sesametouch1pro"
        case .sesameTouch:
            filePrefix = "sesametouch1_"
        case .bleConnector:
            filePrefix = "bleconnector_"
        case .remote:
            filePrefix = "remote_"
        case .remoteNano:
            filePrefix = "remoten_"
        case .sesame5US:
            filePrefix = "sesame5us_"
        case .hub3:
            filePrefix = "hub3_"
        case .sesameFace:
            filePrefix = "sesameFace1_"
        case .sesameFacePro:
            filePrefix = "sesameFace1Pro_"
        case .sesame6Pro:
            filePrefix = "sesame6pro_"
        case .sesameFaceAI:
            filePrefix = "sesameface1ai_"
        case .sesameFaceProAI:
            filePrefix = "sesameface1proai_"
        case .openSensor2:
            filePrefix = "opensensor2"
        }
        var zips: [URL] = []
        if  let fileURLs = Bundle.main.urls(forResourcesWithExtension: "zip", subdirectory: nil) {
            zips = fileURLs.filter{ $0.lastPathComponent.range(of: "^\(filePrefix)", options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil }
        }
        guard let file = zips.first else {
            L.d("Missing Firmware files. Must be added to the project and included in Copy Bundle Resources")
            return URL(fileURLWithPath: "")
        }
        return file
    }
}

public extension CHDevice {
    
    func isBleAvailable() -> Bool  {
        var isOK = true
        if (CHBluetoothCenter.shared.centralManager.state == .unauthorized) {
            isOK = false
        }
        if (CHBluetoothCenter.shared.centralManager.state == .poweredOff) {
            isOK = false
        }
        if self.deviceStatus.loginStatus == .unlogined {
            isOK = false
        }
        return isOK
    }
    
    func isBleAvailable<T>(_ result: @escaping (CHResult<T>)) -> Bool {
        var isOK = true
        if (CHBluetoothCenter.shared.centralManager.state == .unauthorized) {
            result(.failure(NSError.bleUnauthorized))
            isOK = false
        } else if (CHBluetoothCenter.shared.centralManager.state == .poweredOff) {
            result(.failure(NSError.blePoweredOff))
            isOK = false
        } else if deviceStatus.loginStatus == .unlogined {
            result(.failure(NSError.deviceNotLoggedIn))
            isOK = false
        }
        return isOK
    }
}

internal extension CHDevice {
    func errorFromResultCode(_ resultCode: SesameResultCode) -> Error {
        if let error = SesameResultCode(rawValue: resultCode.rawValue) {
            return error
        } else {
            let error = NSError(domain: "Sesame2SDK",
                                code: Int(resultCode.rawValue),
                                userInfo: ["message": resultCode.plainName])
            return error
        }
    }
    
    func getTimeSignature() -> String {
        if let key = getKey()?.secretKey {
            let sign = CC.CMAC.AESCMACWithTime(key.hexStringtoData())
            return sign[0...3].toHexString()
        } else {
            return "0000"
        }
    }

    func setHistoryTag(_ tag: Data, result: @escaping (CHResult<CHEmpty>)) {
        let historyTag = (tag.count > 21) ? tag[0...20].copyData : tag
//        L.d("標籤, setHistoryTag=>", historyTag)
        (self as? CHDeviceUtil)?.sesame2KeyData?.historyTag = historyTag
        CHDeviceCenter.shared.getDevice(deviceID: deviceId)?.historyTag = historyTag
        CHDeviceCenter.shared.saveifNeed()
        result(.success(CHResultStateNetworks(input: CHEmpty())))
    }

    func getHistoryTag() -> Data? {
        return (self as? CHDeviceUtil)?.sesame2KeyData?.historyTag?.copyData
    }

    func createGuestKey(result: @escaping CHResult<String>) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let deviceKey = getKey() //返回CHDeviceKey
        let jsonData = try! encoder.encode(deviceKey)
        var data = try! JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd HH:mm"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        data["keyName"] = dateFormatter.string(from: date)
        CHAccountManager.shared.API(request: .init(.post, "/device/v1/sesame2/\(deviceId.uuidString)/guestkey", data)) { postResult in
            switch postResult {
            case .success(let data):
//                L.d("test",data) //["test", Optional(34 bytes)] todo 金表示这里会crash!
                let decoder = JSONDecoder()
                let guestKey = try! decoder.decode(String.self, from: data!)
                result(.success(.init(input: guestKey)))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }

    // 訂閱IoT主題前必需調用驗證
    func iotCustomVerification(result: @escaping CHResult<CHEmpty>) {
        CHAccountManager.shared.API(request: .init(.get, "/device/v1/iot/sesame2/\(deviceId.uuidString)", queryParameters: ["a": getTimeSignature()])) { verifyResult in
            switch verifyResult {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    func postBatteryData(_ payload: String) {
        CHAccountManager.shared.API(request: .init(.post, "/device/v2/sesame5/\(deviceId.uuidString)/battery", ["payload": payload])) { res in
            if case .failure(let error) = res {
                L.d("postBattery error", error)
            }
        }
    }
}

// MARK: - SesameLock
public protocol CHSesameLock: CHDevice {
    var mechStatus: CHSesameProtocolMechStatus? { get set }
    func getHistoryTag() -> Data?
    func setHistoryTag(_ tag: Data, result: @escaping (CHResult<CHEmpty>))
}

public extension CHSesameLock {
#if os(watchOS)
    func getSesameLockStatus(result: @escaping CHResult<CHEmpty>) {
        CHIoTManager.shared.getCHDeviceShadow(self) { shadowResult in
            switch shadowResult {
            case .success(let shadow):
                
                var isConnectedByWM2 = false
                if let wm2s = shadow.data.wifiModule2s {
                    isConnectedByWM2 = wm2s.filter({ $0.isConnected == true }).count > 0
                }
                
                if (self.productModel == .sesame5 || self.productModel == .sesame5Pro || self.productModel == .sesame5US){
                    if let mechStatusData = shadow.data.mechStatus?.hexStringtoData(),
                       let mechStatus = Sesame5MechStatus.fromData(Sesame2MechStatus.fromData(mechStatusData)!.ss5Adapter()) {
                        //                    L.d("[ss5][iot] isInLockRange",mechStatus.isInLockRange,mechStatus.position)
                        if(isConnectedByWM2){
                            if( self.deviceStatus.loginStatus == .unlogined){
                                self.mechStatus = mechStatus
                            }
                        }
                    }
                }else if self.productModel == .bikeLock2{
                    if let mechStatusData = shadow.data.mechStatus?.hexStringtoData(),
                       let mechStatus = CHSesameBike2MechStatus.fromData(Sesame2MechStatus.fromData(mechStatusData)!.ss5Adapter()){
                        if(isConnectedByWM2){
                            if( self.deviceStatus.loginStatus == .unlogined){
                                self.mechStatus = mechStatus
                            }
                        }
                    }
                }else{
                        if let mechStatusData = shadow.data.mechStatus?.hexStringtoData(),
                           let mechStatus = Sesame2MechStatus.fromData(mechStatusData) {
                            if (isConnectedByWM2) {
                                if( self.deviceStatus.loginStatus == .unlogined){
                                    self.mechStatus = mechStatus
                                }
                            }
                        }
                    }
                    
                    if isConnectedByWM2 { //
                        self.deviceShadowStatus = (self.mechStatus?.isInLockRange == true) ? .locked() : .unlocked()
                    }else{
                        self.deviceShadowStatus = nil
                    }
                    L.d("⌚️iot",isConnectedByWM2,self.deviceStatus,self.deviceShadowStatus,(self.mechStatus?.isInLockRange == true) )
                    //                self.delegate?.onBleDeviceStatusChanged(device: self, status: self.deviceStatus, shadowStatus: self.deviceShadowStatus)
                    
                    result(.success(.init(input: .init())))
                case .failure(let error):
                    L.d("⌚️ error",error)
                    self.deviceShadowStatus = nil
                    //               self.delegate?.onBleDeviceStatusChanged(device: self, status: self.deviceStatus, shadowStatus: self.deviceShadowStatus)
                    
                    result(.failure(error))
                }
            }
        }
#endif 
    }

internal extension CHDevice {
    // 訪客鑰匙調用, 取session token並上傳server以secretKey簽章後得到login token
    func sign(token: String, result: @escaping CHResult<String>) {
        guard let keyData = getKey() else {
            return
        }
        L.d("API:/device/v1/sesame2/sign",token, deviceId.uuidString,keyData.secretKey)
        
        CHAccountManager.shared.API(request: .init(.post, "/device/v1/sesame2/sign", ["deviceId": deviceId.uuidString, "token": token, "secretKey": keyData.secretKey])) { serverResult in
            switch serverResult {
            case .success(let data):
                let signedToken = String(data: data!, encoding: .utf8)!
                //                L.d("sign ok:",signedToken)
                result(.success(.init(input: signedToken)))
            case .failure(let error):
                L.d("sign error!")
                
                result(.failure((error)))
            }
        }
    }
    
    // IoT只驗證一次
    func isServerAuthed() -> Bool {
        let authKey = "iot\(self.getKey()!.secretKey.substring(to: 8))"
        let deviceCache = UserDefaults.standard.dictionary(forKey: self.deviceId.uuidString) ?? [:]
        let authedKeys = deviceCache["authedKeys"] as? [String] ?? []
        return authedKeys.contains(authKey)
    }
    
    func setServerAuthed() {
        let authKey = "iot\(self.getKey()!.secretKey.substring(to: 8))"
        var deviceCache = UserDefaults.standard.dictionary(forKey: self.deviceId.uuidString) ?? [:]
        var authedKeys = deviceCache["authedKeys"] as? [String] ?? []
        if !authedKeys.contains(authKey) {
            authedKeys.append(authKey)
            deviceCache["authedKeys"] = authedKeys
            UserDefaults.standard.setValue(deviceCache, forKey: self.deviceId.uuidString)
        }
    }
}

public protocol CHSesameConnector {
    var sesame2Keys: [String: String] { get }
    func insertSesame(_ device: CHDevice, result: @escaping CHResult<CHEmpty>)
    func removeSesame(tag: String, result: @escaping CHResult<CHEmpty>)
    func setRadarSensitivity(payload: Data, result: @escaping CHResult<CHEmpty>)
}

extension CHSesameConnector {
    func setRadarSensitivity(payload: Data, result: @escaping CHResult<CHEmpty>) {}
}

public protocol  CHSesameConnectorDelegate : AnyObject{
    func onSesame2KeysChanged(device: CHSesameConnector, sesame2keys: [String: String])
    func onRadarReceive(device: CHSesameConnector, payload: Data)
}
public extension CHSesameConnectorDelegate {
    func onSesame2KeysChanged(device: CHSesameConnector, sesame2keys: [String: String]){}
    func onRadarReceive(device: CHSesameConnector, payload: Data){}
}
