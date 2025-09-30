//
//  CHBluetoothCenter.swift
//  SesameSDK
//
//  Created by tse on 2023/5/9.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import CoreBluetooth

public class CHBluetoothCenter: NSObject {

    public static let shared = CHBluetoothCenter()
    public weak var delegate: CHBleManagerDelegate?{
        didSet{
            L.d("CHBleManagerDelegate delegate")//todo check 會不會重覆連
            deviceMap =  deviceMap.filter{
                $1.isRegistered
            }
        }
    }
    public weak var statusDelegate: CHBleStatusDelegate?

    var centralManager: CBCentralManager!
    var deviceMap = SafeDictionary<String, CHDevice>()

    private var scanEnabled = false
    private var discoverUnregisterTimer: Timer?

    public private(set) var scanning: CHScanStatus = CHScanStatus.bleClose() {
        didSet {
            statusDelegate?.didScanChange(status: scanning)
        }
    }

    override init() {
        super.init()
//        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .background), options: [CBCentralManagerOptionShowPowerAlertKey: false])
//        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(), options: [CBCentralManagerOptionShowPowerAlertKey: false])
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue(label: "CentralManager"), options: [CBCentralManagerOptionShowPowerAlertKey: false])

        discoverUnregisterTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
    }

    public func disableScan(result: @escaping (CHResult<CHEmpty>)) {
        scanEnabled = false
        switch centralManager.state {
        case .poweredOff:
            scanning = .disable(bleStatus: .closed)
        case .poweredOn:
            scanning = .disable(bleStatus: .opened)
        case .resetting:
            scanning = .disable(bleStatus: .closed)
        case .unauthorized:
            scanning = .disable()
        case .unknown:
            scanning = .disable()
        case .unsupported:
            scanning = .disable()
        @unknown default:
            scanning = .disable()
        }

        if centralManager.state == .poweredOn {
            centralManager.stopScan()
        }
        result(.success(CHResultStateBLE(input: CHEmpty())))
    }

    // MARK: - enableScan
    public func enableScan(result: @escaping (CHResult<CHEmpty>)) {
        scanEnabled = true//wait for scanForPeripherals

        switch centralManager.state {
        case .poweredOff:
            scanning = .enable(bleStatus: .closed)
        case .poweredOn:
            scanning = .enable(bleStatus: .opened)
        case .resetting:
            scanning = .enable(bleStatus: .closed)
        case .unauthorized:
            scanning = .enable()
        case .unknown:
            scanning = .enable()
        case .unsupported:
            scanning = .enable()
        @unknown default:
            scanning = .enable()
        }

        if centralManager.isScanning {
            result(.success(CHResultStateBLE(input: CHEmpty())))
            return
        }
        if centralManager.state == .poweredOn {
            result(.success(CHResultStateBLE(input: CHEmpty())))
            centralManager.scanForPeripherals(withServices: [CBUUID(string: "0xFD81")], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        } else {
            result(.failure(NSError.blePoweredOff))
        }
    }

    // MARK: - disConnectAll
    public func disConnectAll(result: @escaping (CHResult<CHEmpty>)) {
        guard centralManager.state == .poweredOn else {
            result(.success(CHResultStateBLE(input: CHEmpty())))
            return
        }
        for device in deviceMap.values {
            device.disconnect { _ in }
        }
        result(.success(CHResultStateBLE(input: CHEmpty())))
    }
}

// MARK: - CBCentralManagerDelegate
extension CHBluetoothCenter: CBCentralManagerDelegate {
    // MARK: - centralManagerDidUpdateState
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            if scanEnabled {
                scanning = .enable(bleStatus: .opened)
                enableScan { _ in }
            } else {
                scanning = .disable(bleStatus: .opened)
            }
        } else if central.state == .poweredOff {
            scanning = .bleClose()
            for var device in deviceMap.values.compactMap({ $0 as? CHDeviceUtil }) {
                device.advertisement = nil
            }
        } else if central.state == .unauthorized {
            scanning = .disable()
        }
    }

    @objc private func runTimedCode() {
        delegate?.didDiscoverUnRegisteredCHDevices(
            deviceMap.filterValues { $0.isRegistered == false && $0.rssi != nil }
        )
    }
}

