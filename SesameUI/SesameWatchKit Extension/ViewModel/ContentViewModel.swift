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

class ContentViewModel: ObservableObject {
    @Published var displayText = "co.candyhouse.sesame2.watchkitapp.openYourSesame".localized
    @Published var haveContent = false
    @Published var selectedUUID: UUID?
    
    private let sesameData: SesameData
    private var disposables = [AnyCancellable]()
    
    init(sesameData: SesameData) {
        self.sesameData = sesameData
        guard WCSession.isSupported() == true else {
            self.displayText = "co.candyhouse.sesame2.watchkitapp.notSupport".localized
            return
        }
        
        // 用戶設備更新
        self.sesameData.$devices
            .sink { newDevice in
                self.haveContent = newDevice.count == 0 ? false : true
            }
            .store(in: &disposables)
        
        // 當用戶選擇 sesame
        self.sesameData.$selectedDeviceUUID
            .sink { uuid in
//                if self.selectedUUID != uuid {
//                    CHBleManager.shared.disConnectAll { _ in }
//                }
                self.selectedUUID = uuid
            }
            .store(in: &self.disposables)
    }
    
    func listViewModel() -> SesameListViewModel {
        .init(sesameData: sesameData)
    }
    
    func lockViewModel() -> SesameLockViewModel {
        .init(device: sesameData.selectedCHDevice())
    }
}
