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
    func onBatteryPercentageChanged(device: CHDevice, percentage: Int)
    func onBleTxPowerReceive(device: CHDevice, txPower: UInt8)
}
public extension CHDeviceStatusDelegate {
    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus, shadowStatus: CHDeviceStatus?) {}
    func onMechStatus(device: CHDevice) {}
    func onBatteryPercentageChanged(device: CHDevice, percentage: Int) {}
    func onBleTxPowerReceive(device: CHDevice, txPower: UInt8) {}
}

// MARK: - CHDevice
public protocol CHDeviceStatusAndKeysDelegate: CHDeviceStatusDelegate, CHWifiModule2Delegate {}
public let CHDeviceUnsetBleTxPowerValue: UInt8 = 21
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
    var bleTxPower: UInt8 { get set }
    func setBleTxPower(txPower: UInt8, result: @escaping (CHResult<CHEmpty>))
}

public extension CHDevice {
    func getKey() -> CHDeviceKey? { return ( self as? CHDeviceUtil)?.sesame2KeyData?.copy()  as? CHDeviceKey }
    
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

    /// 用服务端 list 的 stateInfo 直接写入设备状态,替代冷启动的 IoT 快照拉取
    /// (锁的 getShadow、Hub3 的 getHub3Status)。stateInfo 不含 isStop/target 等精确位,
    /// 只能近似,等 BLE/MQTT 补精。
    func applyServerState(_ stateInfo: [String: Any]) {
        let wm2Connected = stateInfo["wm2State"] as? Bool ?? false
        if self is CHWifiModule2 {
            self.mechStatus = CHWifiModule2NetworkStatus(isAPWork: wm2Connected,
                                                         isNetwork: wm2Connected,
                                                         isIoTWork: wm2Connected,
                                                         isBindingAPWork: false,
                                                         isConnectingNetwork: false,
                                                         isConnectingIoT: false)
            if let hub3 = self as? CHHub3Device,
               let relayStatus = stateInfo["relayStatus"] as? Int {
                hub3.isRelayOn = (relayStatus == 1)
            }
            return
        }

        // Touch / Face 连接器:用服务端状态恢复 WiFi 在线状态
        if let biometricDevice = self as? CHSesameBiometricDevice {
            switch biometricDevice.deviceType {
            case .sesameTouch, .sesameTouchPro, .sesameFace, .sesameFacePro, .sesameFaceAI, .sesameFaceProAI:
                deviceShadowStatus = wm2Connected
                    ? ((mechStatus?.isInLockRange == true) ? .locked() : .unlocked())
                    : nil
                return
            default:
                break
            }
        }

        // 锁类:角度 + 锁态
        applyServerWM2Connected(wm2Connected)
        guard wm2Connected else {
            deviceShadowStatus = nil
            return
        }
        let isLocked: Bool?
        switch stateInfo["CHSesame2Status"] as? String {
        case "locked": isLocked = true
        case "unlocked": isLocked = false
        default: isLocked = nil
        }
        guard let isLocked = isLocked else { return }
        let flags: UInt8 = isLocked ? 2 : 4 // bit1 isInLockRange / bit2 isInUnlockRange
        let position = stateInfo["position"] as? Int
        let serverMechStatus: CHSesameProtocolMechStatus?
        if self is CHSesameBike2 {
            serverMechStatus = CHSesameBike2MechStatus(battery: 0, flags: flags | 4)
        } else if self is CHSesameLock {
            let pos = Int16(truncatingIfNeeded: (position ?? 0) * 360 / 1024)
            serverMechStatus = Sesame5MechStatus(battery: 0, target: pos, position: pos, flags: flags | 16)
        } else {
            serverMechStatus = nil // Bot2 等无角度环,仅用 deviceShadowStatus
        }
        if let serverMechStatus = serverMechStatus {
            applyIotMechStatusIfNeeded(serverMechStatus)
        }
        deviceShadowStatus = isLocked ? .locked() : .unlocked()
    }

    private func applyServerWM2Connected(_ connected: Bool) {
        if let device = self as? CHSesame5Device {
            device.isConnectedByWM2 = connected
        } else if let device = self as? CHSesameBike2Device {
            device.isConnectedByWM2 = connected
        } else if let device = self as? CHSesameBot2Device {
            device.isConnectedByWM2 = connected
        }
    }

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
    func setBleTxPower(txPower: UInt8, result: @escaping (CHResult<CHEmpty>)) {
        result(.failure(NSError.notSupported))
    }
    
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
        if let key = (self as? CHDeviceUtil)?.sesame2KeyData {
            key.historyTag = historyTag
            CHBleSupport.keys.save(key)
        }
        result(.success(CHResultStateNetworks(input: CHEmpty())))
    }

    func getHistoryTag() -> Data? {
        return (self as? CHDeviceUtil)?.sesame2KeyData?.historyTag?.copyData
    }
    
    func postBatteryData(_ payload: String, result: @escaping CHResult<Int>) {
        CHBleSupport.host.postBatteryData(deviceId: deviceId, payload: payload, result: result)
    }

    func sign(token: String, result: @escaping CHResult<String>) {
        guard let keyData = getKey() else {
            result(.failure(NSError.noDataError))
            return
        }
        CHBleSupport.host.signGuestKey(deviceId: deviceId, token: token, secretKey: keyData.secretKey, result: result)
    }
}

// MARK: - SesameLock
public protocol CHSesameLock: CHDevice {
    var mechStatus: CHSesameProtocolMechStatus? { get set }
    func getHistoryTag() -> Data?
    func setHistoryTag(_ tag: Data, result: @escaping (CHResult<CHEmpty>))
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
