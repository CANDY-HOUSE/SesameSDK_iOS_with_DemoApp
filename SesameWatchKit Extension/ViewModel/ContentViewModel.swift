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
    
    private func receivedDeviceModels() {
        deviceProvider
            .subjectPublisher
            .map { $0.result }
            .switchToLatest()
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
                strongSelf.deviceModels = deviceModels
                strongSelf.displayText = LocalizedString("co.candyhouse.sesame-sdk-test-app.watchkitapp.sesameReady")
                strongSelf.displayColor = UIColor.white
        }
        .store(in: &disposables)
        deviceProvider.connect()
    }
    
    func sesameLockCellModels() -> [Sesame2LockViewModel] {
        deviceModels.map { deviceModel -> Sesame2LockViewModel in
            Sesame2LockViewModel(device: deviceModel.device)
        }
    }
}
