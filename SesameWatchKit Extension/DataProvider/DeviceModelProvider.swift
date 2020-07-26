//
//  DeviceModelProvider.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/6/6.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import Combine
import SesameWatchKitSDK

/// Provide `DeviceModel` instances.
final class DeviceModelProvider: Provider {
    
    private var disposables = [AnyCancellable]()
    var subjectPublisher = PassthroughSubject<DeviceModelSubject, Error>()

    func connect() {
        updateWheneverMessageComming()
        connectDevicesWhenAppBecomeActivate()
        disconnectAllDevicesWhenAppInactivate()
    }
    
    private func updateWheneverMessageComming() {
        NotificationCenter.default.publisher(for: .WCSessioinDidReceiveMessage)
            .map { notification -> [AnyHashable: Any]? in
                notification.userInfo
        }
        .sink { userInfo in
            CHDeviceManager.shared.getSesame2s { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let devices):
                        let deviceModelSubject = DeviceModelSubject(request: .init(devices.data))
                        self.subjectPublisher.send(deviceModelSubject)
                        deviceModelSubject.connect()
                    case .failure(let error):
                        self.subjectPublisher.send(completion: .failure(error))
                    }
                }
            }
        }
        .store(in: &disposables)
    }
    
    private func connectDevicesWhenAppBecomeActivate() {
        NotificationCenter.default.publisher(for: .ApplicationDidBecomeActive)
            .sink { _ in
                L.d("ApplicationDidBecomeActive")
                CHBleManager.shared.enableScan(){ res in

                }

                CHDeviceManager.shared.getSesame2s { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let devices):
                            let deviceModelSubject = DeviceModelSubject(request: .init(devices.data))
                            self.subjectPublisher.send(deviceModelSubject)
                            deviceModelSubject.connect()
                        case .failure(let error):
                            self.subjectPublisher.send(completion: .failure(error))
                        }
                    }
                }
        }
        .store(in: &self.disposables)
    }
    
    private func disconnectAllDevicesWhenAppInactivate() {
        NotificationCenter.default.publisher(for: Notification.Name.ApplicationWillResignActive)
            .sink { _ in
                CHBleManager.shared.disableScan(){res in}
                CHBleManager.shared.disConnectAll(){res in}
                L.d("ApplicationWillResignActive")
        }
        .store(in: &self.disposables)
    }
}
