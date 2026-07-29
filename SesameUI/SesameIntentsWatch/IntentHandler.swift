//
//  IntentHandler.swift
//  SesameIntentsWatch
//
//  Created by YuHan Hsiao on 2021/09/24.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import Intents
import SesameSDK

class IntentHandler: INExtension {

    override func handler(for intent: INIntent) -> Any {
        Sesame2Store.shared.refreshDB()
        CHExtensionListener.post(notification: CHExtensionListener.shortcutDidBecomeActive)
        if let _ = intent as? UnlockSesameIntent {
            return UnlockSesameIntentHandler()
        } else if let _ = intent as? LockSesameIntent {
            return LockSesameIntentHandler()
        } else {
            return ToggleSesameIntentHandler()
        }
    }

}
