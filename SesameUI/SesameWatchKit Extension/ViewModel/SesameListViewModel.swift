//
//  SesameListViewModel.swift
//  SesameWatchKit Extension
//
//  Created by Wayne Hsiao on 2020/8/4.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import WatchKit
import SesameWatchKitSDK
import SwiftUI
import Combine

class SesameListViewModel: ObservableObject {
    private var sesameData: SesameData
    
    init(sesameData: SesameData) {
        self.sesameData = sesameData
    }
    
    func cellViewModels() -> [SesameListCellModel] {
        return sesameData.devices.sorted { left, right -> Bool in
            left.compare(right)
        }.map {
            SesameListCellModel(device: $0, sesameData: sesameData)
        }
    }
}

class SesameListCellModel: ObservableObject, Identifiable {
    private(set) var uuid: UUID!
    private var device: CHDevice
    private var disposables = [AnyCancellable]()
    private var sesameData: SesameData!

    @Published var title = ""
    @Published var image = "Icon"
    @Published var circleColor = Color.white
    @Published var circleLineWidth: CGFloat = 0.0

    init(device: CHDevice, sesameData: SesameData) {
        self.device = device
        self.uuid = device.deviceId
        self.title = device.deviceName
        self.sesameData = sesameData
        let selectedId = sesameData.selectedDeviceUUID
        self.circleColor = self.uuid == selectedId ? Color(UIColor.sesame2LightGray) : Color.white
        self.circleLineWidth = self.uuid == selectedId ? 2 : 0
    }

    func isSelected(uuid: UUID) -> Bool {
        return uuid == device.deviceId
    }

    func selectDevice() {
        sesameData.selectedDeviceUUID = uuid
    }
}
