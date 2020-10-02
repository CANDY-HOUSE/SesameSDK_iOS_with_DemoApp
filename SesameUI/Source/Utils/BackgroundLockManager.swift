//
//  LocationManager.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/7.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import CoreLocation
import NotificationCenter
import SesameSDK

// MARK: - BackgroundLockProtocol
protocol BackgroundLockProtocol {
    func active()
    func deactive()
    func didEnterBackground()
    func didBecomeActive()
}

// MARK: - BackgroundLockManager
class BackgroundLockManager {
    private static var startBackgroundBleLock = false
    private static var startBackgroundGPSLock = false
    
    private enum BackgroundLock {
        case gpsBackgroundLock
        case bleBackgroundLock
        
        func instance() -> BackgroundLockProtocol {
            switch self {
            case .gpsBackgroundLock:
                return GPSBackgroundLockManager.shared
            case .bleBackgroundLock:
                return BleBackgroundLockManager.shared
            }
        }
    }
    
    private static let backgroundBleLock: BackgroundLockProtocol = BackgroundLock.bleBackgroundLock.instance()
    private static let backgroundGPSLock: BackgroundLockProtocol = BackgroundLock.gpsBackgroundLock.instance()
    
    // MARK: activeIfNeeded
    static func activeIfNeeded() {
        
        var autoUnlockDevices = 0
        startBackgroundBleLock = false
        startBackgroundGPSLock = false
        
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesame2s):
                for sesame in sesame2s.data {
                    if let autoUnlockType = Sesame2Store.shared.getSesame2Property(sesame)?.autoUnlockType {
                        if autoUnlockType == 1 {
                            startBackgroundGPSLock = true
                            autoUnlockDevices += 1
                        } else if autoUnlockType == 2 {
                            startBackgroundBleLock = true
                            autoUnlockDevices += 1
                        }
                    }
                }
            case .failure(_):
                break
            }
        }
        
        if startBackgroundBleLock {
            backgroundBleLock.active()
        }
        if startBackgroundGPSLock {
            backgroundGPSLock.active()
        }
        if autoUnlockDevices == 0 {
            deactive()
        }
    }
    
    // MARK: deactive
    static func deactive() {
        startBackgroundBleLock = false
        startBackgroundGPSLock = false
        backgroundBleLock.deactive()
        backgroundGPSLock.deactive()
    }
    
    // MARK: didEnterBackground
    static func didEnterBackground() {
        if startBackgroundBleLock {
            backgroundBleLock.didEnterBackground()
        }
        if startBackgroundGPSLock {
            backgroundGPSLock.didEnterBackground()
        }
    }
    
    // MARK: didBecomeActive
    static func didBecomeActive() {
        if startBackgroundBleLock {
            backgroundBleLock.didBecomeActive()
        }
        if startBackgroundGPSLock {
            backgroundGPSLock.didBecomeActive()
        }
    }
}

extension BackgroundLockProtocol {
    func currentSesame2Delegates(_ completion: @escaping ([UUID: CHSesame2Delegate?]?)->Void) {
        CHDeviceManager.shared.getSesame2s() { result in
            switch result {
            case .success(let sesame2s):
                let delegates = sesame2s.data.reduce([UUID: CHSesame2Delegate?]()) { (result, current) -> [UUID : CHSesame2Delegate?] in
                    var result = result
                    result[current.deviceId] = current.delegate
                    return result
                }
                completion(delegates)
            case .failure(_):
                completion(nil)
            }
        }
    }
}

