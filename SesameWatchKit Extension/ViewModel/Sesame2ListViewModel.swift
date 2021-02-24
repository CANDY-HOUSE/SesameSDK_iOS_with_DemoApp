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

class Sesame2ListViewModel: ObservableObject {
    @Published var display = ""
    private var devices: [CHDevice]
    
    init(devices: [CHDevice]) {
        self.devices = devices.sorted { left, right -> Bool in
            left.compare(right)
        }
    }
    
    func cellViewModels() -> [Sesame2ListCellModel] {
        var cellModels = [Sesame2ListCellModel]()
        cellModels += devices.map {
            Sesame2ListCellModel(device: $0)
        }
        return cellModels
    }
}
