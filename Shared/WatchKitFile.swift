//
//  WatchKitFile.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/12/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
#if os(iOS)
import SesameSDK
#else
import SesameWatchKitSDK
#endif

struct WatchKitFile: Codable {
    let deviceId: String
    let key: String
    let name: String
    let historyTag: String
}
