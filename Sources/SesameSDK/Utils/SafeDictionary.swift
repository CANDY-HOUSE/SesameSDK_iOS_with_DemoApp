//
//  SafeDictionary.swift
//  SesameSDK
//
//  Created by eddy on 2024/1/22.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation

class SafeDictionary<Key: Hashable, Value> {
    private var dictionary: [Key: Value] = [:]
    private var concurrentQueue: DispatchQueue
    
    public init() {
        self.concurrentQueue = DispatchQueue(label: "co.candyhouse.safedictionary", attributes: .concurrent)
    }
    
    public func getOrPut(_ key: Key, backup: Value) -> Value {
        return concurrentQueue.sync(flags: .barrier) {
            if let existingValue = dictionary[key] {
                return existingValue
            } else {
                dictionary[key] = backup
                return backup
            }
        }
    }
    
    public var values: [Value] {
        var result: [Value] = []
        concurrentQueue.sync {
            result = Array(self.dictionary.values)
        }
        return result
    }
    
    public func filter(_ isIncluded: @escaping ((key: Key, value: Value)) -> Bool) -> SafeDictionary<Key, Value> {
        let filteredSafeDictionary = SafeDictionary<Key, Value>()
        concurrentQueue.sync {
            let filtered = self.dictionary.filter { isIncluded(($0.key, $0.value)) }
            filteredSafeDictionary.concurrentQueue.sync(flags: .barrier) {
                filteredSafeDictionary.dictionary = filtered
            }
        }
        return filteredSafeDictionary
    }
    
    public func value(key: Key) -> Value? {
        var valueOfKey: Value?
        concurrentQueue.sync {
            valueOfKey = dictionary[key]
        }
        return valueOfKey
    }
    
    public func filterValues(_ isIncluded: @escaping (Value) -> Bool) -> [Value] {
        var result: [Value] = []
        concurrentQueue.sync {
            result = self.dictionary.values.filter(isIncluded)
        }
        return result
    }
    
    public func updateValue(_ value: Value, forKey: Key) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.dictionary.updateValue(value, forKey: forKey)
        }
    }
    
    public func removeValue(forKey key: Key) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.dictionary.removeValue(forKey: key)
        }
    }
    
    public func removeAll(keepingCapacity: Bool = false) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.dictionary.removeAll(keepingCapacity: keepingCapacity)
        }
    }
    
    public func accessWithBlock(_ block: @escaping ([Key: Value]) -> Void) {
        concurrentQueue.async(flags: .barrier) {
            block(self.dictionary)
        }
    }
    
    public subscript(key: Key) -> Value? {
        get {
            return self.value(key: key)
        }
        set {
            if let newVal = newValue {
                self.updateValue(newVal, forKey: key)
            } else {
                self.removeValue(forKey: key)
            }
        }
    }
    
}
