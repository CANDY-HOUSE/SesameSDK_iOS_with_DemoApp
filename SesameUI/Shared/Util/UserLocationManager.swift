//
//  UserLocation.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/05/11.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import Foundation
import CoreLocation
#if os(iOS)
import SesameSDK
#else
import SesameWatchKitSDK
#endif

class UserLocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = UserLocationManager()
    var locationManagers = [String: [String: Any]]()
    
    override init() {
        super.init()
    }
    
    func postCHDeviceLocation(_ device: CHDevice) {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestLocation()
        locationManagers[device.deviceId.uuidString] = ["chDevice": device, "locationManager": locationManager]
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let deviceDic = locationManagers.filter({
            $0.value["locationManager"] as? CLLocationManager == manager
        }).first?.value else {
            return
        }
        let device = deviceDic["chDevice"] as! CHDevice
        let deviceInfo = CHDeviceInfo(deviceUUID: device.deviceId.uuidString,
                                      deviceModel: String(device.productModel.rawValue),
                                      longitude: String(locations.last!.coordinate.longitude),
                                      latitude: String(locations.last!.coordinate.latitude))
        locationManagers.removeValue(forKey: device.deviceId.uuidString)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        L.d("Get location failed", error)
    }
}
