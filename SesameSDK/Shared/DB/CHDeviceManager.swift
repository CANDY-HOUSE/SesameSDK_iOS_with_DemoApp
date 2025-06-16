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
        DispatchQueue.global(qos: .background).async{
            CHIoTManager.shared.reconnect()
        }
    }
#elseif os(watchOS)
    override init() {
        super.init()
        DispatchQueue.main.async {
            self.getCHDevices { result in
                if case let .success(devices) = result {
                    for device in devices.data {
                        (device as? CHDeviceUtil)?.goIOT ()
                    }
                }
            }
        }
    }
#endif
    // 从范例SDK同步
    public func getCHDevices(result: @escaping (CHResult<[CHDevice]>)) {
        let devices = CHDeviceCenter.shared.lastCachedevices().compactMap { deviceData -> CHDevice? in
            guard let deviceModelString = deviceData.deviceModel,
                  let productModel = CHProductModel.deviceModeulFromString(deviceModelString),
                  let deviceId = deviceData.deviceUUID else {
                L.d("[CHDeviceManager][getCHDevices] Missing data for device: \(deviceData)")
                return nil
            }
            guard var sesame2Device = CHBluetoothCenter.shared.deviceMap.getOrPut(deviceId, backup: productModel.chDeviceFactory()) as? CHDeviceUtil else {
                L.d("[CHDeviceManager][getCHDevices] Failed to get or put device in device map for ID: \(deviceId)")
                return nil
            }
            
            sesame2Device.sesame2KeyData = deviceData.toCHDeviceKey()
            sesame2Device.productModel = productModel
            return sesame2Device as? CHDevice
        }
        result(.success(CHResultStateBLE(input: devices)))
    }
    
    public func receiveCHDeviceKeys(_ deviceKeys: [CHDeviceKey],result: @escaping (CHResult<[CHDevice]>)){
//        L.d("🔑","收鑰匙多多")
        parse(deviceKeys: deviceKeys, result)
    }
    public func receiveCHDeviceKeys(_ deviceKeys: CHDeviceKey...,result: @escaping (CHResult<[CHDevice]>)){
//        L.d("🔑","收鑰匙咄咄")
        parse(deviceKeys: deviceKeys, result)
    }

    private func parse(deviceKeys: [CHDeviceKey], _ result: @escaping (CHResult<[CHDevice]>)){
        let newDeviceIds: [UUID] = deviceKeys.compactMap({ $0.deviceUUID })
        var returnNewDevices = [CHDevice]()
        // batch update
        CHDeviceCenter.shared.appendDevices(deviceKeys)
        // fetch
        CHDeviceCenter.shared.lastCachedevices().forEach({ deviceData in
            // L.d("本地查找到設備")
            if let deviceID = deviceData.deviceUUID,
               var deviceTithBle = CHBluetoothCenter.shared.deviceMap.filterValues({ $0.deviceId?.uuidString == deviceID }).first as? CHDeviceUtil {
                if newDeviceIds.contains(UUID(uuidString: deviceID)!) {
                    deviceTithBle.sesame2KeyData = deviceData.toCHDeviceKey()
                    returnNewDevices.append(deviceTithBle as! CHDevice)
                    deviceTithBle.goIOT()
                }
            } else {
                // L.d("沒有就創造無訊號設備")
                if let productModel = CHProductModel.deviceModeulFromString(deviceData.deviceModel!) {
                    let device = productModel.chDeviceFactory()
                    if var deviceUtil = device as? CHDeviceUtil {
                        deviceUtil.sesame2KeyData = deviceData.toCHDeviceKey()
                        if newDeviceIds.contains(device.deviceId) {
                            returnNewDevices.append(device)
                            deviceUtil.goIOT()
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
        CHAccountManager.shared.API(request: .init(.delete, "/device/v1/token", ["token": token, "deviceId": deviceId, "name": name])) { deleteResult in
            switch deleteResult {
            case .success(_):
                result(.success(.init(input: .init())))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
}
