//
//  IntentHandler.swift
//  SesameIntents
//
//  Created by Wayne Hsiao on 2020/9/9.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Intents

class IntentHandler: INExtension {

    override func handler(for intent: INIntent) -> Any {
        if let _ = intent as? OpenSesame2Intent {
            return OpenSesame2IntentHandler()
        } else if let _ = intent as? LockSesame2Intent {
            return LockSesame2IntentHandler()
        } else {
            return ToggleSesame2IntentHandler()
        }
    }

}
