//
//  CHSesameBot2Device.swift
//  SesameSDK
//
//  Created by eddy on 2023/12/13.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

class CHSesameBot2Device: CHSesameOS3, CHSesameBot2, CHDeviceUtil {
    
    var scripts: CHSesamebot2Status = {
        var events = [CHSesamebot2Event]()
        for i in 0...9 {
            events.append(CHSesamebot2Event(nameLength: 1, name: [UInt8(48 + i)]))
        }
        let status = CHSesamebot2Status(curIdx: 0, eventLength: 10, events: events)
        return status
    }()
    
    var advertisement: BleAdv? {
        didSet{
            guard let advertisement = advertisement else {
                deviceStatus = .noBleSignal()
                return
            }
            setAdv(advertisement)
        }
    }
    
    override func onGattSesamePublish(_ payload: SesameOS3PublishPayload) {
        super.onGattSesamePublish(payload)
        let itemCode = payload.itemCode
        let data = payload.payload
        switch itemCode {
        case .mechStatus:
            mechStatus = CHSesameBike2MechStatus.fromData(data)!
            self.deviceStatus = mechStatus!.isInLockRange  ? .locked() :.unlocked()
        default:
            L.d("[bot2][publish]!![\(data.bytes)]")
        }
    }
    
    func goIOT() {
        if( self.isGuestKey){ return }
#if os(iOS)
        CHIoTManager.shared.subscribeCHDeviceShadow(self) { result in
            switch result {
            case .success(let content):
                var isConnectedByWM2 = false
                if let wm2s = content.data.wifiModule2s {
                    isConnectedByWM2 = wm2s.filter({ $0.isConnected == true }).count > 0
                }
                if isConnectedByWM2,
                   let mechStatusData = content.data.mechStatus?.hexStringtoData(),
                   let mechStatus = CHSesameBike2MechStatus.fromData(mechStatusData) {
                    self.mechStatus = mechStatus
                }
                if isConnectedByWM2 {
                    self.deviceShadowStatus = (self.mechStatus?.isInLockRange == true) ? .locked() : .unlocked()
                }else{
                    self.deviceShadowStatus = nil
                }
            case .failure( _): break
            }
        }
#endif
    }
}

extension CHSesameBot2Device {
    
    func click(index: UInt8? = nil, result: @escaping (CHResult<CHEmpty>)) {
        var itemCode = SesameItemCode.click
        if let idx = index {
            itemCode = SesameItemCode(rawValue: UInt8(SesameItemCode.BOT2_ITEM_CODE_RUN_SCRIPT_0.rawValue) + idx) ?? .click
        }
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined {
            CHIoTManager.shared.sendCommandToWM2(itemCode, Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
        if (!self.isBleAvailable(result)) {
            CHIoTManager.shared.sendCommandToWM2(itemCode, Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
        sendCommand(.init(itemCode)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
    func sendClickScript(index: UInt8, script: Data, result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(SesameItemCode.BOT2_ITEM_CODE_EDIT_SCRIPT, Data([index]) + script)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
    
    func selectScript(index: UInt8, result: @escaping (CHResult<CHEmpty>)) {
        result(.success(CHResultStateBLE(input:CHEmpty())))
    }
    
    func getCurrentScript(index: UInt8?, result: @escaping (CHResult<CHSesamebot2Event>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(SesameItemCode.scriptCurrent, index != nil ? Data([index!]) : nil)) { payload in
            L.d("[getCurrentScript] all: ", payload.data.bytes)
            if payload.cmdResultCode == .success {
                if let resp = CHSesamebot2Event.fromData(payload.data) {
                    result(.success(CHResultStateBLE(input: resp)))
                } else {
                    result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
                }
            } else {
                result(.failure(self.errorFromResultCode(payload.cmdResultCode)))
            }
        }
    }
    
    func getScriptNameList(result: @escaping (CHResult<CHSesamebot2Status>)) {
        result(.success(CHResultStateBLE(input: self.scripts)))
    }
}

extension CHSesameBot2Device {
    func register(result: @escaping CHResult<CHEmpty>)  {
        if deviceStatus != .readyToRegister() {
            result(.failure(NSError.deviceStatusNotReadyToRegister))
            return
        }
        deviceStatus = .registering()
        
        let date = Date()
        var timestamp: UInt32 = UInt32(date.timeIntervalSince1970)
        let timestampData = Data(bytes: &timestamp,count: MemoryLayout.size(ofValue: timestamp))
        let payload = Data(appKeyPair.publicKey)+timestampData
        self.commandQueue = DispatchQueue(label:deviceId.uuidString, qos: .userInitiated)
        //        L.d("[bk2]register item",deviceId.uuidString)
        let request = CHAPICallObject(.post, "/device/v1/sesame5/\(self.deviceId.uuidString)", [
            "t": self.advertisement!.productType!.rawValue,
            "pk": self.mSesameToken!.toHexString()
        ])
        
        CHAccountManager
            .shared
            .API(request: request) { response in
                switch response {
                case .success(_):
                    self.sendCommand(.init(.registration, payload), isCipher: .plaintext) { response in
                        var ecdhSecretPre16 = Data()
                        if (self.appKeyPair.havePubKey(remotePublicKey: response.data[13...76].bytes)) { // 新协议
                            ecdhSecretPre16 = Data(self.appKeyPair.ecdh(remotePublicKey: response.data[13...76].bytes))[0...15]
                            self.mechStatus = CHSesameBike2MechStatus.fromData(response.data[0...6])!
                        } else {
                            ecdhSecretPre16 = Data(self.appKeyPair.ecdh(remotePublicKey: response.data[3...66].bytes))[0...15]
                            self.mechStatus = CHSesameBike2MechStatus.fromData(response.data[0...2])!
                        }
                        self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString, sessionKey: CC.CMAC.AESCMAC(self.mSesameToken!, key: ecdhSecretPre16),sessionToken: ("00"+self.mSesameToken!.toHexString()).hexStringtoData())
                        self.sesame2KeyData = CHDeviceKey(// 建立設備
                            deviceUUID: self.deviceId,
                            deviceModel: self.productModel.deviceModel(),
                            historyTag: nil,
                            keyIndex: "0000",
                            secretKey: ecdhSecretPre16.toHexString(),
                            sesame2PublicKey: self.mSesameToken!.toHexString()
                        )
                        self.isRegistered = true // 設定為已註冊
                        self.goIOT()
                        self.deviceStatus = self.mechStatus!.isInLockRange  ? .locked() :.unlocked()
                        CHDeviceCenter.shared.appendDevice(self.sesame2KeyData!) // 存到SDK層的DB中(why?!
                        result(.success(CHResultStateNetworks(input: CHEmpty())))
                    }
                case .failure(let error):
                    L.d("[stp][bk2]register error",error)
                    result(.failure(error))
                    //                    self.deviceStatus = .waitingForAuth()
                    self.disconnect(){_ in}
                }
            }
    }
}
