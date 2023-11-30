//
//  CHSesameBikeDevice.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/10/15.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import CoreBluetooth

final class CHSesameBikeDevice: CHBaseDevice, CHSesameBike, CHDeviceUtil {
    
    var mechSetting: CHSesameBikeMechSettings?
    var isConnectedByWM2 = false

    var cipher: Sesame2BleCipher?
    var fwVersion: UInt8?
    
    var advertisement: BleAdv? {
        didSet{
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
              let bikeLockSessionToken = bikeLockSessionToken else {
            return nil
        }

        let sessionToken = appRandomToken + bikeLockSessionToken
        let appPublicKey = appKeyPair.publicKey
        let signPayload = keyIndex + appPublicKey + sessionToken
        return signPayload.toHexString()
    }
    var bikeLockSessionToken: Data? {
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
    
    func goIOT() {}
}
