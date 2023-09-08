//
//  CHBaseDevice.swift
//  SesameSDK
//
//  Created by tse on 2023/5/9.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import CoreBluetooth

class CHBaseDevice: NSObject, CBPeripheralDelegate {
    var cmdCallBack: [SesameItemCode: SesameOS3ResponseCallback] = [:]//os3
    var onResponse: Sesame2ResponseCallback?//os2
    var onResponseWm2: WifiModule2ResponseCallback?
    var productModel: CHProductModel!
    var commandQueue:DispatchQueue! {
        didSet {
            self.semaphoreSesame = DispatchSemaphore(value: 0)
            self.semaphoreSesame?.signal()
            cmdCallBack = [:]
        }
    }
    var gattRxBuffer: SesameBleReceiver = SesameBleReceiver()
    var gattTxBuffer: SesameBleTransmiter?
    var semaphoreSesame: DispatchSemaphore!
    var isGuestKey = false
    var sesame2KeyData: CHDeviceKey? {
        didSet {
            if let sesame2KeyData = sesame2KeyData {
                self.deviceId = sesame2KeyData.deviceUUID
                self.isGuestKey = String(sesame2KeyData.secretKey.substring(to: 16)) == "0000000000000000" ? true : false
            }
        }
    }
    var delegate: CHDeviceStatusDelegate?
    var deviceStatus: CHDeviceStatus = .noBleSignal() {
        didSet{
            if oldValue != deviceStatus {
                self.delegate?.onBleDeviceStatusChanged(device: self as! CHDevice, status: self.deviceStatus,shadowStatus: self.deviceShadowStatus)
            }
        }
    }
    var deviceShadowStatus: CHDeviceStatus? {
        didSet {
            if deviceShadowStatus != oldValue {
                delegate?.onBleDeviceStatusChanged(device: self as! CHDevice, status: deviceStatus,shadowStatus: deviceShadowStatus)
            }
        }
    }
    let appKeyPair = ECC.generate()
    public var rssi: NSNumber?
    public var txPowerLevel:Int?
    public var isRegistered: Bool = true
    public var deviceId: UUID!
    var characteristic: CBCharacteristic?
    var peripheral: CBPeripheral! {
        didSet{
            peripheral!.delegate = self
        }
    }
    var mechStatus: CHSesameProtocolMechStatus? {
        didSet {
            self.delegate?.onMechStatus(device: self as! CHDevice)
        }
    }
    public func disconnect(result: @escaping (CHResult<CHEmpty>)) {
        guard let peripheral = peripheral else {
            result(.failure(NSError.peripheralEmpty))
            return
        }
        if peripheral.state == .connected {
            CHBluetoothCenter.shared.centralManager.cancelPeripheralConnection(peripheral)
            L.d("⌚️","斷開藍牙",peripheral.state.rawValue)
            result(.success(CHResultStateBLE(input: CHEmpty())))
        }
    }


    public func connect(result: @escaping (CHResult<CHEmpty>)) {
        if CHBluetoothCenter.shared.centralManager.state == .poweredOff {
            result(.failure(NSError.blePoweredOff))
            return
        }
        if CHBluetoothCenter.shared.centralManager.state == .unauthorized {
            result(.failure(NSError.bleUnauthorized))
            return
        }
        guard let peripheral = peripheral else {
            result(.failure(NSError.peripheralEmpty))
            return
        }

        if let secretKey = sesame2KeyData?.secretKey, String(secretKey.substring(to: 16)) == "0000000000000000" {
            self.isGuestKey = true
            URLSession.isInternetReachable { isAvailable in
                if isAvailable == false {
                    self.deviceStatus = .waitingForAuth()
                } else {
                    self.connect(peripheral, result: result)
                }
            }
        } else {
            self.isGuestKey = false
            connect(peripheral, result: result)
        }
    }

    private func connect(_ peripheral: CBPeripheral, result: @escaping (CHResult<CHEmpty>)) {
        if deviceStatus == .receivedBle() {
            deviceStatus = .bleConnecting()
            CHBluetoothCenter.shared.centralManager.connect(peripheral, options: nil)
            result(.success(CHResultStateBLE(input: CHEmpty())))
        } else if deviceStatus == .noBleSignal() && CHBluetoothCenter.shared.centralManager.retrievePeripherals(withIdentifiers: [peripheral.identifier]).count > 0  {
            CHBluetoothCenter.shared.centralManager.cancelPeripheralConnection(peripheral)
            CHBluetoothCenter.shared.centralManager.connect(peripheral, options: nil)
            result(.success(CHResultStateBLE(input: CHEmpty())))
        } else {
            result(.failure(NSError.deviceStatusNotReceiveBLE))
        }
    }
    public func dropKey(result: @escaping (CHResult<CHEmpty>))  {
        delegate = nil
        CHDeviceCenter.shared.deleteDevice(self.deviceId)
        deviceStatus = .noBleSignal()
        disconnect(){res in}
        sesame2KeyData = nil
//        #if os(iOS)
//        CHIoTManager.shared.unsubscribeCHDeviceShadow(self)
//        #endif
        result(.success(CHResultStateBLE(input: CHEmpty())))
    }


     func setAdv(_ advertisement: BleAdv) {
        peripheral = advertisement.mPeripheral
        isRegistered = advertisement.isRegistered
        rssi = advertisement.rssi
        deviceId = advertisement.deviceID
        productModel = advertisement.productType!
        txPowerLevel = advertisement.txPowerLevel 
        if deviceStatus == .waitingForAuth() {
            URLSession.isInternetReachable { isAvailable in
                if isAvailable == true {
                    self.deviceStatus = .receivedBle()
                }
            }
        }
        if deviceStatus == .noBleSignal() {
            deviceStatus = .receivedBle()
        }
    }
}

