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
    var deviceModels: [DeviceModel] { get set }
}

class ContentViewModel: NSObject, ObservableObject, ContentViewModelProtocol {
    @Published var displayText = "co.candyhouse.sesame-sdk-test-app.watchkitapp.openYourSesame".localized
    
    /// Data model wrapper, used to index and generate list view.
    @Published var deviceModels = [DeviceModel]() {
        didSet {
            isShowContent = deviceModels.count > 0 ? true : false
        }
    }
    @Published var isShowContent = false
    @Published var displayColor = UIColor.white
    
    let userData = UserData.shared
    
    private var disposables = [AnyCancellable]()
    
    override init() {
        super.init()
        guard WCSession.isSupported() == true else {
            self.displayText = "co.candyhouse.sesame-sdk-test-app.watchkitapp.notSupport".localized
            return
        }
        
        updateWheneverMessageComming()
        connectDevicesWhenAppBecomeActivate()
        disconnectAllDevicesWhenAppInactivate()
    }
    
    // MARK: - Get Devices
    private func updateWheneverMessageComming() {
        NotificationCenter.default.publisher(for: .WCSessioinDidReceiveMessage)
            .map { notification -> [AnyHashable: Any]? in
                notification.userInfo
            }
            .sink { userInfo in
                CHDeviceManager.shared.getSesame2s { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let sesame2s):
                            executeOnMainThread {
                                self.receivedSesame2s(sesame2s.data)
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
                
                CHDeviceManager.shared.getSesame2s { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let sesame2s):
                            executeOnMainThread {
                                self.receivedSesame2s(sesame2s.data)
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
    
    private func receivedSesame2s(_ sesame2s: [CHSesame2]) {
        let deviceModels = sesame2s.map { sesame2 in
            DeviceModel(uuid: sesame2.deviceId, device: sesame2)
        }
        
        self.deviceModels = deviceModels.sorted(by: { (left, right) -> Bool in
            left.uuid.uuidString < right.uuid.uuidString
        })
        
        // MARK: - Clear removed device
        let containedSelectedUUID = deviceModels.contains {
            userData.selectedDevice == $0.device.deviceId
        }
        if containedSelectedUUID == false {
            userData.selectedDevice = nil
        }
        displayText = "co.candyhouse.sesame-sdk-test-app.watchkitapp.sesameReady".localized
        displayColor = UIColor.white
    }
    
    private func receivedError(_ error: Error) {
        displayText = error.localizedDescription
        displayColor = UIColor.white
        isShowContent = false
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

    // MARK: - User Event
    func deviceHasSelected() {
        // Refresh UI
        CHBleManager.shared.disConnectAll { _ in
            
        }
        isShowContent.toggle()
        isShowContent.toggle()
    }
    
    // MARK: - View Models
    func selectedSesameLockCellModel() -> Sesame2LockViewModel {
        let selectedDeviceId = userData.selectedDevice
        let selectedIndex = deviceModels.firstIndex(where: {
            $0.device.deviceId == selectedDeviceId
        }) ?? 0
        
        return Sesame2LockViewModel(device: deviceModels[selectedIndex].device)
    }
    
    func sesameLockCellModels() -> [Sesame2LockViewModel] {
        deviceModels.map { deviceModel -> Sesame2LockViewModel in
            Sesame2LockViewModel(device: deviceModel.device)
        }
    }
    
    func sesame2ListViewModel() -> Sesame2ListViewModel {
        let sesame2s = deviceModels.map {
            $0.device
        }
        return Sesame2ListViewModel(sesame2s: sesame2s)
    }
}
