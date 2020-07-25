//
//  CHBLEDelegatesManager.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/24.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

public final class CHBLEDelegatesManager: CHBleManagerDelegate {
    static let shared = CHBLEDelegatesManager()

    private var bleObservers = NSHashTable<AnyObject>(options: .weakMemory)
    
    private init() {
        CHBleManager.shared.delegate = self
    }
    
    public func addObserver(_ observer: CHBleManagerDelegate) {
        bleObservers.add(observer)
    }
    
    public func removeObserver(_ observer: CHBleManagerDelegate) {
        bleObservers.remove(observer)
    }
    
    public func didDiscoverUnRegisteredSesame2s(sesame2s : [CHSesame2]) {
        bleObservers.objectEnumerator().forEach({ observer in
            if let observer = observer as? CHBleManagerDelegate {
                observer.didDiscoverUnRegisteredSesame2s(sesame2s: sesame2s)
            }
        })
    }
    
    public func didDiscoverUnRegisteredSesame2(sesame2: CHSesame2) {
        bleObservers.objectEnumerator().forEach({ observer in
            if let observer = observer as? CHBleManagerDelegate {
                observer.didDiscoverUnRegisteredSesame2(sesame2: sesame2)
            }
        })
    }
}
