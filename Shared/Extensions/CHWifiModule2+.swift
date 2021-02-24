//
//  CHWifiModule2+.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
import SesameSDK
#elseif os(watchOS)
import WatchKit
import SesameWatchKitSDK
#endif

extension CHWifiModule2 {
    public func localizedDescription() -> String {
        switch deviceStatus {
        case .reset:
            return "co.candyhouse.sesame2.reset".localized
        case .noBleSignal:
            return "co.candyhouse.sesame2.noBleSignal".localized
        case .receivedBle:
            return "co.candyhouse.sesame2.receivedBle".localized
        case .bleConnecting:
            return "co.candyhouse.sesame2.bleConnecting".localized
        case .waitingGatt:
            return "co.candyhouse.sesame2.waitingGatt".localized
        case .bleLogining:
            return "co.candyhouse.sesame2.bleLogining".localized
        case .readyToRegister:
            return "co.candyhouse.sesame2.readyToRegister".localized
        case .registering:
            return "co.candyhouse.sesame2.registering".localized
        case .waitApConnect:
            return "co.candyhouse.sesame2.waitApConnect".localized
        case .iotConnected:
            return "co.candyhouse.sesame2.iotConnected".localized
        case .iotDisconnected:
            return "co.candyhouse.sesame2.iotDisconnected".localized
        case .busy:
            return "co.candyhouse.sesame2.busy".localized
        @unknown default:
            return "unknown"
        }
    }
}
