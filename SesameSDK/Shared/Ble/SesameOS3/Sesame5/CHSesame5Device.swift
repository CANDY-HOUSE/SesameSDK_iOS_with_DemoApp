//
//  CHSesame5Device.swift
//  SesameSDK
//  Created by tse on 2023/3/9.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

class CHSesame5Device: CHSesameOS3, CHDeviceUtil ,CHSesame5 {
    
    var mechSetting: CHSesame5MechSettings?
    var opsSetting: CHSesame5OpsSettings?
    var isConnectedByWM2 = false

    public var isHistory: Bool = false { // isHistory:現在還有沒有歷史要讀的flag
        didSet {
            if oldValue != isHistory ,isHistory{
//                L.d("[ss5][history] isHistory", oldValue,"->",isHistory)
                self.readHistoryCommand(){_ in}
            }
        }
    }

    var advertisement: BleAdv? {
        didSet{
            guard let advertisement = advertisement  else {
                deviceStatus = .noBleSignal()
                return
            }
            setAdv(advertisement)
            if (self.deviceStatus.loginStatus == .logined ) {
                isHistory = advertisement.adv_tag_b1
            }
        }
    }

    override func onGattSesamePublish(_ payload: SesameOS3PublishPayload) {
        super.onGattSesamePublish(payload)
        let itemCode = payload.itemCode
        let data = payload.payload
        switch itemCode {
            case .mechStatus:
                mechStatus = Sesame5MechStatus.fromData(data)!
                self.readHistoryCommand(){_ in}
                self.deviceStatus = mechStatus!.isInLockRange  ? .locked() :.unlocked()
            case .mechSetting:
                mechSetting = CHSesame5MechSettings.fromData(data)!
            case .OPS_CONTROL:
                opsSetting = CHSesame5OpsSettings.fromData(data)!
        default:
            L.d("!![ss5][pub][\(itemCode.rawValue)]")
        }
    }
}

struct Sesame5MechStatus: CHSesameProtocolMechStatus {
    let battery: UInt16
    let target: Int16
    let position: Int16
    let flags: UInt8
    var data: Data {battery.data + target.data + position.data  + flags.data}
    var isClutchFailed: Bool { return flags & 1 > 0 }
    var isInLockRange: Bool { return flags & 2 > 0 }
    var isInUnlockRange: Bool { return flags & 4 > 0 }
    var isStop: Bool? { return flags & 16 > 0 }
    var isBatteryCritical: Bool { return flags & 32 > 0 }

//    public func getBatteryPrecentage() -> Int { 有必要可以自己複寫電量。這裡是範例
//        return 0
//    }

    public func getBatteryVoltage() -> Float {
        return Float(battery) * 2 / 1000
    }

    static func fromData(_ buf: Data) -> Sesame5MechStatus? {
        return  buf.withUnsafeBytes({ $0.load(as: self) })
    }
}
