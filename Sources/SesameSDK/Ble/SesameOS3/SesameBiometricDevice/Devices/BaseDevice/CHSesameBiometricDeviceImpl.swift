//
//  CHSesameBiometricDeviceImpl.swift
//  SesameSDK
//
//  Created by frey Mac on 2026/4/3.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

class CHSesameBiometricDeviceImpl: CHSesameOS3,
                                   CHSesameBiometricDevice,
                                   CHSesameBiometricEventHost,
                                   CHDeviceUtil,
                                   CHDevice,
                                   CHMechanicalSettingsCapable,
                                   CHCardCapable,
                                   CHFingerPrintCapable,
                                   CHPassCodeCapable,
                                   CHPalmCapable,
                                   CHFaceCapable{

    let deviceType: BiometricDeviceType
    let supportedCapabilities: Set<BiometricCapability>

    private var _advertisement: BleAdv?
    private var _sesame2Keys = [String: String]()
    private var eventHandlers: [SesameItemCode: (SesameItemCode, Data) -> Void] = [:]

    let delegateManager = CHDelegateManager()

    public var mechSetting: CHSesameBaseMechSettings?
    public var triggerDelaySetting: CHRemoteBaseTriggerSettings?

    private var _radarPayload: Data = Data([0x33, 0x10, 0x00, 0x00, 0x00])
    public var radarPayload: Data {
        get { return _radarPayload }
        set {
            _radarPayload = newValue
            notifyRadarReceive(payload: _radarPayload)
        }
    }

    private let iotDeviceModels: Set<CHProductModel> = [
        .sesameTouch,
        .sesameTouch2,
        .sesameTouchPro,
        .sesameTouch2Pro,
        .sesameFace,
        .sesameFace2,
        .sesameFaceAI,
        .sesameFace2AI,
        .sesameFacePro,
        .sesameFace2Pro,
        .sesameFaceProAI,
        .sesameFace2ProAI
    ]

    init(deviceType: BiometricDeviceType, supportedCapabilities: Set<BiometricCapability>) {
        self.deviceType = deviceType
        self.supportedCapabilities = supportedCapabilities
        super.init()
    }

    required override init() {
        self.deviceType = .sesameTouch
        self.supportedCapabilities = []
        super.init()
    }

    deinit {
        clearEventHandlers()
    }

    public var sesame2Keys: [String: String] {
        get { return _sesame2Keys }
        set {
            _sesame2Keys = newValue
            (self.delegate as? CHSesameConnectorDelegate)?.onSesame2KeysChanged(device: self, sesame2keys: _sesame2Keys)
            notifySesameKeysChanged()
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

    public func getProductType() -> CHProductModel? {
        return advertisement?.productType
    }

    public func setAdvertisement(_ advertisement: Any?) {
        if let adv = advertisement as? BleAdv {
            self.advertisement = adv
        }
    }

    public func registerEventHandler(for itemCode: SesameItemCode,
                                     handler: @escaping (SesameItemCode, Data) -> Void) {
        eventHandlers[itemCode] = handler
    }

    private func clearEventHandlers() {
        eventHandlers.removeAll()
    }

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

        L.d("!![BiometricDevice][Unhandled pub][\(itemCode.rawValue)]")
    }

    public func registerProtocolDelegate(_ delegate: AnyObject, for type: Any.Type) {
        delegateManager.register(delegate, for: type)
    }

    public func unregisterProtocolDelegate(_ delegate: AnyObject, for type: Any.Type) {
        delegateManager.unregister(delegate, for: type)
    }

    public func notifyProtocolDelegates<T>(_ type: T.Type, handler: (T) -> Void) {
        delegateManager.notify(type, handler: handler)
    }

    public func goIOT() {
        if self.isGuestKey { return }

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
