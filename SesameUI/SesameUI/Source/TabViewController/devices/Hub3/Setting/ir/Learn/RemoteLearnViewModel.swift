//
//  IRControlViewModel.swift
//  SesameUI
//
//  Created by eddy on 2023/12/29.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK


extension IRRemote: CellSubItemDiscriptor {
    
    var title: String {
        return self.alias
    }
    
    func iconWithDevice(_ device: CHDevice) -> String? {
        return nil
    }
    
    func convertToCellDescriptorModel(device: CHDevice, cellCls: AnyClass) -> CHCellDescriptor {
        return CHCellDescriptor(cellCls: cellCls, rawValue: self) { cell in
            guard let emitCell = cell as? Hub3IREmitCell else {
                return
            }
            emitCell.device = device
            emitCell.configure(item: self)
        }
    }
}

extension CHSesamebot2Event: CellSubItemDiscriptor {
    
    var title: String {
        return "\("co.candyhouse.sesame2.Scripts".localized) \(self.displayName)"
    }
    
    func iconWithDevice(_ device: CHDevice) -> String? {
        return device.currentStatusImage() + "-noBorder"
    }
    
    func convertToCellDescriptorModel(device: CHDevice, cellCls: AnyClass, click: (() -> Void)?) -> CHCellDescriptor {
        return CHCellDescriptor(cellCls: cellCls, rawValue: self) { cell in
            guard let emitCell = cell as? Hub3IREmitCell else {
                return
            }
            emitCell.clickHandler = click
            emitCell.device = device
            emitCell.configure(item: self)
        }
    }
}

class RemoteLearnViewModel: NSObject {
    
    var onError: ((Error) -> Void)?
    var didUpdate: ((RemoteLearnViewModel) -> Void)?
    var onModeChange: ((RemoteLearnViewModel) -> Void)?
    var onMechStatusChange: ((CHDeviceStatus) -> Void)?
    var onIRKeysStatusChange: ((Bool) -> Void)?
    var didChange: (() -> Void)?
    
    func getRemoteName() -> String {
        return remote?.alias ?? "co.candyhouse.hub3.default_ir_title".localized
    }
    
    func updateIRRemoteAlias(_ alias: String) {
        remote?.updateAlias(alias)
    }
    
    public private(set) var dataSource = [IRCode]() {
        didSet {
            executeOnMainThread { [self] in
                self.didUpdate?(self)
            }
        }
    }
    
    var hub3DeviceId: String = ""
    var remote: IRRemote?
    
    public private(set) var isRegisterMode: Bool! = false {
        didSet {
            executeOnMainThread {
                self.onModeChange?(self)
            }
        }
    }
    
    init(hub3DeviceId: String, remote: IRRemote?) {
        self.hub3DeviceId = hub3DeviceId
        super.init()
        setRemote(remote)
        prepareHapticFeedback()
    }
    
    override init() {
        super.init()
        CHIRManager.shared.unsubscribeTopic(topic: getModeTopic())
        CHIRManager.shared.unsubscribeTopic(topic: getLearnDataTopic())
        prepareHapticFeedback()
    }
    
    deinit {
        L.d(" IRControlViewModel deinit")
    }
    
    func viewDidHide() {
        dataSource = []
    }
    
    func viewDidLoad() {
        guard let remote = remote, remote.haveSave == true else {
            postIRDevice { _ in }
            return
        }
        getIRKeys()
    }
    
    private func setRemote(_ remote: IRRemote?) {
        if let remote = remote {
            self.remote = remote
            return
        }
        
        self.remote = IRRemote(
            uuid: UUID().uuidString.uppercased(),
            alias: "co.candyhouse.hub3.default_ir_title".localized,
            model: "",
            type: IRType.DEVICE_REMOTE_CUSTOM,
            timestamp: Int(Date().timeIntervalSince1970 * 1000), state: "", code: 0, direction:"")
        self.remote?.haveSave = false
    }
    
