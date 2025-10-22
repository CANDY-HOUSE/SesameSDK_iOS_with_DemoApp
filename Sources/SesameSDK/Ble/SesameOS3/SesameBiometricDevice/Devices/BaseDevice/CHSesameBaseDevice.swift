//
//  CHSesameBaseDevice.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

class CHSesameBaseDevice: CHSesameOS3, CHSesameBasePro,CHDeviceUtil,CHDevice,CHSesameConnector,CHMechanicalSettingsCapable{
    
    // 存储属性
    private var _advertisement: BleAdv?
    private var _sesame2Keys = [String: String]()
    
    // 事件处理器
    private var eventHandlers: [SesameItemCode: (SesameItemCode, Data) -> Void] = [:]
    
    // 委托管理器
    let delegateManager = CHDelegateManager()
    
    // 公共属性
    public var mechSetting: CHSesameBaseMechSettings?
    public var triggerDelaySetting: CHRemoteBaseTriggerSettings?
    
    // 雷达灵敏度
    private var _radarPayload: Data = Data([0x33, 0x10, 0x00, 0x00, 0x00])
    public var radarPayload: Data {
        get { return _radarPayload }
        set {
            _radarPayload = newValue
            (self.delegate as? CHSesameConnectorDelegate)?.onRadarReceive(device: self, payload: _radarPayload)
        }
    }

    private let iotDeviceModels: Set<CHProductModel> = [
        .sesameTouch,
        .sesameTouchPro,
        .sesameFace,
        .sesameFaceAI,
        .sesameFacePro,
        .sesameFaceProAI
    ]
    
    // 初始化方法
    public override init() {
        super.init()
    }
    
    // 实现 CHDeviceManagementCapable 要求
    public func getProductType() -> CHProductModel? {
        return advertisement?.productType
    }
    
    public func setAdvertisement(_ advertisement: Any?) {
        if let adv = advertisement as? BleAdv {
            self.advertisement = adv
        }
    }
    
    // 为了兼容现有代码，保留这些属性
    public var sesame2Keys: [String: String] {
        get { return _sesame2Keys }
        set {
            _sesame2Keys = newValue
            (self.delegate as? CHSesameConnectorDelegate)?.onSesame2KeysChanged(device: self, sesame2keys: _sesame2Keys)
        }
    }
    
    public var advertisement: BleAdv? {
        get { return _advertisement }
        set {
            _advertisement = newValue
            
            guard let advertisement = _advertisement else {
                deviceStatus = .noBleSignal()
                return
            }
            setAdv(advertisement)
        }
    }
    
    
    // 注册事件处理器
    public func registerEventHandler(for itemCode: SesameItemCode, handler: @escaping (SesameItemCode, Data) -> Void) {
        eventHandlers[itemCode] = handler
    }
    
    
    // 处理蓝牙事件
    override func onGattSesamePublish(_ payload: SesameOS3PublishPayload) {
        super.onGattSesamePublish(payload)
        
        let itemCode = payload.itemCode
        let data = payload.payload
        if registerHandlers(itemCode: itemCode, payload: data) {
            return
        }
        if let handler = eventHandlers[itemCode] {
            handler(itemCode, data)
            return
        }
        
        L.d("!![BaseDevice][Unhandled pub][\(itemCode.rawValue)]")
    }
    
    // 处理公钥
    private func handlePubKeySesame(data: Data) {
        var sesame2Keys = [String: String]()
        let dividedData = data.divideArray(chunkSize: 23)
        
        for keyData in dividedData {
            let lockStatus = keyData[22]
            
            if lockStatus != 0 {
                if keyData[21] == 0x00 {
                    let deviceIDData = keyData[0...15]
                    if let sesame2DeviceId = deviceIDData.toHexString().noDashtoUUID() {
                        sesame2Keys[sesame2DeviceId.uuidString] = "05"
                    }
                } else {
                    let ss2Ir22 = keyData[0...21]
                    if let decodedData = Data(base64Encoded: (String(data: ss2Ir22, encoding: .utf8)! + "==")) {
                        if let sesame2DeviceId = decodedData.toHexString().noDashtoUUID() {
                            sesame2Keys[sesame2DeviceId.uuidString] = "04"
                        }
                    }
                }
            }
        }
        
        self.sesame2Keys = sesame2Keys
        L.d("sesame2Keys", sesame2Keys)
    }
    
    deinit {
        clearEventHandlers()
    }
    
    private func clearEventHandlers() {
        
        eventHandlers.removeAll()
    }
    
    
    func registerFingerPrintDelegate() {
        CHFingerPrintEventHandlers.registerHandlers(for: self)
    }
    
    func registerPassCodeDelegate() {
        CHPassCodeEventHandlers.registerHandlers(for: self)
    }
    
    func registerPalmDelegate() {
        CHPalmEventHandlers.registerHandlers(for: self)
    }
    
    func registerFaceDelegate() {
        CHFaceEventHandlers.registerHandlers(for: self)
    }
    
    // 实现 goIOT 方法
    public func goIOT() {
        if( self.isGuestKey){ return }
        
        guard self.productModel != nil else {
            L.d("[goIOT] productModel is nil, skipping IoT setup")
            return
        }
        
#if os(iOS)
        if productModel == .openSensor || productModel == .openSensor2 {
            goIoTWithOpenSensor()
            return
        }
        if iotDeviceModels.contains(productModel) {
            CHIoTManager.shared.subscribeCHDeviceShadow(self) { result in
                switch result {
                case .success(let content):
                    var isConnectedByWM2 = false
                    if let wm2s = content.data.wifiModule2s {
                        isConnectedByWM2 = wm2s.contains { $0.isConnected == true }
                    }
                    
                    if isConnectedByWM2 {
                        self.deviceShadowStatus = (self.mechStatus?.isInLockRange == true) ? .locked() : .unlocked()
                    } else {
                        self.deviceShadowStatus = nil
                    }
                case .failure(_):
                    break
                }
            }
        }
#endif
    }
    
    

    
}
