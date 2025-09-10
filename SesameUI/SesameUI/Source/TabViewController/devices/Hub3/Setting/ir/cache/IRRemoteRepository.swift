//
//  IRRemoteRepository.swift
//  SesameUI
//
//  Created by wuying on 2025/9/9.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import Combine
import SesameSDK

// MARK: - State Model
struct IrRemoteState {
    var remoteMap: [String: [IRRemote]] = [:]
}

// MARK: - Repository
class IRRemoteRepository {
    static let shared = IRRemoteRepository()
    
    // 使用 CurrentValueSubject（更接近 StateFlow）
    private let _stateSubject = CurrentValueSubject<IrRemoteState, Never>(IrRemoteState())
    
    // 对外提供的状态流
    var statePublisher: AnyPublisher<IrRemoteState, Never> {
        return _stateSubject.eraseToAnyPublisher()
    }
    
    // 获取当前状态的便捷属性
    var currentState: IrRemoteState {
        return _stateSubject.value
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    func addRemote(key: String, remote: IRRemote) {
        var currentMap = currentState.remoteMap
        var list = currentMap[key] ?? []
        list.append(remote)
        currentMap[key] = list
        updateState(remoteMap: currentMap)
    }
    
    func setRemotes(key: String, remotes: [IRRemote]) {
        var currentMap = currentState.remoteMap
        currentMap[key] = remotes
        updateState(remoteMap: currentMap)
    }
    
    func addRemotes(key: String, remotes: [IRRemote]) {
        var currentMap = currentState.remoteMap
        var existingList = currentMap[key] ?? []
        existingList.append(contentsOf: remotes)
        currentMap[key] = existingList
        updateState(remoteMap: currentMap)
    }
    
    func removeRemote(key: String, remoteUUID: String) {
        var currentMap = currentState.remoteMap
        if var list = currentMap[key] {
            list.removeAll { $0.uuid == remoteUUID }
            if list.isEmpty {
                currentMap.removeValue(forKey: key)
            } else {
                currentMap[key] = list
            }
            updateState(remoteMap: currentMap)
        }
    }
    
    func updateRemote(key: String, index: Int, remote: IRRemote) {
        var currentMap = currentState.remoteMap
        if var list = currentMap[key], index < list.count {
            list[index] = remote
            currentMap[key] = list
            updateState(remoteMap: currentMap)
        }
    }
    
    func getRemotesByKey(_ key: String) -> [IRRemote] {
        return currentState.remoteMap[key] ?? []
    }
    
    func getRemoteByIndex(key: String, index: Int) -> IRRemote? {
        guard let list = currentState.remoteMap[key], index < list.count else {
            return nil
        }
        return list[index]
    }
    
    func containsRemote(key: String, remote: IRRemote) -> Bool {
        return currentState.remoteMap[key]?.contains { $0.uuid == remote.uuid } ?? false
    }
    
    func getAllKeys() -> Set<String> {
        return Set(currentState.remoteMap.keys)
    }
    
    func clearRemotes(key: String) {
        var currentMap = currentState.remoteMap
        currentMap.removeValue(forKey: key)
        updateState(remoteMap: currentMap)
    }
    
    func clearAll() {
        updateState(remoteMap: [:])
    }
    
    // MARK: - Private Methods
    
    private func updateState(remoteMap: [String: [IRRemote]]) {
        let newState = IrRemoteState(remoteMap: remoteMap)
        _stateSubject.send(newState)
    }
}
