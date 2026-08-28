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
    private(set) var sensorDetectIntervalMs: Int16 = CHDeviceUnsetSensorDetectInterval {
        didSet {
            guard oldValue != sensorDetectIntervalMs,
                  let device = self as? CHSesame5 else { return }
            (delegate as? CHSesame5Delegate)?.onSensorDetectIntervalReceive(
                device: device,
                intervalMs: sensorDetectIntervalMs
            )
        }
    }
    private(set) var lockUnlockSwitchPoint: Int16 = 0
    private(set) var hasLockUnlockSwitchPointSetting = false

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

        case .SSM3_ITEM_CODE_SENSOR_DETECT_INTERVAL_SETTING:
            guard let intervalMs = int16Value(from: data) else {
                L.d("SesameOS3LockBase", "invalid sensor interval payload: \(data.count)")
                return
            }
            sensorDetectIntervalMs = intervalMs

        case .SSM3_ITEM_CODE_LOCK_UNLOCK_SWITCH_POINT_SETTING:
            guard let point = int16Value(from: data) else {
                L.d("SesameOS3LockBase", "invalid switch point payload: \(data.count)")
                return
            }
            updateLockUnlockSwitchPointSetting(point)

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

    func setSensorDetectInterval(intervalMs: Int16, result: @escaping (CHResult<CHEmpty>)) {
        if !isBleAvailable(result) { return }

        sendCommand(.init(.SSM3_ITEM_CODE_SENSOR_DETECT_INTERVAL_SETTING, intervalMs.littleEndian.data)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                self.sensorDetectIntervalMs = intervalMs
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }

    func setLockUnlockSwitchPoint(point: Int16, result: @escaping (CHResult<CHEmpty>)) {
        if !isBleAvailable(result) { return }

        sendCommand(.init(.SSM3_ITEM_CODE_LOCK_UNLOCK_SWITCH_POINT_SETTING, point.littleEndian.data)) { responsePayload in
            if responsePayload.cmdResultCode == .success {
                self.updateLockUnlockSwitchPointSetting(point)
                result(.success(CHResultStateBLE(input: CHEmpty())))
            } else {
                result(.failure(self.errorFromResultCode(responsePayload.cmdResultCode)))
            }
        }
    }

    private func updateLockUnlockSwitchPointSetting(_ point: Int16) {
        guard !hasLockUnlockSwitchPointSetting || lockUnlockSwitchPoint != point else { return }
        lockUnlockSwitchPoint = point
        hasLockUnlockSwitchPointSetting = true

        guard let device = self as? CHSesame5 else { return }
        (delegate as? CHSesame5Delegate)?.onLockUnlockSwitchPointReceive(device: device, point: point)
    }

    private func int16Value(from data: Data) -> Int16? {
        guard data.count >= 2 else { return nil }
        let rawValue = UInt16(data[data.startIndex]) |
            (UInt16(data[data.index(after: data.startIndex)]) << 8)
        return Int16(bitPattern: rawValue)
    }
}
