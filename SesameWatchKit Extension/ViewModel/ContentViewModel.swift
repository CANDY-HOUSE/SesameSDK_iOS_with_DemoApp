//
//  ContentViewModel.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/6/2.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import WatchConnectivity
import SesameWatchKitSDK
import Combine
import WatchKit

protocol ContentViewModelProtocol: class {
    var displayText: String { get set }
    var deviceModels: [SesameDeviceModel] { get set }
}

class ContentViewModel: NSObject, ObservableObject, ContentViewModelProtocol {
    @Published var displayText = "co.candyhouse.sesame2.watchkitapp.openYourSesame".localized
    @Published var isShowContent = false
    @Published var displayColor = UIColor.white
    @Published var deviceModels = [SesameDeviceModel]() {
        didSet {
            isShowContent = deviceModels.count > 0 ? true : false
        }
    }
    
    let userData = UserData.shared
    
    private var disposables = [AnyCancellable]()
    private var selectedUUID = ""
    
    override init() {
        super.init()
        guard WCSession.isSupported() == true else {
            self.displayText = "co.candyhouse.sesame2.watchkitapp.notSupport".localized
            return
        }
        
        updateWheneverMessageComming()
        connectDevicesWhenAppBecomeActivate()
        disconnectAllDevicesWhenAppDidEnterBackground()
    }
    
    // MARK: - Get Devices
    private func updateWheneverMessageComming() {
        NotificationCenter.default.publisher(for: .WCSessioinDidReceiveMessage)
            .map { notification -> [AnyHashable: Any]? in
                notification.userInfo
            }
            .sink { userInfo in
                CHDeviceManager.shared.getCHDevices { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let devies):
                            executeOnMainThread {
                                self.receiveCHDevices(devies.data)
                            }
                        case .failure(let error):
                            executeOnMainThread {
                                self.receivedError(error)
                            }
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
                CHDeviceManager.shared.getCHDevices { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let devies):
                            executeOnMainThread {
                                self.receiveCHDevices(devies.data)
                            }
                        case .failure(let error):
                            executeOnMainThread {
                                self.receivedError(error)
                            }
                        }
                    }
                }
            }
            .store(in: &self.disposables)
    }
    
    private func receiveCHDevices(_ devices: [CHDevice]) {
        deviceModels = devices.map { device in
            SesameDeviceModel(uuid: device.deviceId, device: device)
        }
        
        // MARK: - Clear removed device
        let containedSelectedUUID = deviceModels.contains {
            userData.selectedDevice == $0.device.deviceId
        }
        if containedSelectedUUID == false {
            userData.selectedDevice = nil
        }
        displayText = "co.candyhouse.sesame2.watchkitapp.openYourSesame".localized
        displayColor = UIColor.white
    }
    
    private func receivedError(_ error: Error) {
        displayText = error.localizedDescription
        displayColor = UIColor.white
        isShowContent = false
    }
    
    private func disconnectAllDevicesWhenAppDidEnterBackground() {
        NotificationCenter.default.publisher(for: Notification.Name.ApplicationDidEnterBackground)
            .sink { _ in
                CHBleManager.shared.disableScan(){res in}
                CHBleManager.shared.disConnectAll(){res in}
                L.d("ApplicationDidEnterBackground")
        }
        .store(in: &self.disposables)
    }

    // MARK: - User Event
    func deviceHasSelected(_ uuid: String?) {
        // Refresh UI
        if let selected = uuid, selectedUUID != selected {
            selectedUUID = selected
            CHBleManager.shared.disConnectAll { _ in
                
            }
            isShowContent.toggle()
            isShowContent.toggle()
        }
    }
    
    // MARK: - View Models
    func selectedSesameLockCellModel() -> Sesame2LockViewModel {
        let selectedDeviceId = userData.selectedDevice
        var selectedIndex: Int?
        
        selectedIndex = deviceModels.firstIndex(where: {
            $0.device.deviceId == selectedDeviceId
        })
        
        if let selected = selectedIndex {
            return Sesame2LockViewModel(device: deviceModels[selected].device)
        } else {
            return Sesame2LockViewModel(device: deviceModels[0].device)
        }
    }
    
    func sesameLockCellModels() -> [Sesame2LockViewModel] {
        deviceModels.map { deviceModel -> Sesame2LockViewModel in
            Sesame2LockViewModel(device: deviceModel.device)
        }
    }
    
    func sesame2ListViewModel() -> Sesame2ListViewModel {
        let devices = deviceModels.map {
            $0.device
        }
        return Sesame2ListViewModel(devices: devices)
    }
}
