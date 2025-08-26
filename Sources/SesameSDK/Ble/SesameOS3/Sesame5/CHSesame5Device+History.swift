//
//  CHSesame5Device+History.swift
//  SesameSDK
//  [history]read/get/post
//  Created by tse on 2023/3/9.
//  Copyright © 2023 CandyHouse. All rights reserved.
//
import Foundation
extension CHSesame5Device {
    
    func readHistoryCommand(_ result: @escaping (CHResult<CHEmpty>))  {
        L.d("[ss5][history] readHistoryCommand <=")
        URLSession.isInternetReachable { isInternetReachable in
//            L.d("[ss5][history] 連網?",isInternetReachable)
            self.sendCommand(.init( .history, "01".hexStringtoData())) { (result) in // 01: 从设备读取最旧的历史记录
                if result.cmdResultCode == .success {
                    guard isInternetReachable && !self.isConnectedByWM2 else { return }
                    self.postProcessHistory(result.data.copyData) { res in
                        if case .success(_) = res  {
                            let recordId = result.data.copyData[0...3].copyData
                            self.sendCommand(.init(SesameItemCode.historyDelete, recordId)) { response in
                                if response.cmdResultCode == .success  { L.d("[ss5][history]歷史删除成功") }
                            }
                        }
                    }
                } else {
                    (self.delegate as? CHSesame5Delegate)?.onHistoryReceived(device: self, result: .failure(self.errorFromResultCode(result.cmdResultCode)))
                    self.isHistory = false
                }
            }
        }
    }
}

extension CHSesame5Device {
    
    func getHistories(cursor: UInt?, subUUID: String?, _ result: @escaping CHResult<CHSesame5HistoryPayload>) {
//        L.d("[ss5][history] getHistories")
        guard let getKey = getKey() else {
            // Key has been deleted
            return
        }
        let secretKey = getKey.sesame2PublicKey
        var queryParams: [String: Any] = ["lg": 15, "a": secretKey, "subUUID": subUUID ?? ""]
        if let cursor = cursor {
            queryParams["cursor"] = cursor
        }
        CHAccountManager.shared
            .API(request: .init(.get, "/device/v2/sesame2/\(self.deviceId.uuidString)/history", queryParameters: queryParams)) { requestResult in

                switch requestResult {
                case .success(let data):
                    //                    L.d("[ss5][history]",data)
                    guard let historyResponse = try? JSONDecoder().decode(CHSesameHistory5Response.self, from: data ?? Data()) else {
                        result(.failure(NSError.parseError))
                        return
                    }
                    let sesame2Histories = historyResponse.histories.compactMap { self.eventToCHHistroy( historyEvent: $0) }
                    result(.success(CHResultStateNetworks(input: .init(histories: sesame2Histories, cursor: historyResponse.cursor))))
                case .failure(let error):
                    result(.failure(error))
                }
            }
    }
    
    func postProcessHistory(_ historyData: Data, _ callback: @escaping CHResult<CHEmpty>) {
//        L.d("[ss5][history]post")
        let request: CHAPICallObject = .init(.post, "/device/v1/sesame2/historys", [
            "s": self.deviceId.uuidString,
            "v": historyData.toHexString(),
            "t":"5",
        ])

        CHAccountManager
            .shared
            .API(request: request) { result in
                switch result {
                case .success(_):
                    L.d("[ss5][history]藍芽", "上傳歷史成功")
                    callback(.success(CHResultStateNetworks(input:CHEmpty())))
                    break
                case .failure(let error):
                    L.d("[ss5][history]藍芽", "上傳歷史失敗,server掉歷史: \(error)")
                    callback(.failure(error))
                    break
                }
            }
    }
}

public class CHSesame5HistoryData {
    required init(historyEvent: CHSesame5HistoryEvent) {
        self.recordID = historyEvent.recordID
        self.historyTag = historyEvent.historyTag
        self.date = Date(timeIntervalSince1970: TimeInterval(historyEvent.timeStamp/1000))
        self.timestamp = historyEvent.timeStamp
        self.mechStatus = historyEvent.parameter == nil ? nil : Sesame5MechStatus.fromData(historyEvent.parameter!)
    }
    
    public let recordID:Int32
    public let historyTag: Data?
    public let date: Date
    public let timestamp: UInt64
    public let mechStatus: CHSesameProtocolMechStatus?
}

