//
//  IRControlViewModel.swift
//  SesameUI
//
//  Created by eddy on 2023/12/29.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

enum IREntryType {
    case manual
    case repository
}

enum IREmitState {
    case ready
    case emitting
    case unavailable
}

enum IRMode {
    case normal
    case edit
}

struct IRItem {
    var mode: IRMode
    var title: String
    var state: IREmitState
    //    var imageName: String = ""
    var rawValue: CHHub3IRCode
}

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

extension CHHub3IRCode {
    func toIRItem() -> IRItem {
        return IRItem(mode: .normal, title: name ?? "", state: IREmitState.ready, rawValue: self)
    }
}

class IRLearningViewModel: NSObject {
    
    public private(set) lazy var payload = {
        var uuid = UUID().uuidString.uppercased()
        var name = ""
        if device.preference.selectExpandIndex > -1,
           device.preference.selectExpandIndex < device.irRemotes.count {
            uuid = device.irRemotes[device.preference.selectExpandIndex].uuid
            name = device.irRemotes[device.preference.selectExpandIndex].alias
        }
        return IRDevicePayload(uuid: uuid, model: "", alias: name,  deviceUUID: device.deviceId.uuidString, state: "", type: IRDeviceType.DEVICE_REMOTE_CUSTOM, keys: [],code: 0 )
    }()
    var onError: ((Error) -> Void)?
    var didUpdate: ((IRLearningViewModel) -> Void)?
    var onModeChange: ((IRLearningViewModel) -> Void)?
    var onMechStatusChange: ((CHDeviceStatus) -> Void)?
    var onIRKeysStatusChange: ((Bool) -> Void)?
    var didChange: (() -> Void)?
    
    func getRemoteName() -> String {
        if payload.alias.isEmpty {
            payload.alias = "co.candyhouse.hub3.default_ir_title".localized
        }
        return payload.alias
    }
    
    func updateIRRemoteAlias(_ alias: String) {
        guard let index = device.irRemotes.firstIndex(where: { $0.uuid == payload.uuid }) else { return }
        device.irRemotes[index].updateAlias(alias)
        payload.alias = alias
    }
    
    public private(set) var dataSource = [IRItem]() {
        didSet {
            executeOnMainThread { [self] in
                self.payload.keys = dataSource.compactMap({ $0.rawValue })
                self.didUpdate?(self)
            }
        }
    }
    private var tempSource = [IRItem]()
    
    weak var device: CHHub3! {
        didSet {
            device.delegate = self
        }
    }
    
    public private(set) var isRegisterMode: Bool! = false {
        didSet {
            executeOnMainThread {
                self.onModeChange?(self)
            }
        }
    }
    
    init(device: CHHub3) {
        self.device = device
        super.init()
        device.delegate = self
        prepareHapticFeedback()
    }
    
    override init() {
        super.init()
        self.device.unsubscribeLearnData()
        prepareHapticFeedback()
    }
    
    deinit {
        L.d(" IRControlViewModel deinit")
    }
    
    func viewWillLoad() {
        guard device.deviceStatus.loginStatus == .unlogined else { return }
        device.connect { _ in }
    }
    
    func viewDidHide() {
        dataSource = []
        guard device.deviceStatus.loginStatus == .logined else { return }
        device.disconnect { _ in }
    }
    
    func viewDidLoad() {
        if device.preference.selectExpandIndex > -1,
           device.preference.selectExpandIndex < device.irRemotes.count {
            getIRKeys()
        } else {
            postIRDevice { _ in }
        }
    }
    