// MARK: - GPSBackgroundLockManager
fileprivate class GPSBackgroundLockManager: NSObject, BackgroundLockProtocol {

    static var shared = GPSBackgroundLockManager() as BackgroundLockProtocol
    private var locationManager: CLLocationManager? = CLLocationManager()
    var originalSesame2Delegates: [UUID: CHSesame2Delegate?]?
    private var isRaiseFromBackground: Bool = false
    
    private func currentSesame2Delegate(_ completion: @escaping (CHSesame2Delegate?)->Void) {
        CHDeviceManager.shared.getSesame2s() { result in
            switch result {
            case .success(let sesame2s):
                completion(sesame2s.data.first?.delegate)
            case .failure(_):
                completion(nil)
            }
        }
    }
    
    func active() {
        locationManager?.delegate = self
        if CLLocationManager.authorizationStatus() == .notDetermined ||
            CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager?.requestAlwaysAuthorization()
        }
    }
    
    func deactive() {
        locationManager?.delegate = nil
    }
    
    // MARK: didEnterBackground
    func didEnterBackground() {
        isRaiseFromBackground = true
        currentSesame2Delegates() { delegates in
            self.originalSesame2Delegates = delegates
        }
        startUpdateIfNeeded()
        locationManager?.startUpdatingLocation()
        locationManager?.startMonitoringSignificantLocationChanges()
    }
    
    // MARK: didBecomeActive
    func didBecomeActive() {
        if isRaiseFromBackground == true {
            CHDeviceManager.shared.getSesame2s { result in
                switch result {
                case .success(let sesame2s):
                    for sesame2 in sesame2s.data {
                        let originalSesame2Delegate = self.originalSesame2Delegates?[sesame2.deviceId]
                        sesame2.delegate = originalSesame2Delegate as? CHSesame2Delegate
                    }
                case .failure(_):
                    break
                }
            }
        }
        CHBleManager.shared.disableScan { _ in }
        CHBleManager.shared.disConnectAll { _ in }
        locationManager?.stopUpdatingLocation()
        locationManager?.stopMonitoringSignificantLocationChanges()
        if let monitoredRegions = locationManager?.monitoredRegions {
            for monitoredRegion in monitoredRegions {
                locationManager?.stopMonitoring(for: monitoredRegion)
            }
        }
        isRaiseFromBackground = false
    }

    fileprivate func startUpdateIfNeeded() {
        
        guard let locationManager = locationManager else {
            return
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.allowsBackgroundLocationUpdates = true
//            locationManager.showsBackgroundLocationIndicator = true
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.pausesLocationUpdatesAutomatically = true
            locationManager.activityType = .automotiveNavigation
            locationManager.startUpdatingLocation()
        } else {
//            remind user
        }
        
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.startMonitoringSignificantLocationChanges()

            CHDeviceManager.shared.getSesame2s { result in
                switch result {
                case .success(let sesmae2s):
                    for sesame2 in sesmae2s.data {
                        guard let sesame2Property = Sesame2Store.shared.getSesame2Property(sesame2) else {
                            return
                        }
                        if sesame2Property.autoUnlockType == AutoUnlockType.gps.rawValue {
                            let center = CLLocationCoordinate2D(latitude: sesame2Property.latitude,
                                                                longitude: sesame2Property.longitude)
                            var deviceName = sesame2.deviceId.uuidString
                            if let customDeviceName = Sesame2Store.shared.getSesame2Property(sesame2)?.name {
                                deviceName = customDeviceName
                            }
                            
                            let region = CLCircularRegion(center: center,
                                                          radius: CLLocationDistance(100),
                                                          identifier: deviceName)
                            if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
                                                region.notifyOnEntry = true
                                                region.notifyOnExit = true
                                                self.locationManager?.startMonitoring(for: region)
                            } else {
//                                remind user
                            }
                        }
                        
                    }
                    
                case .failure(_):
                    break
                }
            }
        } else {
//            remind user
        }
    }
}

