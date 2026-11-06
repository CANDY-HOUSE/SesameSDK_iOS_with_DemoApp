//
//  CHDeviceUtil+OS3.swift
//  SesameSDK
//
//  Created by eddy on 2023/12/25.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

// os3下的通用工具集合
extension CHDeviceUtil where Self: CHSesameOS3 & CHDevice {
    
    /// 登录
    /// - Parameter token: 用戶token
    func login(token: String? = nil) {
        guard let sesame2KeyData = sesame2KeyData, let sessionToken = mSesameToken else { return }
        self.deviceStatus = .bleLogining()
        let sessionAuth: Data = token?.hexStringtoData() ?? CC.CMAC.AESCMAC(sessionToken, key: sesame2KeyData.secretKey.hexStringtoData())
        self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString,sessionKey: sessionAuth,sessionToken:("00"+sessionToken.toHexString()).hexStringtoData())
        self.commandQueue = DispatchQueue(label: deviceId.uuidString, qos: .userInitiated)
        sendCommand(.init(.login, sessionAuth[0...3]), isCipher: .plaintext) { [weak self] res in
            guard let self = self else { return }
            self.handleLoginReceived(res)
        }
    }
    
    /// 處理登陸結果需要歷史紀錄時才需要同步時間
    /// - Parameter res: response
    func handleLoginReceived(_ res: SesameOS3CmdResponsePayload) {
        guard let _ = self as? CHSesame5 else { return }
        guard res.cmdResultCode == .success, let time = Sesame5Time.fromData(res.data)?.time else {
            L.d("[os3][login] skip time sync", res.cmdResultCode.plainName, res.data.count)
            return
        }
        let sesameTime = Date(timeIntervalSince1970: TimeInterval(time))
        let timeErrorInterval = sesameTime.timeIntervalSince1970 - Date().timeIntervalSince1970
        if abs(timeErrorInterval) > 3 {
            var timestamp: UInt32 = UInt32(Date().timeIntervalSince1970)
            let timestampData = Data(bytes: &timestamp,count: MemoryLayout.size(ofValue: timestamp))
            self.sendCommand(.init(.time,timestampData)) { res in
                L.d("[os3][cmd]", timeErrorInterval,res.cmdResultCode.plainName)
            }
        }
    }
    
    func register(result: @escaping CHResult<CHEmpty>)  {
        guard deviceStatus == .readyToRegister(), let sessionToken = mSesameToken, let productType = advertisement?.productType else {
            result(.failure(NSError.deviceStatusNotReadyToRegister))
            return
        }
        deviceStatus = .registering()

        var timestamp: UInt32 = UInt32(Date().timeIntervalSince1970)
        let timestampData = Data(bytes: &timestamp,count: MemoryLayout.size(ofValue: timestamp))
        let payload = Data(appKeyPair.publicKey)+timestampData
        self.commandQueue = DispatchQueue(label:deviceId.uuidString, qos: .userInitiated)

        CHBleSupport.host.registerOs3(deviceId: deviceId, productType: Int(productType.rawValue), publicKey: sessionToken.toHexString()) { response in
            switch response {
            case .success(_):
                self.sendCommand(.init(.registration, payload), isCipher: .plaintext) { response in
                    // A device registered concurrently by another app answers 4 bytes ending in 0x09.
                    if(response.data.count == 4 && response.data[response.data.startIndex + 3] == 0x09){
                        return
                    }
                    let data = Data(response.data)
                    let secret: Data
                    let mechStatus: CHSesameProtocolMechStatus
                    do {
                        if data.count >= 77, self.appKeyPair.havePubKey(remotePublicKey: data[13...76].bytes),
                           let status = Sesame5MechStatus.fromData(data[0...6]) {
                            secret = Data(try self.appKeyPair.ecdh(remotePublicKey: data[13...76].bytes))[0...15]
                            mechStatus = status
                            if let sesame5Device = self as? CHSesame5Device {
                                sesame5Device.mechSetting = CHSesame5MechSettings.fromData(data[7...12])
                            }
                        } else if data.count >= 67, let status = CHSesameBike2MechStatus.fromData(data[0...2]) {
                            secret = Data(try self.appKeyPair.ecdh(remotePublicKey: data[3...66].bytes))[0...15]
                            mechStatus = status
                        } else {
                            throw NSError.parseError
                        }
                    } catch {
                        self.deviceStatus = .readyToRegister()
                        self.disconnect { _ in }
                        result(.failure(error))
                        return
                    }
                    self.mechStatus = mechStatus
                    self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString, sessionKey: CC.CMAC.AESCMAC(sessionToken, key: secret),sessionToken: ("00"+sessionToken.toHexString()).hexStringtoData())
                    let key = CHDeviceKey(
                        deviceUUID: self.deviceId,
                        deviceModel: self.productModel.deviceModel(),
                        historyTag: nil,
                        keyIndex: "0000",
                        secretKey: secret.toHexString(),
                        sesame2PublicKey: sessionToken.toHexString()
                    )
                    self.sesame2KeyData = key
                    self.isRegistered = true
                    self.deviceStatus = mechStatus.isInLockRange  ? .locked() :.unlocked()
                    CHBleSupport.keys.save(key)
                    result(.success(CHResultStateNetworks(input: CHEmpty())))
                }
            case .failure(let error):
                L.d("[stp]register error",error)
                result(.failure(error))
                self.disconnect(){_ in}
            }
        }
    }

    /// 更新固件
    /// - Parameter result: 返回 peripheral
    func updateFirmware(result: @escaping CHResult<CBPeripheral?>) {
        result(.success(CHResultStateBLE(input: self.peripheral)))
    }
    
    /// 獲取固件當前版本號
    /// - Parameter result: 版本號
    func getVersionTag(result: @escaping (CHResult<String>))  {
        if(!isBleAvailable(result)){return}
        sendCommand(.init(.versionTag)) { (response) in
            if response.cmdResultCode == .success {
                let versionTag = String(data: response.data, encoding: .utf8) ?? ""
                result(.success(CHResultStateNetworks(input: versionTag)))
                CHBleSupport.host.postFirmwareVersion(deviceId: self.deviceId, versionTag: versionTag) { _ in }
            } else {
                result(.failure(self.errorFromResultCode(response.cmdResultCode)))
            }
        }
    }
    
    /// 重置設備
    /// - Parameter result: 返回結果
    func reset(result: @escaping (CHResult<CHEmpty>)) {
        if (!self.isBleAvailable(result)) { return }
        sendCommand(.init(.reset)) { (responsePayload) in
            self.dropKey { dropResult in
                switch dropResult {
                case .success(_):
                    result(.success(CHResultStateNetworks(input: CHEmpty())))
                case .failure(let error):
                    result(.failure(error))
                }
            }
        }
    }
    
}
