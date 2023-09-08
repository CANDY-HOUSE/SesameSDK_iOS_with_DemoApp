//
//  SesameBot+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/08/11.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import SesameSDK

extension CHSesameBot {
    /// 當前 bot 模式
    var sesameBotMode: SesameBotClickMode? {
        SesameBotClickMode.modeForSesameBot(self)
    }
}

