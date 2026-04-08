//
//  CHSesameOS3LockBase.swift
//  SesameSDK
//
//  Created by frey Mac on 2026/4/3.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

class CHSesameOS3LockBase: CHSesameOS3, CHDeviceUtil, CHSesameLock {

    var isConnectedByWM2 = false

    public var isHistory: Bool = false {
        didSet {
            if isHistory {
                self.readHistoryCommand { _ in }
            }
        }
    }

    var advertisement: BleAdv? {
        didSet {
            guard let advertisement = advertisement else {
                deviceStatus = .noBleSignal()
                return
            }
            setAdv(advertisement)
            if self.deviceStatus.loginStatus == .logined {
                isHistory = advertisement.adv_tag_b1
            }
        }
    }

    override func onGattSesamePublish(_ payload: SesameOS3PublishPayload) {
        super.onGattSesamePublish(payload)

        let itemCode = payload.itemCode
        let data = payload.payload

        switch itemCode {
        case .SSM3_ITEM_CODE_BATTERY_VOLTAGE:
            postBatteryData(data.toHexString()) { _ in }

        case .SSM3_ITEM_CODE_BLE_TX_POWER_SETTING:
            guard let value = data.first else { return }
            bleTxPower = value

        default:
            handleLockDevicePublish(payload)
        }
    }

    /// 子類覆寫：各自處理機型專屬 publish
    func handleLockDevicePublish(_ payload: SesameOS3PublishPayload) {
    }

    /// 子類覆寫：把 history 結果派發給各自 delegate
    func notifyHistoryReceived(_ result: Result<CHResultState<Data>, Error>) {
    }

    func readHistoryCommand(_ result: @escaping (CHResult<CHEmpty>)) {
        URLSession.isInternetReachable { isInternetReachable in
            self.sendCommand(.init(.history, "01".hexStringtoData())) { response in
                if response.cmdResultCode == .success {
                    let histItem = response.data.copyData
                    self.notifyHistoryReceived(.success(CHResultStateBLE(input: histItem)))

                    guard isInternetReachable && !self.isConnectedByWM2 else { return }

                    self.postProcessHistory(response.data.copyData) { res in
                        if case .success(_) = res {
                            let recordId = response.data.copyData[0...3].copyData
                            self.sendCommand(.init(SesameItemCode.historyDelete, recordId)) { _ in }
                        }
                    }
                } else {
                    self.notifyHistoryReceived(.failure(self.errorFromResultCode(response.cmdResultCode)))
                    self.isHistory = false
                }
            }
        }
    }

    func postProcessHistory(_ historyData: Data, _ callback: @escaping CHResult<CHEmpty>) {
        CHAPIClient.shared.postHistory(deviceId: self.deviceId.uuidString, payload: historyData.toHexString(), t: "5") { result in
            switch result {
            case .success(_):
                callback(.success(CHResultStateNetworks(input: CHEmpty())))
            case .failure(let error):
                callback(.failure(error))
            }
        }
    }

    func setBleTxPower(txPower: UInt8, result: @escaping (CHResult<CHEmpty>)) {
        if !isBleAvailable(result) { return }

        sendCommand(.init(.SSM3_ITEM_CODE_BLE_TX_POWER_SETTING, Data([txPower]))) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }
}
