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
        case .sesame5US:
            filePrefix = "sesame5us_"
        case .sesame6Pro:
            filePrefix = "sesame6pro_"
        case .sesame6ProSLiDingDoor:
            filePrefix = "sesame6pro_"
        case .wifiModule2: break
        case .sesameBot:
            filePrefix = "sesamebot1"
        case .sesameBot2:
            filePrefix = "sesamebot2"
        case .sesameBot3:
            filePrefix = "sesamebot2"
        case .bikeLock:
            filePrefix = "sesamebike1"
        case .bikeLock2:
            filePrefix = "sesamebike2"
        case .bikeLock3:
            filePrefix = "sesamebike3"
        case .openSensor:
            filePrefix = "opensensor1"
        case .openSensor2:
            filePrefix = "opensensor2"
        case .bleConnector:
            filePrefix = "bleconnector_"
        case .remote:
            filePrefix = "remote_"
        case .remoteNano:
            filePrefix = "remoten_"
        case .hub3:
            filePrefix = "hub3_"
        case .sesameTouch:
            filePrefix = "sesametouch1_"
        case .sesameTouch2:
            filePrefix = "sesametouch1_"
        case .sesameTouchPro:
            filePrefix = "sesametouch1pro"
        case .sesameTouch2Pro:
            filePrefix = "sesametouch1pro"
        case .sesameFace:
            filePrefix = "sesameFace1_"
        case .sesameFace2:
            filePrefix = "sesameFace1_"
        case .sesameFacePro:
            filePrefix = "sesameFace1Pro_"
        case .sesameFace2Pro:
            filePrefix = "sesameFace1Pro_"
        case .sesameFaceAI:
            filePrefix = "sesameface1ai_"
        case .sesameFace2AI:
            filePrefix = "sesameface1ai_"
        case .sesameFaceProAI:
            filePrefix = "sesameface1proai_"
        case .sesameFace2ProAI:
            filePrefix = "sesameface1proai_"
	case .sesameMiwa:
            filePrefix = "sesammiwa_"
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
    
    /// 规则：
    /// - 仅 CHSesame5：BLE 不可用才允许用 IoT mechStatus 覆盖
    /// - 其他设备：直接用 IoT mechStatus 覆盖
    func applyIotMechStatusIfNeeded(_ mechStatus: CHSesameProtocolMechStatus) {
        if self is CHSesame5 {
            if self.isBleAvailable() == false {
                self.mechStatus = mechStatus
            }
        } else {
            self.mechStatus = mechStatus
        }
    }
    
    var isLockDevice: Bool {
        self is CHSesameLock
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
    
    func isBleAvailable(withHint: Void = ()) -> (available: Bool, hintKey: String?) {
        switch CHBluetoothCenter.shared.centralManager.state {
        case .unauthorized, .poweredOff:
            return (false, "co.candyhouse.sesame2.bluetoothPoweredOff")
        default:
            break
        }
        
        if deviceStatus.loginStatus == .unlogined {
            return (false, "co.candyhouse.sesame2.noBleSignal")
        }
        
        return (true, nil)
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
    
    func postBatteryData(_ payload: String) {
        CHAPIClient.shared.postBatteryData(deviceId: deviceId.uuidString, payload: payload) { res in
            if case .failure(let error) = res {
                L.d("postBattery error", error)
            }
        }
    }
    
    // 訪客鑰匙調用, 取session token並上傳server以secretKey簽章後得到login token
    func sign(token: String, result: @escaping CHResult<String>) {
        guard let keyData = getKey() else {
            return
        }
        L.d("API:/device/v1/sesame2/sign", token, deviceId.uuidString, keyData.secretKey)
        
        CHAPIClient.shared.signDeviceToken(
            deviceId: deviceId.uuidString,
            token: token,
            secretKey: keyData.secretKey
        ) { serverResult in
            switch serverResult {
            case .success(let signedToken):
                result(.success(.init(input: signedToken.data)))
            case .failure(let error):
                L.d("sign error!")
                result(.failure(error))
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
                
                if (self.productModel == .sesame5 || self.productModel == .sesame5Pro || self.productModel == .sesame5US || self.productModel == .sesameMiwa){
                    if let mechStatusData = shadow.data.mechStatus?.hexStringtoData(),
                       let mechStatus = Sesame5MechStatus.fromData(Sesame2MechStatus.fromData(mechStatusData)!.ss5Adapter()) {
                        //                    L.d("[ss5][iot] isInLockRange",mechStatus.isInLockRange,mechStatus.position)
                        if(isConnectedByWM2){
                            if( self.deviceStatus.loginStatus == .unlogined){
                                self.mechStatus = mechStatus
                            }
                        }
                    }
                }else if (self.productModel == .bikeLock2 || self.productModel == .bikeLock3){
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

public protocol CHSesameConnector {
    var sesame2Keys: [String: String] { get }
    func insertSesame(_ device: CHDevice, result: @escaping CHResult<CHEmpty>)
    func removeSesame(tag: String, result: @escaping CHResult<CHEmpty>)
    func setRadarSensitivity(payload: Data, result: @escaping CHResult<CHEmpty>)
}

extension CHSesameConnector {
    func setRadarSensitivity(payload: Data, result: @escaping CHResult<CHEmpty>) {}
    func insertSesame(_ device: CHDevice, result: @escaping CHResult<CHEmpty>){}
    func removeSesame(tag: String, result: @escaping CHResult<CHEmpty>){}
}

public protocol  CHSesameConnectorDelegate : AnyObject{
    func onSesame2KeysChanged(device: CHSesameConnector, sesame2keys: [String: String])
    func onRadarReceive(device: CHSesameConnector, payload: Data)
    func onSlotFull(device: CHSesameConnector)
    func onSSMSupport(device: CHSesameConnector,isSupport: Bool)
}
public extension CHSesameConnectorDelegate {
    func onSesame2KeysChanged(device: CHSesameConnector, sesame2keys: [String: String]){}
    func onRadarReceive(device: CHSesameConnector, payload: Data){}
    func onSlotFull(device: CHSesameConnector){}
    func onSSMSupport(device: CHSesameConnector,isSupport: Bool){}
}
