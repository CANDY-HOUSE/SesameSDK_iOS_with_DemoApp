//
//  CHSesameBike2Device.swift
//  SesameSDK
//
//  Created by JOi Chao on 2023/5/30.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

class CHSesameBike2Device: CHSesameOS3 ,CHSesameBike2, CHDeviceUtil {

    var isConnectedByWM2 = false
    var advertisement: BleAdv? {
        didSet{
            guard let advertisement = advertisement else {
                deviceStatus = .noBleSignal()
                return
            }
            setAdv(advertisement)
            if (self.deviceStatus.loginStatus == .logined ) {
                isHistory = advertisement.adv_tag_b1
            }
        }
    }
    
    public var isHistory: Bool = false {
        didSet {
            if isHistory {
                self.readHistoryCommand(){_ in}
            }
        }
    }
    
    override  func onGattSesamePublish(_ payload: SesameOS3PublishPayload) {
        super.onGattSesamePublish(payload)
        let itemCode = payload.itemCode
        let data = payload.payload
        switch itemCode {
        case .mechStatus:
            if data.count == 7 {
                mechStatus = Sesame5MechStatus.fromData(data)!
            } else {
                mechStatus = CHSesameBike2MechStatus.fromData(data)!
            }
            self.deviceStatus = mechStatus!.isInLockRange  ? .locked() :.unlocked()
            postBatteryData(data[0..<2].toHexString())
        case .SSM3_ITEM_CODE_BATTERY_VOLTAGE:
            postBatteryData(data.toHexString())
        default:
            L.d("[bk2][publish]!![\(itemCode.rawValue)]")
        }
    }
}


extension CHSesameBike2Device {

    public func unlock(historytag: Data?, result: @escaping (CHResult<CHEmpty>))  {
        if deviceShadowStatus != nil,
           deviceStatus.loginStatus == .unlogined {
            CHIoTManager.shared.sendCommandToWM2(SesameItemCode.unlock, historytag ?? Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
        if (!self.isBleAvailable(result)) {
            CHIoTManager.shared.sendCommandToWM2(SesameItemCode.unlock, historytag ?? Data(), self) { _ in
                result(.success(CHResultStateNetworks(input: CHEmpty())))
            }
            return
        }
        sendCommand(.init(.unlock,historytag)) { responsePayload in
//            L.d("[bk2][unlock][sendCommand] res =>",responsePayload.cmdResultCode)
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }

    public func updateFirmware(result: @escaping CHResult<CBPeripheral?>) {
        result(.success(CHResultStateBLE(input: self.peripheral)))
    }

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

    func login(token: String? = nil) {
        guard let sesame2KeyData = sesame2KeyData, let sessionToken = mSesameToken else {
            return
        }
        self.deviceStatus = .bleLogining()
        let sessionAuth: Data = token?.hexStringtoData() ?? CC.CMAC.AESCMAC(sessionToken, key: sesame2KeyData.secretKey.hexStringtoData())
        self.cipher = SesameOS3BleCipher(name: self.deviceId.uuidString,sessionKey: sessionAuth,sessionToken:("00"+sessionToken.toHexString()).hexStringtoData())
        self.commandQueue = DispatchQueue(label: deviceId.uuidString, qos: .userInitiated)
        sendCommand(.init(.login, sessionAuth[0...3]), isCipher: .plaintext) { res in
//            L.d("[bk2][login]",res.data.toHexString())
            let  time = Sesame5Time.fromData(res.data).time
            let sesameTime = Date(timeIntervalSince1970: TimeInterval(time))
//            L.d("[bk2][time]", sesameTime.description(with: .current))
//            L.d("[bk2][phonetime]", Date().description(with: .current))

            let timeErrorInterval = sesameTime.timeIntervalSince1970 - Date().timeIntervalSince1970
//            L.d("[ss5][timeErrorInterval]", timeErrorInterval)
            if abs(timeErrorInterval) > 3 {
//                L.d("[bk2][timeErrorInterval>3]", timeErrorInterval)
                var timestamp: UInt32 = UInt32(Date().timeIntervalSince1970)
                let timestampData = Data(bytes: &timestamp,count: MemoryLayout.size(ofValue: timestamp))
                self.sendCommand(.init(.time,timestampData)) { res in
//                    L.d("[bk2][cmd]", timeErrorInterval,res.cmdResultCode.plainName)
                }
            }
        }
    }

    func readHistoryCommand(_ result: @escaping (CHResult<CHEmpty>))  {
        URLSession.isInternetReachable { isInternetReachable in
            self.sendCommand(.init( .history, "01".hexStringtoData())) { (result) in // 01: 从设备读取最旧的历史记录
                if result.cmdResultCode == .success {
                    let histItem = result.data.copyData
                    (self.delegate as? CHSesameBike2Delegate)?.onHistoryReceived(device: self, result: .success(CHResultStateBLE(input: histItem)))
                    guard isInternetReachable && !self.isConnectedByWM2 else { return }
                    self.postProcessHistory(result.data.copyData) { res in
                        if case .success(_) = res  {
                            let recordId = result.data.copyData[0...3].copyData
                            self.sendCommand(.init(SesameItemCode.historyDelete, recordId)) { response in
                                if response.cmdResultCode == .success  { L.d("[bike2][history]歷史删除成功") }
                            }
                        }
                    }
                } else {
                    (self.delegate as? CHSesameBike2Delegate)?.onHistoryReceived(device: self, result: .failure(self.errorFromResultCode(result.cmdResultCode)))
                    self.isHistory = false
                }
            }
        }
    }
    
    func postProcessHistory(_ historyData: Data, _ callback: @escaping CHResult<CHEmpty>) {
        CHAPIClient.shared.postHistory(deviceId: self.deviceId.uuidString, payload: historyData.toHexString(), t: "5") { result in
            switch result {
            case .success(_):
                callback(.success(CHResultStateNetworks(input:CHEmpty())))
                break
            case .failure(let error):
                callback(.failure(error))
                break
            }
        }
    }

}
