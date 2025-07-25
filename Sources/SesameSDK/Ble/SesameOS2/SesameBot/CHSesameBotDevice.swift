//
//  CHSwitchDevice.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import CoreBluetooth

final class CHSesameBotDevice: CHBaseDevice, CHSesameBot, CHDeviceUtil {

    var isConnectedByWM2 = false

    var fwVersion: UInt8?
    var mechSetting: CHSesameBotMechSettings?
    var cipher: Sesame2BleCipher?
    
    var advertisement: BleAdv? {
        didSet {
            guard let advertisement = advertisement  else {
                deviceStatus = .noBleSignal()
                return
            }
            setAdv(advertisement)
        }
    }

    var appRandomToken = Data.generateRandomData(count: 4)
    func getToken() -> String? {
        guard let keyIndex = sesame2KeyData?.keyIndex.hexStringtoData(),
              let sesameBotSessionToken = sesameBotSessionToken else {
            return ""
        }

        let sessionToken = appRandomToken + sesameBotSessionToken
        let appPublicKey = appKeyPair.publicKey
        let signPayload = keyIndex + appPublicKey + sessionToken
        return signPayload.toHexString()
    }
    var sesameBotSessionToken: Data? {
        didSet{
            if self.isRegistered {
                if isGuestKey {
                    sign(token: getToken()!) { signResult in
                        if case let .success(signedToken) = signResult {
                            self.login(token: signedToken.data)
                        }
                    }
                } else if deviceStatus == .waitingGatt() {
                    login()
                }
            } else {
                self.deviceStatus = .readyToRegister()
                self.sesame2KeyData = nil
            }
        }
    }
    
    
    func goIOT() {
        #if os(iOS)
        CHIoTManager.shared.subscribeCHDeviceShadow(self) { [self] result in
            switch result {
            case .success(let content):

                if let wm2s = content.data.wifiModule2s {
                    if let wm2 = wm2s.filter({ $0.isConnected == true }).first {
                        isConnectedByWM2 = wm2.isConnected
                    } 
                }
                if let mechStatusData = content.data.mechStatus?.hexStringtoData(),
                   let mechStatus = SesameBotMechStatus.fromData(mechStatusData) {
                    if isConnectedByWM2 {
                        self.deviceShadowStatus = mechStatus.isInLockRange ? .locked() : mechStatus.isInUnlockRange ? .unlocked() : .moved()
                    }else{
                        self.deviceShadowStatus = nil
                    }

                    if !self.isBleAvailable() {
                        self.mechStatus = mechStatus
                    }
                }

                self.delegate?.onBleDeviceStatusChanged(device: self, status: self.deviceStatus,shadowStatus: self.deviceShadowStatus)

            case .failure(let error):
                L.d(error)
            }
        }
        #endif
    }

    deinit {
        #if os(iOS)
        CHIoTManager.shared.unsubscribeCHDeviceShadow(self)
        #endif
    }
}
