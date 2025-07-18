//
//  MulticastDelegate.swift
//  SesameSDK
//
//  Created by eddy on 2024/5/24.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation

open class CHMulticastDelegate<T> {
    
    private let delegates: NSHashTable<AnyObject>
    private let defaultDelegateQueue = DispatchQueue(label: "co.candyhouse.multicastDelegateQueue", attributes: .concurrent)
    
    public init(strongReference: Bool = false) {
        delegates = strongReference ? NSHashTable<AnyObject>() : NSHashTable<AnyObject>.weakObjects()
    }
    
    public func addDelegate(_ delegate: T, _ queue: DispatchQueue? = nil) {
        let targetQueue = queue ?? defaultDelegateQueue
        targetQueue.async(flags: .barrier) {
            self.delegates.add(delegate as AnyObject)
        }
    }
    
    public func removeDelegate(_ delegate: T, _ queue: DispatchQueue? = nil) {
        let targetQueue = queue ?? defaultDelegateQueue
        targetQueue.async(flags: .barrier) {
            self.delegates.remove(delegate as AnyObject)
        }
    }
    
    public func removeAll(_ queue: DispatchQueue? = nil) {
        let targetQueue = queue ?? defaultDelegateQueue
        targetQueue.async(flags: .barrier) {
            self.delegates.removeAllObjects()
        }
    }
    
    public func invokeDelegates(_ invocation: @escaping (T) -> (), _ queue: DispatchQueue? = nil) {
        let targetQueue = queue ?? defaultDelegateQueue
        targetQueue.async {
            for delegate in self.delegates.allObjects {
                invocation(delegate as! T)
            }
        }
    }
    
    public func containsDelegate(_ delegate: T, _ queue: DispatchQueue? = nil) -> Bool {
           let targetQueue = queue ?? defaultDelegateQueue
           var contains = false
           targetQueue.sync {
               contains = self.delegates.contains(delegate as AnyObject)
           }
           return contains
       }
}
