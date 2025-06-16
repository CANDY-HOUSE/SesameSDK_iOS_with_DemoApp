//
//  UserData.swift
//  SesameWatchKit Extension
//
//  Created by Wayne Hsiao on 2020/8/4.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import Combine
import SesameWatchKitSDK

final class SesameData: ObservableObject {
    static let shared = SesameData()
    @Published var selectedDeviceUUID: UUID? {
        didSet {
            if let uuid = selectedDeviceUUID?.uuidString {
                UserDefaults.standard.setValue(uuid, forKey: "watchSelectedUUID")
            }
        }
    }
    @Published var devices: [CHDevice] = []
    
    func selectedCHDevice() -> CHDevice? {
        let deviceId = selectedDeviceUUID
        let selectedDevice = devices
            .filter { $0.deviceId == deviceId }
            .first
        return selectedDevice ?? devices.first
    }
    
    init() {
        if let lastTimeSelected = UserDefaults.standard.string(forKey: "watchSelectedUUID") {
            selectedDeviceUUID = UUID(uuidString: lastTimeSelected)!
        }
    }
}
