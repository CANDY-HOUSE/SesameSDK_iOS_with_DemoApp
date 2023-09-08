//
//  CHDeviceManager.swift
//  Sesame2SDK
//
//  Created by tse on 2020/7/15.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

public class CHDeviceManager: NSObject {
    public static let shared = CHDeviceManager()
    
    #if os(iOS)
    override init() {
        super.init()
    }
    #elseif os(watchOS)
    override init() {
        super.init()
        DispatchQueue.main.async {
            self.getCHDevices { result in
                if case let .success(devices) = result {
                    for device in devices.data {
//                        (device as? CHDeviceUtil)?.goIOT ()
                    }
                }
            }
        }
    }
    #endif
    
    public func getCHDevices(result: @escaping (CHResult<[CHDevice]>)) { 
        var devices = [CHDevice]()
        for deviceData in CHDeviceCenter.shared.lastCachedevices() { // 檢索最後緩存的設備
            if let productModel = CHProductModel.deviceModeulFromString(deviceData.deviceModel!) {
                if let deviceId = deviceData.deviceUUID {
                    if var sesame2Device = CHBluetoothCenter.shared.deviceMap.getOrPut(deviceId, backup: productModel.chDeviceFactory()) as? CHDeviceUtil {
                        sesame2Device.sesame2KeyData = deviceData.toCHDeviceKey()
                        sesame2Device.productModel = productModel
                        devices.append(sesame2Device as! CHDevice)
                    }
                }
            }else{
                L.d("[CHDeviceManager][getCHDevices]!!!!")
            }
        }
        result(.success(CHResultStateBLE(input: devices)))
    }
    
    public func receiveCHDeviceKeys(_ deviceKeys: [CHDeviceKey],result: @escaping (CHResult<[CHDevice]>)){
        parse(deviceKeys: deviceKeys, result)
    }
    public func receiveCHDeviceKeys(_ deviceKeys: CHDeviceKey...,result: @escaping (CHResult<[CHDevice]>)){
        parse(deviceKeys: deviceKeys, result)
    }

    private func parse(deviceKeys: [CHDeviceKey], _ result: @escaping (CHResult<[CHDevice]>)){
        var newDeviceIds: [UUID] = []
        var returnNewDevices = [CHDevice]()

        deviceKeys.forEach { (deviceKey) in
            newDeviceIds.append(deviceKey.deviceUUID)
            CHDeviceCenter.shared.appendDevice(deviceKey)
        }

        CHDeviceCenter.shared.lastCachedevices().forEach({ deviceData in
            // L.d("本地查找到設備")
            if let deviceID = deviceData.deviceUUID,
               var deviceTithBle = CHBluetoothCenter.shared.deviceMap.values.filter({ $0.deviceId.uuidString == deviceID }).first as? CHDeviceUtil {
                if newDeviceIds.contains(UUID(uuidString: deviceID)!) {
                    deviceTithBle.sesame2KeyData = deviceData.toCHDeviceKey()
                    returnNewDevices.append(deviceTithBle as! CHDevice)
//                    deviceTithBle.goIOT()
                }
            } else {
                // L.d("沒有就創造無訊號設備")
                if let productModel = CHProductModel.deviceModeulFromString(deviceData.deviceModel!) {
                    let device = productModel.chDeviceFactory()
                    if var deviceUtil = device as? CHDeviceUtil {
                        deviceUtil.sesame2KeyData = deviceData.toCHDeviceKey()
                        if newDeviceIds.contains(device.deviceId) {
                            returnNewDevices.append(device)
//                            deviceUtil.goIOT()
                        }
                        CHBluetoothCenter.shared.deviceMap.updateValue((deviceUtil as! CHDevice), forKey: device.deviceId.uuidString)
                    }
                }
            }
        })
        result(.success(CHResultStateBLE(input: returnNewDevices)))
    }
}

extension CHDeviceManager {
    public func disableNotification(deviceId: String, token: String, name: String, result: @escaping CHResult<CHEmpty>) {
    }
}