    private func getIRKeys() {
        // from server
        CHIRManager.shared.getIRDeviceKeysByUid(hub3DeviceId, remote!.uuid) { [weak self] getResult in
            if case let .success(codes) = getResult {
                self?.dataSource = codes.data
                executeOnMainThread {
                    self?.onIRKeysStatusChange?(true)
                }
            } else if case let .failure(err) = getResult, let errCallback = self?.onError {
                executeOnMainThread {
                    errCallback(err)
                    self?.onIRKeysStatusChange?(false)
                }
            }
        }
    }
    
    private func postIRDevice(_ completion: @escaping (Bool) -> Void) {
        executeOnMainThread { [self] in
            let payload = IRDevicePayload(uuid: remote!.uuid, model: remote!.model, alias: remote!.alias, deviceUUID: hub3DeviceId,
                                          state: "", type: remote!.type, keys: self.dataSource, code: remote!.code)
            CHIRManager.shared.postIRDevice(self.hub3DeviceId, payload) { [self] result in
                if case (.success(_)) = result {
                    getIRKeys()
                } else {
                    executeOnMainThread {
                        onIRKeysStatusChange?(false)
                    }
                }
            }
        }
    }
    
    func getIRMode() {
        CHIRManager.shared.subscribeTopic(topic: getModeTopic()) { [weak self] onResult in
            guard let self = self else { return }
            
            if case let .failure(err) = onResult, let errCallback = self.onError {
                L.e("IRLearningViewModel", "getIRMode", err)
                return
            }
            
            if case let .success(result) = onResult {
                if let mode = self.extractValueWithJson(data: result.data) {
                    self.isRegisterMode = mode == 1
                    if(self.isRegisterMode) {
                        subscribeServerForPostIRDataWhenModelSwitch()
                    } else {
                        unsubscribeServerForPostIRData()
                    }
                    L.d("IRLearningViewModel", "getIRMode success mode=\(mode)", result.data.toHexString())
                }
            }
        }
        CHIRManager.shared.irModeGet(hub3DeviceId: hub3DeviceId) { [weak self] result in
            guard let self = self else { return }
            if case let .failure(err) = result, let errCallback = self.onError {
                errCallback(err)
                L.e("IRLearningViewModel","getIRMode",err)
            } else {
                L.d("IRLearningViewModel","getIRMode success from device")
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
    
    func checkNetworReachable() -> Bool {
        guard NetworkReachabilityHelper.shared.isReachable else {
            self.onError?(NSError.noNetworkError)
            return false
        }
        return true
    }
    
    func switchIRMode() {
        //BLE & Net 必须同时连接才可编辑
        guard checkNetworReachable() else { return }
        let willSet = !isRegisterMode
        setIRMode(mode: willSet ? 0x01 : 0x00)
    }
    
    func gaurdRegisterMode() {
        if(isRegisterMode) {
            setIRMode(mode: 0x00)
        }
    }
    
    func setIRMode(mode: UInt8) {
        CHIRManager.shared.irModeSet(hub3DeviceId: hub3DeviceId, mode: mode) { [weak self] result in
            guard let self = self else { return }
            if case let .failure(err) = result, let errCallback = self.onError {
                executeOnMainThread {
                    errCallback(err)
                }
                
            }
        }
    }
    
    func deleteIR(id: String, completion: @escaping (Error?) -> Void) {
        guard checkNetworReachable() else { return }
        CHIRManager.shared.irCodeDelete(hub3DeviceId: hub3DeviceId, uuid: remote!.uuid, keyUUID: id){ [weak self]  result in
            self?.didChange?()
            guard let self = self else { return }
            var isError: Error? = nil
            if case let .failure(err) = result, let errCallback = self.onError {
                errCallback(err)
                isError = err
            } else {
                self.dataSource.removeAll(where: { $0.keyUUID == id })
            }
            executeOnMainThread { completion(isError) }
        }
    }
    
    func changeIRCode(id: String, name: String, completion: @escaping (Error?) -> Void) {
        CHIRManager.shared.irCodeChange(hub3DeviceId: hub3DeviceId, uuid: remote!.uuid, keyUUID: id, name: name) { [weak self] result in
            self?.didChange?()
            guard let self = self else { return }
            var isError: Error? = nil
            if case let .failure(err) = result, let errCallback = self.onError {
                errCallback(err)
                isError = err
            } else {
                if let idx = self.dataSource.firstIndex(where: { $0.keyUUID == id }) {
                    self.dataSource[idx] = IRCode(keyUUID: id, name: name)
                }
            }
            executeOnMainThread { completion(isError) }
        }
    }
    
    func emitIRCode(id: String, completion: @escaping (Bool) -> Void) {
        self.triggerHapticFeedback()
        Debouncer(interval: 0).debounce { [weak self] in
            guard let self = self else { return }
            emit(id: id,irDeviceUUID: self.remote!.uuid) { res in
                completion(res)
            }
        }
    }
    
    func emit(id: String, irDeviceUUID: String, completion: @escaping (Bool) -> Void) {
        CHIRManager.shared.irCodeEmit(hub3DeviceId: hub3DeviceId, code: id,irDeviceUUID: irDeviceUUID, irType: 0) { [weak self] result in
            guard let self = self else { return }
            var isSuccess = true
            if case let .failure(err) = result, let errCallback = self.onError {
                executeOnMainThread { errCallback(err) }
                isSuccess = false
            }
            executeOnMainThread { completion(isSuccess) }
        }
        return
    }
    
    private func subscribeServerForPostIRData(keyUUID: String?, shouldUpdateIRCode: Bool = false) {
        CHIRManager.shared.subscribeTopic(topic: getLearnDataTopic()) { [weak self] onResult in
            guard let self = self else { return }
            
            if case let .failure(err) = onResult, let errCallback = self.onError {
                executeOnMainThread { errCallback(err) }
                CHIRManager.shared.unsubscribeTopic(topic: getLearnDataTopic())
                setIRMode(mode: 0x00)
                return
            }
            
            if case let .success(result) = onResult {
                let irData = result.data
                let irDataNameUUID = UUID().uuidString.uppercased()
                CHIRManager.shared.unsubscribeTopic(topic: getLearnDataTopic())
                setIRMode(mode: 0x00)
                CHIRManager.shared.addLearnData(data: irData,
                                        hub3DeviceUUID: hub3DeviceId,
                                        irDataNameUUID: irDataNameUUID,
                                        irDeviceUUID: remote!.uuid,
                                        keyUUID: keyUUID ?? irDataNameUUID) {
                    if case let .failure(err) = $0, let errCallback = self.onError {
                        executeOnMainThread { errCallback(err) }
                    } else if case .success = $0 {
                        if shouldUpdateIRCode {
                            self.onIRCodeChanged(ir: IRCode(keyUUID: irDataNameUUID, name: ""))
                        }
                    }
                }
            }
        }
    }
    
    func updateIRDevice(_ alias: String, _ result: @escaping CHResult<CHEmpty>){
        CHIRManager.shared.updateIRDevice(hub3DeviceId: hub3DeviceId, ["uuid": remote!.uuid, "alias": alias], result)
    }
    
    func onIRCodeChanged(ir: IRCode) {
        dataSource.append(ir)
        self.postIRDevice { _ in }
    }
    
    func subscribeServerForPostIRDataWhenEmitCode(_ keyUUID :String) {
        subscribeServerForPostIRData(keyUUID: keyUUID, shouldUpdateIRCode: false)
    }
    
    func subscribeServerForPostIRDataWhenModelSwitch() {
        subscribeServerForPostIRData(keyUUID: nil, shouldUpdateIRCode: true)
    }
    
    func unsubscribeServerForPostIRData() {
        CHIRManager.shared.unsubscribeTopic(topic: getLearnDataTopic())
    }
    
    func getModeTopic() -> String {
        return "hub3/\(self.hub3DeviceId)/ir/mode"
    }
    
    func getLearnDataTopic() -> String {
        return "hub3/\(self.hub3DeviceId)/ir/learned/data"
    }
}
