//
//  Debouncer.swift
//  SesameUI
//
//  Created by eddy on 2024/1/3.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation

class Debouncer {
    var workItem: DispatchWorkItem?
    var interval: TimeInterval
    
    init(interval: TimeInterval) {
        self.interval = interval
    }
    
    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        let newWorkItem = DispatchWorkItem(block: action)
        workItem = newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: newWorkItem)
    }
}
