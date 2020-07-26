//
//  DeviceModelSubject.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/6/7.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import Combine
import SesameWatchKitSDK

/// The subject accept `CHSesameBleInterface` as request and produce `DeviceModel` as result.
/**
 An example of using a ```DeviceModelSubject```
 
 **Subscribe**
 ```
 deviceProvider
     .devicesPublisher
     .map { $0.result }
     .switchToLatest()
     .sink(receiveCompletion: { complete in
         switch complete {
         case .finished:
             print("Finished")
         case .failure(let error):
             print("Error: \(error)")
         }
     }) { [weak self] deviceModels in
         guard let strongSelf = self else { return }
         for deviceModel in deviceModels {
             deviceModel.device.connect()
         }
         strongSelf.deviceModels = deviceModels
         strongSelf.displayText = LocalizedString("co.candyhouse.sesame-sdk-test-app.watchkitapp.sesameReady")
         SessionDataManager.shared.sendMessageToiPhone(["removeCopy": true])
 }
 .store(in: &disposables)
 deviceProvider.connect()
 ```
 **Publishe**
 ```
 let deviceModelSubject = DeviceModelSubject(request: .init(devices))
 self.devicesPublisher.send(deviceModelSubject)
 deviceModelSubject.connect()
 ```
*/

final class DeviceModelSubject: ProviderSubject {
    let request: CurrentValueSubject<[CHSesame2], Error>
    var result: PassthroughSubject = PassthroughSubject<[DeviceModel], Error>()
    
    private var disposables = Set<AnyCancellable>()
    
    /// Create a
    /// - Parameter request: `[CHSesame2]` subject
    init(request: CurrentValueSubject<[CHSesame2], Error>) {
        self.request = request
        self.setup()
    }
    
    /// Start emit values.
    func connect() {
        let devices = request.value
        request.send(devices)
    }
    
    private func setup() {
        request
            .sink(receiveCompletion: { [weak self] subject in
                guard let strongSelf = self else { return }
                switch subject {
                case .finished:
                    break
                case .failure(let error):
                    strongSelf.result.send(completion: .failure(error))
                }
            }) { [weak self] devices in
                guard let strongSelf = self else { return }
                strongSelf.result.send(
                    devices.compactMap { device -> DeviceModel? in
                        guard let uuid = device.deviceId else { return nil }
                        return DeviceModel(uuid: uuid, device: device)
                    }
                )
        }
        .store(in: &disposables)
    }
}
