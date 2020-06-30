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
    
    public func didDiscoverUnRegisteredSesames(sesames : [CHSesameBleInterface]) {
        bleObservers.objectEnumerator().forEach({ observer in
            if let observer = observer as? CHBleManagerDelegate {
                observer.didDiscoverUnRegisteredSesames(sesames: sesames)
            }
        })
    }
    
    public func didDiscoverUnRegisteredSesame(sesame: CHSesameBleInterface) {
        bleObservers.objectEnumerator().forEach({ observer in
            if let observer = observer as? CHBleManagerDelegate {
                observer.didDiscoverUnRegisteredSesame(sesame: sesame)
            }
        })
    }
}
