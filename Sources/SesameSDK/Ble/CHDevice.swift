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
public protocol CHDevice: AnyObject {
    var delegate: CHDeviceStatusDelegate? { get set }
    var rssi: NSNumber? { get }
    var deviceId: UUID! { get }
    var isRegistered: Bool { get }
    var txPowerLevel: Int? { get }
    var productModel: CHProductModel! { get }
    var deviceStatus: CHDeviceStatus { get set}
    var deviceShadowStatus: CHDeviceStatus? { get set }
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
    func getGuestKeys(result: @escaping CHResult<[CHGuestKey]>)
    func removeGuestKey(_ guestKeyId: String, result: @escaping CHResult<CHEmpty>)
    func updateGuestKey(_ guestKeyId: String, name: String, result: @escaping CHResult<CHEmpty>)
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
            filePrefix = "sesame5pro"
        case .wifiModule2: break
        case .sesameBot:
            filePrefix = "sesamebot1"
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
        }
        var zips: [URL] = []
        if  let fileURLs = Bundle.main.urls(forResourcesWithExtension: "zip", subdirectory: nil) {
            zips = fileURLs.filter{ $0.lastPathComponent.range(of: "^\(filePrefix)", options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil }
        }
//        L.d("hcia [dfu]",zips[0])
//        L.d("hcia [dfu]",zips[0].lastPathComponent)
        return zips[0]
    }
}

internal extension CHDevice {
    func checkBle() -> Bool  {
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
        return !isOK
    }
    
    func checkBle<T>(_ result: @escaping (CHResult<T>)) -> Bool {
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
        return !isOK
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
    }

    func iotCustomVerification(result: @escaping CHResult<CHEmpty>) {}

    func getGuestKeys(result: @escaping CHResult<[CHGuestKey]>) {}

    func updateGuestKey(_ guestKeyId: String, name: String, result: @escaping CHResult<CHEmpty>) {}

    func removeGuestKey(_ guestKeyId: String, result: @escaping CHResult<CHEmpty>) {
        guard let secretKey = getKey()?.secretKey.hexStringtoData() else {
            result(.failure(NSError.noSecretKeyError))
            return
        }

        var timestamp: UInt32 = UInt32(Date().timeIntervalSince1970)
        let timestampData = Data(bytes: &timestamp,
                                 count: MemoryLayout.size(ofValue: timestamp))

        let randomTag = Data(timestampData.arrayOfBytes()[1...3])
        let keyCheck = CC.CMAC.AESCMAC(randomTag,
                                       key: secretKey)
    }
}

// MARK: - SesameLock
public protocol CHSesameLock: CHDevice {
    var mechStatus: CHSesameProtocolMechStatus? { get set }
    func getHistoryTag() -> Data?
    func setHistoryTag(_ tag: Data, result: @escaping (CHResult<CHEmpty>))
}

public extension CHSesameLock {
    func enableNotification(token: String, name: String, result: @escaping CHResult<CHEmpty>) {}
    
    func disableNotification(token: String, name: String, result: @escaping CHResult<CHEmpty>) {
        CHDeviceManager.shared.disableNotification(deviceId: deviceId.uuidString, token: token, name: name, result: result)
    }
    
    func isNotificationEnabled(token: String, name: String, result: @escaping CHResult<Bool>) {}
    
#if os(watchOS)
    func getSesameLockStatus(result: @escaping CHResult<CHEmpty>) {}
#endif 
    }

internal extension CHDevice {
    func sign(token: String, result: @escaping CHResult<String>) {
        guard let keyData = getKey() else {
            return
        }
    }
    
    func putSesameFW(_ fw: String, result: @escaping CHResult<CHEmpty>) {}
    
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
}

public protocol  CHSesameConnectorDelegate : AnyObject{
    func onSesame2KeysChanged(device: CHSesameConnector, sesame2keys: [String: String])
}
public extension CHSesameConnectorDelegate {
        func onSesame2KeysChanged(device: CHSesameConnector, sesame2keys: [String: String]){}
}