public enum CHSesame5History {
    case manualLocked(CHSesame5HistoryData)
    case manualUnlocked(CHSesame5HistoryData)
    case bleLock(CHSesame5HistoryData)
    case bleUnlock(CHSesame5HistoryData)
    case autoLock(CHSesame5HistoryData)
    case wm2Lock(CHSesame5HistoryData)
    case wm2Unlock(CHSesame5HistoryData)
    case webLock(CHSesame5HistoryData)
    case webUnlock(CHSesame5HistoryData)
    case doorOpen(CHSesame5HistoryData)
    case doorClose(CHSesame5HistoryData)

}

extension CHSesame5Device {
    func eventToCHHistroy(historyEvent: CHSesame5HistoryEvent) -> CHSesame5History? {
        switch Sesame2HistoryTypeEnum(rawValue: historyEvent.type) {
        case .AUTOLOCK:
            return CHSesame5History.autoLock(CHSesame5HistoryData(historyEvent: historyEvent))
        case .BLE_LOCK:
            return CHSesame5History.bleLock(CHSesame5HistoryData(historyEvent: historyEvent))
        case .BLE_UNLOCK:
            return CHSesame5History.bleUnlock(CHSesame5HistoryData(historyEvent: historyEvent))
        case .WM2_UNLOCK:
            return CHSesame5History.wm2Unlock(CHSesame5HistoryData(historyEvent: historyEvent))
        case .WM2_LOCK:
            return CHSesame5History.wm2Lock(CHSesame5HistoryData(historyEvent: historyEvent))
        case .MANUAL_LOCKED:
            return CHSesame5History.manualLocked(CHSesame5HistoryData(historyEvent: historyEvent))
        case .MANUAL_UNLOCKED:
            return CHSesame5History.manualUnlocked(CHSesame5HistoryData(historyEvent: historyEvent))
        case .WEB_LOCK:
            return CHSesame5History.webLock(CHSesame5HistoryData(historyEvent: historyEvent))
        case .WEB_UNLOCK:
            return CHSesame5History.webUnlock(CHSesame5HistoryData(historyEvent: historyEvent))
        case .DOOR_OPEN:
            return CHSesame5History.doorOpen(CHSesame5HistoryData(historyEvent: historyEvent))
        case .DOOR_CLOSE:
            return CHSesame5History.doorClose(CHSesame5HistoryData(historyEvent: historyEvent))
        @unknown default:
            return nil
        }
    }
    //TODO: 此處 register 待重構，暂时迁至此处。因为 Sesame5在基类时引发了命令在指令队列已存在，不再发送命令的问题。该问题在 Sesame5独有。尚在分析中。
    public func register(result: @escaping CHResult<CHEmpty>)  {
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

        let request = CHAPICallObject(.post, "/device/v1/sesame5/\(self.deviceId.uuidString)", [
            "t":advertisement!.productType!.rawValue,
            "pk":self.mSesameToken!.toHexString()
        ])

        CHAccountManager
            .shared
            .API(request: request) { response in
                switch response {
                case .success(_):
                    self.sendCommand(.init(.registration, payload), isCipher: .plaintext) { response in
                        // 检查是否为错误响应 长度为4且最后一位为09（错误标记位）
                        // [1001297]嵌入设备在多App同时并发注册时，后注册的设备会返回4个字节长度且最后一位为09的数据。
                        if(response.data.count == 4 && response.data[3] == 0x09){
                            return
                        }
                        self.mechStatus =
                            Sesame5MechStatus.fromData(response.data[0...6])!
                        self.mechSetting = CHSesame5MechSettings.fromData(response.data[7...12])!
                        let ecdhSecretPre16 = Data(self.appKeyPair.ecdh(remotePublicKey: response.data[13...76].bytes))[0...15]

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
                        CHDeviceCenter.shared.appendDevice(self.sesame2KeyData!) // 存到SDK層的DB中
                        result(.success(CHResultStateNetworks(input: CHEmpty())))
                    }
                case .failure(let error):
                    L.d("[stp]register error",error)
                    result(.failure(error))
//                    self.deviceStatus = .waitingForAuth()
                    self.disconnect(){_ in}
                }
            }

    }

    
}