extension CHBluetoothCenter: CBPeripheralDelegate {

    public func centralManager(_ central: CBCentralManager,  didDiscover peripheral: CBPeripheral,advertisementData: [String: Any],  rssi RSSI: NSNumber) {/// 收廣播

        let deviceAdv = BleAdv(advertisementData: advertisementData, rssi: RSSI, peripheral: peripheral)
        guard let deviceId = deviceAdv.deviceID else { return }
        var device = deviceMap.getOrPut(deviceId.uuidString, backup: deviceAdv.productType!.chDeviceFactory()) as? CHDeviceUtil
        device?.advertisement = deviceAdv

    }

    public func centralManager(_ central: CBCentralManager,
                               didConnect peripheral: CBPeripheral) {
        var device = deviceMap.values.compactMap({ $0 as? CHDeviceUtil }).filter({ $0.advertisement?.mPeripheral == peripheral }).first
        device?.deviceStatus = .waitingGatt()
        device?.advertisement?.mPeripheral.discoverServices(nil)
    }

    public func centralManager(_ central: CBCentralManager,
                               didDisconnectPeripheral peripheral: CBPeripheral,
                               error: Error?) {
        var device = deviceMap.values.compactMap({ $0 as? CHDeviceUtil }).filter({ $0.advertisement?.mPeripheral == peripheral }).first
        device?.advertisement = nil

    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        var device = deviceMap.values.compactMap({ $0 as? CHDeviceUtil }).filter({ $0.advertisement?.mPeripheral == peripheral }).first
        device?.deviceStatus = .receivedBle()
        if error != nil, let chDevice = device as? CHDevice {
            L.d(chDevice.deviceId.uuidString, "🚢->💣跟\(chDevice.productModel.deviceModel())Connect錯誤!", error as Any, "deviceStatus")
        }
    }
}

public enum CHScanStatus: Equatable {
    case enable(bleStatus: CHBleStatus = CHBleStatus.opened)
    case disable(bleStatus: CHBleStatus = CHBleStatus.opened)
    case error(bleStatus: CHBleStatus = CHBleStatus.opened)
    case bleClose(bleStatus: CHBleStatus = CHBleStatus.closed)

    public var bleStatus: CHBleStatus {
        switch self {
        case .enable(bleStatus: let bleStatus):
            return bleStatus
        case .disable(bleStatus: let bleStatus):
            return bleStatus
        case .bleClose(bleStatus: let bleStatus):
            return bleStatus
        case .error(bleStatus: let bleStatus):
            return bleStatus
        }
    }

    public var plainText: String {
        switch self {
        case .enable(bleStatus: let bleStatus):
            return "enable, \(bleStatus.rawValue)"
        case .disable(bleStatus: let bleStatus):
            return "disable, \(bleStatus.rawValue)"
        case .bleClose(bleStatus: let bleStatus):
            return "bleClose, \(bleStatus.rawValue)"
        case .error(bleStatus: let bleStatus):
            return "error, \(bleStatus.rawValue)"
        }
    }
}

public enum CHBleStatus: String {
    case opened
    case closed
}

public protocol CHBleStatusDelegate: AnyObject {
    func didScanChange(status: CHScanStatus)
}

public protocol CHBleManagerDelegate: AnyObject {
    func didDiscoverUnRegisteredCHDevices(_ devices: [CHDevice])
}
public extension CHBleManagerDelegate {
    func didDiscoverUnRegisteredCHDevices(_ devices: [CHDevice]) {}
}

public enum MatterProductModel: UInt8 {
    case doorLock = 0x00
    case onOffSwitch = 0x01
    case none = 0xff
}

