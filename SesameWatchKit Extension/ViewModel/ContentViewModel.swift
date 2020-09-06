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

class ContentViewModel<ContentProvider: Provider>: NSObject, ObservableObject, ContentViewModelProtocol {
    @Published var displayText = LocalizedString("co.candyhouse.sesame-sdk-test-app.watchkitapp.openYourSesame")
    
    /// Data model wrapper, used to index and generate list view.
    @Published var deviceModels = [DeviceModel]() {
        didSet {
            isShowContent = deviceModels.count > 0 ? true : false
        }
    }
    @Published var isShowContent = false
    @Published var displayColor = UIColor.white
    
    let userData = UserData.shared
    
    private var deviceProvider: ContentProvider
    private var disposables = [AnyCancellable]()
    
    init(deviceProvider: ContentProvider = DeviceModelProvider() as! ContentProvider) {

        self.deviceProvider = deviceProvider
        super.init()
        self.receivedDeviceModels()
        guard WCSession.isSupported() == true else {
            self.displayText = LocalizedString("co.candyhouse.sesame-sdk-test-app.watchkitapp.notSupport")
            return
        }
    }
    
    // MARK: - Binding
    private func receivedDeviceModels() {
        deviceProvider
            .subjectPublisher
            .map { $0.result }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { complete in
                switch complete {
                case .finished:
                    L.d("Finished")
                case .failure(let error):
                    L.d("Error: \(error)")
                    self.displayText = error.localizedDescription
                    self.displayColor = UIColor.white
                    self.isShowContent = false
                }
            }) { [weak self] deviceModels in
                guard let strongSelf = self,
                    let deviceModels = deviceModels as? [DeviceModel] else {
                    return
                }
                L.d("Watch get \(deviceModels.count) device(s).")
                strongSelf.deviceModels = deviceModels.sorted(by: { (left, right) -> Bool in
                    left.uuid.uuidString < right.uuid.uuidString
                })
                
                // MARK: - Clear removed device
                let containedSelectedUUID = deviceModels.contains {
                    strongSelf.userData.selectedDevice == $0.device.deviceId
                }
                if containedSelectedUUID == false {
                    strongSelf.userData.selectedDevice = nil
                }
                strongSelf.displayText = LocalizedString("co.candyhouse.sesame-sdk-test-app.watchkitapp.sesameReady")
                strongSelf.displayColor = UIColor.white
        }
        .store(in: &disposables)
        deviceProvider.connect()
    }
    
    // MARK: - User Event
    func deviceHasSelected() {
        // Refresh UI
        isShowContent.toggle()
        isShowContent.toggle()
    }
    
    // MARK: - View Models
    func selectedSesameLockCellModel() -> Sesame2LockViewModel {
        let selectedIndex = deviceModels.firstIndex(where: { [weak self] in
            $0.device.deviceId == self?.userData.selectedDevice
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
