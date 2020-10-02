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
    private var sesame2s: [CHSesame2]
    
    init(sesame2s: [CHSesame2]) {
        self.sesame2s = sesame2s.sorted(by: {
            $0.compare($1)
        })
    }
    
    func cellViewModels() -> [Sesame2ListCellModel] {
        sesame2s.map {
            Sesame2ListCellModel(device: $0)
        }
    }
}