public enum CHProductModel: UInt16 ,CaseIterable{
    case sesame2 = 0
    case wifiModule2 = 1
    case sesameBot = 2
    case bikeLock = 3
    case sesame4 = 4
    case sesame5 = 5
    case bikeLock2 = 6
    case sesame5Pro = 7
    case openSensor = 8
    case sesameTouchPro = 9
    case sesameTouch = 10
    case bleConnector = 11
    case hub3 = 13
    case remote = 14
    case remoteNano = 15
    case sesame5US = 16
    case sesameBot2 = 17
    case sesameFacePro = 18
    case sesameFace = 19
    case sesame6Pro = 21
    case sesameFaceProAI = 22
    case sesameFaceAI = 23
    case openSensor2 = 24

    public func deviceModel() -> String {///絕對不要動。ios/server/android必須一致
        switch self {
        case .sesame2: return "sesame_2"
        case .wifiModule2: return "wm_2"
        case .sesameBot: return "ssmbot_1"
        case .bikeLock: return "bike_1"
        case .bikeLock2: return "bike_2"
        case .sesame4: return "sesame_4"
        case .sesame5: return "sesame_5"
        case .sesame5Pro: return "sesame_5_pro"
        case .openSensor: return "open_sensor_1"
        case .sesameTouchPro: return "ssm_touch_pro"
        case .sesameTouch: return "ssm_touch"
        case .bleConnector: return "BLE_Connector_1"
        case .hub3: return "hub_3"
        case .remote: return "remote"
        case .remoteNano: return "remote_nano"
        case .sesame5US: return "sesame_5_us"
        case .sesameBot2: return "bot_2"
        case .sesameFace: return "sesame_face"
        case .sesameFacePro: return "sesame_face_Pro"
        case .sesame6Pro: return "sesame_6_pro"
        case .sesameFaceProAI: return "sesame_face_pro_ai"
        case .sesameFaceAI: return "sesame_face_ai"
        case .openSensor2: return "open_sensor_2"
        }
    }
    public func deviceModelName() -> String {//android必須一致
        switch self {
        case .sesame2: return "Sesame 3"
        case .wifiModule2: return "WiFi Module 2"
        case .sesameBot: return "Sesame Bot 1"
        case .bikeLock: return "Sesame Bike 1"
        case .bikeLock2: return "Sesame Bike 2"
        case .sesame4: return "Sesame 4"
        case .sesame5: return "Sesame 5"
        case .sesame5Pro: return "Sesame 5 Pro"
        case .openSensor: return "Open Sensor 1"
        case .sesameTouchPro: return "Sesame Touch 1 Pro"
        case .sesameTouch: return "Sesame Touch 1"
        case .bleConnector: return "BLE Connector"
        case .hub3: return "Hub 3"
        case .remote: return "Remote"
        case .remoteNano: return "Remote Nano"
        case .sesame5US: return "Sesame 5 US"
        case .sesameBot2: return "Sesame Bot 2"
        case .sesameFace: return "Sesame Face 1"
        case .sesameFacePro: return "Sesame Face 1 Pro"
        case .sesame6Pro: return "Sesame 6 Pro"
        case .sesameFaceProAI: return "Sesame Face 1 Pro AI"
        case .sesameFaceAI: return "Sesame Face 1 AI"
        case .openSensor2: return "Open Sensor 2"
        }
    }

