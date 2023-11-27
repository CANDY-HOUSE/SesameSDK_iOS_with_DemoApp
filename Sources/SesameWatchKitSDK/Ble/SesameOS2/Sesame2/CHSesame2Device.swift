//
//  Sesame2BleDevice.swift
//  sesame2-sdk
//
//  Created by tse on 2023/5/11.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import CoreBluetooth

class CHSesame2Device: CHBaseDevice, CHSesame2, CHDeviceUtil {

    var isConnectedByWM2 = false

    func getToken() -> String? {
        guard let keyIndex = sesame2KeyData?.keyIndex.hexStringtoData(),
              let sesame2SessionToken = sesame2SessionToken else {
            return nil
        }

        let sessionToken = appRandomToken + sesame2SessionToken
        let appPublicKey = appKeyPair.publicKey
//        L.d("appPublicKey",appKeyPair.publicKey.toHexString())
        let signPayload = keyIndex + appPublicKey + sessionToken
        return signPayload.toHexString()
    }
    var sesame2SessionToken: Data? {
        didSet {
            if self.isRegistered {
                if isGuestKey {
                    sign(token: getToken()!) { signResult in
                        if case let .success(signedToken) = signResult {
                            L.d("[ss4][ans]",signedToken.data)
                            self.login(token: signedToken.data)
                        }
                    }
                } else if deviceStatus == .waitingGatt() {
                    login()
                }
            } else {
                deviceStatus = .readyToRegister()
                sesame2KeyData = nil
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
        }
    }
    
    var cipher: Sesame2BleCipher?

    var mechSetting: CHSesame2MechSettings?

    func goIOT() {}
    var appRandomToken = Data.generateRandomData(count: 4)
    var fwVersion: UInt8?
}