    private func getIRKeys() {
        // from server
        guard !device.irRemotes.isEmpty else { return }
        device.getIRDeviceKeysByUid(payload.uuid) { [weak self] getResult in
            if case let .success(codes) = getResult {
                self?.dataSource = codes.data.compactMap({ $0.toIRItem() })
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
            device.postIRDevice(self.payload) { [self] result in
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
    
    func fetchIRMode(completion: @escaping (Bool) -> Void) {
        device.irModeGet { [weak self] result in
            guard let self = self else { return }
            var isSuccess = true
            if case let .failure(err) = result, let errCallback = self.onError {
                errCallback(err)
                isSuccess = false
            } else if case let .success(mode) = result {
                self.isRegisterMode = mode.data == 1
            }
            executeOnMainThread { completion(isSuccess) }
        }
    }
    
    func checkNetworReachable() -> Bool {
        guard NetworkReachabilityHelper.shared.isReachable else {
            self.onError?(NSError.noNetworkError)
            return false
        }
        return true
    }
    
    func switchIRMode(completion: @escaping (Bool) -> Void) {
        //BLE & Net 必须同时连接才可编辑
        guard checkNetworReachable() else { return }
        let willSet = !isRegisterMode
        setIRMode(mode: willSet ? 0x01 : 0x00, completion: completion)
    }
    
    func gaurdRegisterMode() {
        if(isRegisterMode) {
            setIRMode(mode: 0x00){_ in}
        }
    }
    
    func setIRMode(mode: UInt8, completion: @escaping (Bool) -> Void) {
        device.irModeSet(mode: mode) { [weak self] result in
            guard let self = self else { return }
            var isSuccess = true
            if case let .failure(err) = result, let errCallback = self.onError {
                errCallback(err)
                isSuccess = false
            } else {
                self.isRegisterMode.toggle()
            }
            executeOnMainThread { completion(isSuccess) }
        }
    }
    
    func deleteIR(id: String, completion: @escaping (Error?) -> Void) {
        guard checkNetworReachable() else { return }
        device.irCodeDelete(uuid: payload.uuid, keyUUID: id){ [weak self]  result in
            self?.didChange?()
            guard let self = self else { return }
            var isError: Error? = nil
            if case let .failure(err) = result, let errCallback = self.onError {
                errCallback(err)
                isError = err
            } else {
                self.dataSource.removeAll(where: { $0.rawValue.keyUUID == id })
            }
            executeOnMainThread { completion(isError) }
        }
    }
    
    func changeIRCode(id: String, name: String, completion: @escaping (Error?) -> Void) {
        device.irCodeChange(uid: payload.uuid, keyUUID: id, name: name) { [weak self] result in
            self?.didChange?()
            guard let self = self else { return }
            var isError: Error? = nil
            if case let .failure(err) = result, let errCallback = self.onError {
                errCallback(err)
                isError = err
            } else {
                if let idx = self.dataSource.firstIndex(where: { $0.rawValue.keyUUID == id }) {
                    self.dataSource[idx] = CHHub3IRCode(keyUUID: id, name: name).toIRItem()
                }
            }
            executeOnMainThread { completion(isError) }
        }
    }
    
    func emitIRCode(id: String, completion: @escaping (Bool) -> Void) {
        self.triggerHapticFeedback()
        Debouncer(interval: 0).debounce { [weak self] in
            guard let self = self else { return }
            emit(id: id,irDeviceUUID: self.payload.uuid) { res in
                completion(res)
            }
        }
    }
    
    func emit(id: String, irDeviceUUID: String, completion: @escaping (Bool) -> Void) {
        device.irCodeEmit(id: id,irDeviceUUID: irDeviceUUID) { [weak self] result in
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
        self.device.subscribeLearnData() { [weak self] onResult in
            guard let self = self else { return }
            
            if case let .failure(err) = onResult, let errCallback = self.onError {
                executeOnMainThread { errCallback(err) }
                return
            }
            
            if case let .success(result) = onResult {
                let irData = result.data
                let irDataNameUUID = UUID().uuidString.uppercased()
                self.device.addLearnData(data: irData,
                                        hub3DeviceUUID: self.device.deviceId.uuidString,
                                        irDataNameUUID: irDataNameUUID,
                                        irDeviceUUID: self.payload.uuid,
                                        keyUUID: keyUUID ?? irDataNameUUID) {
                    if case let .failure(err) = $0, let errCallback = self.onError {
                        executeOnMainThread { errCallback(err) }
                    } else if case .success = $0 {
                        if shouldUpdateIRCode {
                            self.onIRCodeChanged(device: self.device,
                                                ir: CHHub3IRCode(keyUUID: irDataNameUUID, name: ""))
                        }
                    }
                }
            }
        }
    }
    
    func subscribeServerForPostIRDataWhenEmitCode(_ keyUUID :String) {
        subscribeServerForPostIRData(keyUUID: keyUUID, shouldUpdateIRCode: false)
    }
    
    func subscribeServerForPostIRDataWhenModelSwitch() {
        subscribeServerForPostIRData(keyUUID: nil, shouldUpdateIRCode: true)
    }
    
    func unsubscribeServerForPostIRData() {
        self.device.unsubscribeLearnData()
    }
}

extension IRLearningViewModel: CHHub3Delegate {
    
    
    func onSesame2KeysChanged(device: CHWifiModule2, sesame2keys: [String : String]) {
        
    }
    
    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus, shadowStatus: CHDeviceStatus?) {
        executeOnMainThread {
            self.onMechStatusChange?(status)
        }
    }
    
    func onMechStatus(device: CHDevice) {
        
    }
    
    func onIRModeReceive(device: SesameSDK.CHHub3, mode: UInt8) {
        isRegisterMode = mode == 1
    }
    
    func onIRCodeChanged(device: CHHub3, ir: CHHub3IRCode) {
        dataSource.append(ir.toIRItem())
        self.postIRDevice { _ in }
    }
    
    func onIRCodeReceiveStart(device: CHHub3) {
        tempSource.removeAll()
    }
    
    func onIRCodeReceive(device: CHHub3, ir: CHHub3IRCode) {
        tempSource.append(ir.toIRItem())
    }
    
    func onIRCodeReceiveEnd(device: CHHub3) {
        dataSource = Array(tempSource)
        tempSource.removeAll()
    }
}
