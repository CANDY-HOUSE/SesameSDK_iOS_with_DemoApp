//
//  Hub3IRRemoteMatchViewModel.swift
//  SesameUI
//
//  Created by wuying on 2025/3/11.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


import Foundation
import SesameSDK


class Hub3IRRemoteMatchViewModel  {
    private let tag = "Hub3IRRemoteMatchViewModel"
    private let remoteRepository: RemoteRepository
    private var isLearningMode = false// 是否處於學習模式
   
    private var irRemoteDevice: IRRemote?
    
    
    private(set) var irMatchItemList: [MatchIRRemote] = [] {
        didSet {
            notifyIRMatchItemListObservers()
        }
    }
    private var irMatchItemListObservers: [([MatchIRRemote]) -> Void] = []
    
    private(set) var isSearching: Bool = false {
        didSet {
            notifySearchingStateObservers()
        }
    }
    private var searchingStateObservers: [(Bool) -> Void] = []
    
    // MARK: - Private Properties
    private var hub3DeviceId: String  = ""
        
    
    // MARK: - Initialization
    init(hub3DeviceId: String, irRemote: IRRemote, existingMatchList: [MatchIRRemote]? = nil) {
        self.hub3DeviceId = hub3DeviceId
        self.irRemoteDevice = irRemote
        self.remoteRepository = RemoteRepository()
        
        if let existingList = existingMatchList, !existingList.isEmpty {
            self.irMatchItemList = existingList
        }
    }

    
    func observeIRMatchItemList(_ handler: @escaping ([MatchIRRemote]) -> Void) {
        irMatchItemListObservers.append(handler)
        handler(irMatchItemList)
    }
    
    private func notifyIRMatchItemListObservers() {
        irMatchItemListObservers.forEach { $0(irMatchItemList) }
    }
    
    func observeSearchingState(_ handler: @escaping (Bool) -> Void) {
        searchingStateObservers.append(handler)
        handler(isSearching)
    }
    
    private func notifySearchingStateObservers() {
        searchingStateObservers.forEach { $0(isSearching) }
    }
    
    func getInitIrRemoteDevice() -> IRRemote? {
        return irRemoteDevice
    }
    
    deinit {
        remoteRepository.clearConfigCache()
        remoteRepository.clearHandlerCache()
    }
    
    func gaurdRegisterMode() {
        if(isLearningMode) {
            isLearningMode = false
            setIRMode(mode: 0x00)
        }
    }
    
    func getIRMode() {
        CHIRManager.shared.subscribeTopic(topic: getModeTopic()) { [weak self] onResult in
            guard let self = self else { return }
            
            if case let .failure(err) = onResult {
                L.e("IRLearningViewModel", "getIRMode", err)
                return
            }
            
            if case let .success(result) = onResult {
                if let mode = self.extractValueWithJson(data: result.data) {
                    let isRegisterMode = mode == 1
                    guard isRegisterMode, isLearningMode else {
                        unsubscribeLearnData()
                        return
                    }
                    subscribeIR()
                }
            }
        }
    }
    
    func extractValueWithJson(data: Data) -> Int? {
        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return nil
            }
            return jsonObject["ir_mode"] as? Int
        } catch {
            L.d("CHHub3Device", "JSON parsing error: \(error)")
            return nil
        }
    }
    
    func viewDidLoad() {
        startAutoMatch()
    }
    
    func setIRMode(mode: UInt8) {
        CHIRManager.shared.irModeSet(hub3DeviceId: hub3DeviceId, mode: mode) { [weak self] result in
            guard let self = self else { return }
            if case let .failure(err) = result {
                L.d(tag, "setIRMode error: \(err)")
            }
        }
            
    }
    
    func getModeTopic() -> String {
        return "hub3/\(self.hub3DeviceId)/ir/mode"
    }
    
    func getLearnDataTopic() -> String {
        return "hub3/\(self.hub3DeviceId)/ir/learned/data"
    }
    
    func unsubscribeLearnData() {
        CHIRManager.shared.unsubscribeTopic(topic: getLearnDataTopic())
    }
    
    private func subscribeIR() {
        CHIRManager.shared.subscribeTopic(topic: getLearnDataTopic()) { [weak self] onResult in
            guard let self = self else { return }
            
            if case let .failure(err) = onResult {
                L.d(self.tag, "subscribeServerForPostIRData error: \(err)")
                startAutoMatch()
                return
            }
            
            if case let .success(result) = onResult {
                if self.irMatchItemList.isEmpty {
                    self.isSearching = true
                }
                CHIRManager.shared.matchIrCode(data: result.data, type: irRemoteDevice!.type, brandName: irRemoteDevice!.model) { [weak self] getResult in
                    if case let .success(codes) = getResult {
                        self?.irMatchItemList = codes.data
                        self?.isSearching = false
                    } else if case let .failure(err) = getResult {
                        L.e(self?.tag ?? "", "matchIrCode", err)
                        self?.isSearching = false
                    }
                }
                startAutoMatch()
            }
        }
    }
    
    private func startAutoMatch() {
        isLearningMode = true
        setIRMode(mode: 0x01)
        subscribeIR()
    }
    
    
    
    
    
}
