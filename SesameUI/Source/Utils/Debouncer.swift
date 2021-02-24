//
//  Debouncer.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/01/30.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import UIKit

public class Debouncer {
    let semaphore = DispatchSemaphore(value: 1)
    var throttle: TimeInterval
    
    init(throttle: TimeInterval = 1.0) {
        self.throttle = throttle
    }
    
    func execute(_ execution: ()->Void) {
        let result = self.semaphore.wait(timeout: .now() + 0.1)
        if result == .success {
            execution()
            DispatchQueue.global().asyncAfter(deadline: .now() + throttle) {
                self.semaphore.signal()
            }
        }
    }
}

public class Throttle {
    var callback: (() -> ())?
    var delay: Double
    weak var timer: Timer?
    
    init(delay: Double = 1.0) {
        self.delay = delay
    }
    
    func call() {
        executeOnMainThread {
            self.timer?.invalidate()
            let nextTimer = Timer.scheduledTimer(timeInterval: self.delay, target: self, selector: #selector(Throttle.fireNow), userInfo: nil, repeats: false)
            self.timer = nextTimer
        }
    }
    
    @objc func fireNow() {
        self.callback?()
    }
    
    func execute(_ execution: @escaping ()->Void) {
        // https://stackoverflow.com/a/49276761/4276890
        executeOnMainThread {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(withTimeInterval: self.delay, repeats: false) { timer in
                execution()
            }
        }
    }
}