    func chDeviceFactory() -> CHDevice {
        switch self {
        case .sesame2: return CHSesame2Device()
        case .sesame4: return CHSesame2Device()
        case .wifiModule2: return CHWifiModule2Device()
        case .sesameBot: return CHSesameBotDevice()
        case .bikeLock: return CHSesameBikeDevice()
        case .bikeLock2: return CHSesameBike2Device()
        case .sesame5, .sesame5US: return CHSesame5Device()
        case .sesame5Pro: return CHSesame5Device()
        case .openSensor: return CHSesameTouchProDevice()
        case .sesameTouchPro: return CHSesameTouchProDevice()
        case .sesameTouch: return CHSesameTouchDevice()
        case .remote, .remoteNano: return CHSesameTouchProDevice()
        case .hub3: return CHHub3Device()
        case .sesameBot2: return CHSesameBot2Device()
        case .sesameFace:return CHSesameFaceDevice()
        case .sesameFacePro:  return CHSesameFaceProDevice()
        case .sesame6Pro:  return CHSesame5Device()
        case .sesameFaceProAI:  return CHSesameFaceProDevice()
        case .sesameFaceAI:  return CHSesameFaceProDevice()
        case .bleConnector: return CHSesame5Device()
        case .openSensor2: return CHSesameTouchProDevice()
        }
     
    }
    static func deviceModeulFromString(_ type: String) -> CHProductModel? {
        for model in CHProductModel.allCases {
            if(type == model.deviceModel()){
                return model
            }
        }
        return nil
    }
}

internal class BleAdv {
    var deviceID: UUID?
    var connectCount: UInt8? = 0

    var manufacturerData: Data  = Data()
    var rssi: NSNumber = 0
    var txPowerLevel = 0

    var isRegistered: Bool = false
    var adv_tag_b1: Bool = false
    var productType: CHProductModel?
    var mPeripheral:CBPeripheral
    var mAdvertisementData:[String: Any]
    var timestamp: Double?
    var isConnectable: Bool?

    init(advertisementData: [String: Any], rssi: NSNumber,peripheral:CBPeripheral)  {
        mPeripheral = peripheral
        mAdvertisementData = advertisementData
        self.rssi = rssi
        if let connectable = advertisementData[CBAdvertisementDataIsConnectable] as? Int {
            self.isConnectable = (connectable == 0) ? false : true
        }
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            self.manufacturerData = manufacturerData

            isRegistered = manufacturerData[4] & 1 > 0
            adv_tag_b1 = manufacturerData[4] & 2 > 0
            // 保留位暫時統一廢棄
            productType = CHProductModel.init(rawValue: UInt16(manufacturerData[2]))
            if let productModel = productType {
                switch productModel{

                case .sesame2, .sesame4 , .sesameBot ,.bikeLock:
                    if let b64IR = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? UserDefaults.standard.string(forKey: peripheral.identifier.uuidString) {
                        if let uuid = Data(base64Encoded: b64IR + "==")?.toHexString().noDashtoUUID() {
                            deviceID = uuid
                            UserDefaults.standard.setValue(b64IR, forKey: peripheral.identifier.uuidString)
                        }
                    }
                case .wifiModule2:
                    if let advData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
                       advData.count >= 8 {
                        let macAddress = advData.copyData[5...10].toHexString()
                        deviceID = ("00000000055afd810001" + macAddress).noDashtoUUID()
                        if advData.count == 12 {
                            connectCount = advData.last
                        }
                    } else {
                        deviceID = "00000000055afd810001000000000000".noDashtoUUID()
                    }
                case .hub3:
                    isRegistered = manufacturerData[3] & 1 > 0
                    let macAddress = manufacturerData.copyData[4...9].toHexString()
                    deviceID = ("00000000055afd810d00" + macAddress).noDashtoUUID()
                case .sesame5, .sesame5Pro, .sesameTouchPro, .sesameTouch, .bikeLock2, .openSensor, .bleConnector, .remote, .remoteNano, .sesame5US, .sesameBot2, .sesameFace, .sesameFacePro, .sesame6Pro, .sesameFaceAI, .sesameFaceProAI, .openSensor2:
                    deviceID = manufacturerData[5...20].toHexString().noDashtoUUID()
                }
            }
            if let txPowerLevel = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int {
                self.txPowerLevel = txPowerLevel
            }
        }
    }
}
