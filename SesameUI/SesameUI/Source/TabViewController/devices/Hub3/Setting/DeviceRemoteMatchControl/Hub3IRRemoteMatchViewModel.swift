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
    
    // MARK: - State Management
    private var uiState: IRMatchUIState = .loading {
        didSet {
            notifyUIStateObservers()
        }
    }
    private var uiStateObservers: [(IRMatchUIState) -> Void] = []
    
    private var irCompanyCode: IRCompanyCode? {
        didSet {
            notifyIRCompanyCodeObservers()
        }
    }
    private var irCompanyCodeObservers: [(IRCompanyCode?) -> Void] = []
    
    private var irRemoteDevice: IRRemote? {
        didSet {
            notifyIRRemoteDeviceObservers()
        }
    }
    private var irRemoteDeviceObservers: [(IRRemote?) -> Void] = []
    
    private(set) var irMatchItemList: [IrControlItem] = [] {
        didSet {
            notifyIRMatchItemListObservers()
        }
    }
    private var irMatchItemListObservers: [([IrControlItem]) -> Void] = []
    
    // MARK: - Private Properties
    private var device: CHHub3!
    private var items: [IrControlItem] = []
    private var config: UIControlConfig?
    private var currentMatchCodeIndex = 0
    //    private var currentCompanyCode: IRCompanyCode!
    
    // MARK: - Initialization
    init(device: CHHub3,irRemote: IRRemote) {
        self.device = device
        self.irRemoteDevice = irRemote
        self.remoteRepository = RemoteRepository()
        setupMatchData(productKey: irRemote.type)
    }
    
    // MARK: - Observer Registration
    func observeUIState(_ handler: @escaping (IRMatchUIState) -> Void) {
        uiStateObservers.append(handler)
        handler(uiState)
    }
    
    func observeIRCompanyCode(_ handler: @escaping (IRCompanyCode?) -> Void) {
        irCompanyCodeObservers.append(handler)
        handler(irCompanyCode)
    }
    
    func observeIRRemoteDevice(_ handler: @escaping (IRRemote?) -> Void) {
        irRemoteDeviceObservers.append(handler)
        handler(irRemoteDevice)
    }
    
    func observeIRMatchItemList(_ handler: @escaping ([IrControlItem]) -> Void) {
        irMatchItemListObservers.append(handler)
        handler(irMatchItemList)
    }
    
    // MARK: - Private Notification Methods
    private func notifyUIStateObservers() {
        uiStateObservers.forEach { $0(uiState) }
    }
    
    private func notifyIRCompanyCodeObservers() {
        irCompanyCodeObservers.forEach { $0(irCompanyCode) }
    }
    
    private func notifyIRRemoteDeviceObservers() {
        irRemoteDeviceObservers.forEach { $0(irRemoteDevice) }
    }
    
    private func notifyIRMatchItemListObservers() {
        irMatchItemListObservers.forEach { $0(irMatchItemList) }
    }
    
    // MARK: - Public Methods
    func setupMatchData(productKey: Int) {
        let callback = MatchCallbackWrapper { [weak self] item in
            
        }
        remoteRepository.initialize(type: irRemoteDevice!.type,uiItemCallback: callback, handlerCallback: callback)
        loadInitialState()
        buildMatchItemList()
    }
    
    func getCurrentIrControlItem(position: Int) -> IrControlItem? {
        return remoteRepository.getMatchItem(position: position, items: items)
    }
    
    func handleItemClick(position: Int) {
        guard let irCompanyCode = irCompanyCode,
              let device = device,
              let currentItem = getCurrentIrControlItem(position: position) else {
            L.d(tag, "ERROR! get item at position: \(position)")
            return
        }
        
        do {
            try remoteRepository.handleItemClick(
                item: currentItem,
                device: device,
                remoteDevice: getCurrentRemoteDevice()
            )
        } catch {
            L.d(tag, "handleItemClick error: \(error)")
        }
    }
    
    func setDevice(_ device: CHHub3) {
        self.device = device
    }
    
    func setIrCompanyCode(_ ircompanyCode: IRCompanyCode) {
        L.d(tag, "setIrCompanyCode ircompanyCode=\(ircompanyCode.code)")
        self.irCompanyCode = ircompanyCode
        remoteRepository.setCurrentState("")
    }
    
    func getCompanyCodeByModel(completion: @escaping (IRCompanyCode?) -> Void) {
        executeOnBackgroundThread { [weak self] in
            guard let self = self else { return }
            remoteRepository.getCompanyCodeList { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let companyCodeList):
                    if companyCodeList.isEmpty {
                        executeOnMainThread {
                            L.d(self.tag, "Load Company Code error !")
                            completion(nil)
                        }
                        return
                    }
                    
                    let matchedCompany = companyCodeList.first(where: {
                        self.irRemoteDevice!.model.lowercased().hasPrefix($0.name.lowercased())
                    })
                    executeOnMainThread  {
                        if let matchedCompany = matchedCompany {
                            L.d(self.tag, "Load Company name：\(matchedCompany.name) code: \(matchedCompany.code)")
                            self.setIrCompanyCode(matchedCompany)
                        } else {
                            L.d(self.tag, "Can't load \(self.irRemoteDevice!.model) companyCode")
                        }
                        completion(matchedCompany)
                    }
                    
                    
                case .failure(let error):
                    L.d(self.tag, "Failed to get company code list: \(error)")
                }
            }
        }
    }
    
    
    func postIrRemoteDevice(name: String, _ completion: @escaping (Bool) -> Void) {
        var state = irRemoteDevice!.state
        if(state == "") {
            state = remoteRepository.getCurrentState(hub3: device, remoteDevice: irRemoteDevice!)
        }
        let payload = IRDevicePayload(uuid: irRemoteDevice!.uuid, model: irRemoteDevice!.model, alias: name, deviceUUID: device.deviceId.uuidString, state: state ?? "", type: irRemoteDevice!.type, keys: [],code: irRemoteDevice!.code)
        device.postIRDevice(payload){ [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                if let index = self.device.irRemotes.firstIndex(where: { remote in
                    return remote.uuid == payload.uuid
                }) {
                    self.device.preference.updateSelectExpandIndex(index)
                }
                L.d(self.tag, "Add IR device success,  index =\(index) state=\(self.irRemoteDevice?.state)")
                executeOnMainThread {
                    self.irRemoteDevice?.haveSave = true
                    completion(true)
                }
                L.d(self.tag, "addIRDeviceInfo success uuid=\(payload.uuid)")
                
            case .failure(let error):
                executeOnMainThread {
                    completion(false)
                }
                L.d(self.tag, "addIRDeviceInfo fail: \(error)")
            }
        }
    }
    
    func getCurrentRemoteDevice() -> IRRemote {
        return IRRemote(
            uuid: "",
            alias: irCompanyCode?.name ?? "",
            model: irCompanyCode!.name,
            type: 0,
            timestamp: Int(Date().timeIntervalSince1970),
            state: "",
            code: irCompanyCode?.code[safe: currentMatchCodeIndex + 1] ?? -1,
            direction: irCompanyCode!.direction
        )
    }
    
    func initMatchParams() {
        remoteRepository.initMatchParams()
    }
    
    func matchNextCode() {
        if currentMatchCodeIndex < getTotalCodeCounts() - 1 {
            currentMatchCodeIndex += 1
        }
    }
    
    func getCurrentCodeIndex() -> Int {
        return currentMatchCodeIndex
    }
    
    func getTotalCodeCounts() -> Int {
        var totalSize = irCompanyCode?.code.count ?? 0
        if totalSize > 1 {
            totalSize -= 1
        }
        return totalSize
    }
    
    // MARK: - Private Methods
    private func handleItemUpdate(_ item: IrControlItem) {
        guard let config = config, !items.isEmpty else { return }
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            executeOnMainThread { [weak self] in
                guard let self = self else { return }
                self.uiState = .success(
                    items: self.items,
                    layoutSettings: config.settings.layout,
                    timestamp: Int64(Date().timeIntervalSince1970 * 10) + Int64.random(in: 0...9)
                )
            }
        }
    }
    
    private func buildMatchItemList() {
        executeOnBackgroundThread {[weak self] in
                guard let self = self else { return }
                let list = remoteRepository.getMatchUiItemList()
                executeOnMainThread { [weak self] in
                    self?.irMatchItemList = list
                }
        }
    }
    
    private func loadInitialState() {
        remoteRepository.loadUIConfig { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let config):
                self.config = config
                self.loadUIParams()
            case .failure(let error):
                self.uiState = .error(error)
            }
        }
    }
    
    private func loadUIParams() {
        remoteRepository.loadUIParams { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let items):
                self.items = items
                if let config = self.config {
                    self.refreshAllItems(config: config)
                }
                
            case .failure(let error):
                self.uiState = .error(error)
            }
        }
    }
    
    
    private func refreshAllItems(config: UIControlConfig) {
        executeOnMainThread { [weak self] in
            guard let self = self else { return }
            self.uiState = .success(
                items: self.items,
                layoutSettings: config.settings.layout,
                timestamp: Int64(Date().timeIntervalSince1970 * 10) + Int64.random(in: 0...9)
            )
        }
    }
    
    func getInitIrRemoteDevice() -> IRRemote? {
        return irRemoteDevice
    }
    
    deinit {
        remoteRepository.clearConfigCache()
        remoteRepository.clearHandlerCache()
    }
}

// MARK: - UI State
enum IRMatchUIState {
    case loading
    case success(items: [IrControlItem], layoutSettings: LayoutSettings, timestamp: Int64)
    case error(Error)
}





struct IRCompanyCode: Codable {
    let code: [Int]
    let name: String
    let direction: String
}


struct MatchCallbackWrapper: HandlerCallback, ConfigUpdateCallback {
    private let callback: (IrControlItem) -> Void
    
    init(_ callback: @escaping (IrControlItem) -> Void) {
        self.callback = callback
    }
    
    // HandlerCallback implementation
    func onItemUpdate(item: IrControlItem) {
        callback(item)
    }
    
    // ConfigUpdateCallback implementation
    func onItemUpdate(_ item: IrControlItem) {
        callback(item)
    }
}