// MARK: CLLocationManagerDelegate
extension GPSBackgroundLockManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    //        L.d("⏲ Did enter \(region.identifier)")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let dts = dateFormatter.string(from: Date())
        notification(body: "Back to " + region.identifier + " @" + dts)
        CHBleManager.shared.enableScan { _ in
            self.readyToAutoUnlock()
        }
    }
    
    func readyToAutoUnlock() {
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesame2s):
                for sesame2 in sesame2s.data {
                    if Sesame2Store.shared.getSesame2Property(sesame2)?.autoUnlockType == 1 {
                        sesame2.delegate = self
                    }
                }
            case .failure(_):
                break
            }
        }
    }
        
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let dts = dateFormatter.string(from: Date())
        notification(body: "Leaving " + region.identifier + " @" + dts)
    }
    
    func notification(body: String) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = ""
        content.body = body
        content.categoryIdentifier = "alarm"
        content.userInfo = ["customData": "fizzbuzz"]
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: trigger)
        center.add(request)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            startUpdateIfNeeded()
        } else {
            // remind user
        }
    }
}

// MARK: CHSesame2Delegate
extension GPSBackgroundLockManager: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status,shadowStatus: CHSesame2ShadowStatus?) {
        
        guard Sesame2Store.shared.getSesame2Property(device)?.autoUnlockType == 1 else {
            return
        }
        
        if status == .receivedBle {
            device.connect(){_ in}
        }
        
        if status.loginStatus() == .logined,
            device.intention == .idle,
            device.mechStatus?.isInLockRange == true {
            device.unlock { _ in
                
            }
        }
    }
    
    public func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        
    }
}

// MARK: - BleBackgroundLockManager
fileprivate class BleBackgroundLockManager: BackgroundLockProtocol {
    
    static let shared = BleBackgroundLockManager()
    private var canOpenLockFlag: Bool = false
    private var isRaiseFromBackground: Bool = false
    
    private var locationManager: CLLocationManager? = CLLocationManager()
    var originalSesame2Delegates: [UUID: CHSesame2Delegate?]?
    
    func active() {
        canOpenLockFlag = true
    }
    
    func deactive() {
        canOpenLockFlag = false
    }
    
    // MARK: didBecomeActive
    func didBecomeActive() {
        if isRaiseFromBackground == true {
            CHDeviceManager.shared.getSesame2s { result in
                switch result {
                case .success(let sesame2s):
                    for sesame2 in sesame2s.data {
                        let originalSesame2Delegate = self.originalSesame2Delegates?[sesame2.deviceId]
                        sesame2.delegate = originalSesame2Delegate as? CHSesame2Delegate
                    }
                case .failure(_):
                    break
                }
            }
        }
        CHBleManager.shared.disableScan { _ in }
        CHBleManager.shared.disConnectAll { _ in }
        isRaiseFromBackground = false
    }
    
    // MARK: didEnterBackground
    func didEnterBackground() {
        isRaiseFromBackground = true
        guard canOpenLockFlag == true else {
            return
        }
        
        currentSesame2Delegates() { delegates in
            self.originalSesame2Delegates = delegates
        }
        
        CHBleManager.shared.enableScan { _ in
            self.readyToAutoUnlock()
        }
    }
    
    // MARK: readyToAutoUnlock
    func readyToAutoUnlock() {
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesame2s):
                for sesame2 in sesame2s.data {
                    sesame2.delegate = self
                }
            case .failure(_):
                break
            }
        }
    }
}

// MARK: CHSesame2Delegate
extension BleBackgroundLockManager: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status,shadowStatus: CHSesame2ShadowStatus?) {
        
        guard Sesame2Store.shared.getSesame2Property(device)?.autoUnlockType == 2 else {
            return
        }
        
        if status == .receivedBle {
            device.connect(){_ in}
        }
        
        L.d("status.loginStatus()", status.loginStatus() == .logined ? "logined" : "not logined")
        L.d("device.intention", device.intention == .idle ? "idle" : "not idle")
        L.d("device.mechStatus?.isInLockRange", device.mechStatus?.isInLockRange == true ? "true" : "false idle")
        
        if status.loginStatus() == .logined,
            device.intention == .idle,
            device.mechStatus?.isInLockRange == true {
            device.unlock { _ in
                if Sesame2Store.shared.getSesame2Property(device)?.autoUnlockType == 2 {
                    Sesame2Store.shared.saveAutoUnlockForSesame2(device, type: .off)
                }
            }
        }
    }
    
    public func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        
    }
}
