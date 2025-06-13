//
//  CHSesameLock+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/08/11.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import SesameSDK

extension CHSesameLock {
    /// [Toggle] 移除 Siri voice short cut
    func removeVoiceToggle() {
        Sesame2Store.shared.removeAttribute("voiceShortcutId", for: self)
    }
    
    /// [Toggle] 設定 Siri voice short cut
    func setVoiceToggle(_ id: UUID) {
        Sesame2Store.shared.saveAttributes(["voiceShortcutId": id], for: self)
    }
    
    /// [Toggle] 是否設定 Siri voice short cut
    func getVoiceToggleId() -> UUID? {
        if let device = Sesame2Store.shared.propertyFor(self) {
            return device.voiceShortcutId
        } else {
            return nil
        }
    }
    
    /// [Lock] 移除 Siri voice short cut
    func removeVoiceLock() {
        Sesame2Store.shared.removeAttribute("voiceLockId", for: self)
    }
    
    /// [Lock] 設定 Siri voice short cut
    func setVoiceLock(_ id: UUID) {
        Sesame2Store.shared.saveAttributes(["voiceLockId": id], for: self)
    }
    
    /// [Lock] 是否設定 Siri voice short cut
    func getVoiceLockId() -> UUID? {
        if let device = Sesame2Store.shared.propertyFor(self) {
            return device.voiceLockId
        } else {
            return nil
        }
    }
    
    /// [Unlock] 移除 Siri voice short cut
    func removeVoiceUnlock() {
        Sesame2Store.shared.removeAttribute("voiceUnlockId", for: self)
    }
    
    /// [Unlock] 設定 Siri voice short cut
    func setVoiceUnlock(_ id: UUID) {
        Sesame2Store.shared.saveAttributes(["voiceUnlockId": id], for: self)
    }
    
    /// [Unlock] 是否設定 Siri voice short cut
    func getVoiceUnlockId() -> UUID? {
        if let device = Sesame2Store.shared.propertyFor(self) {
            return device.voiceUnlockId
        } else {
            return nil
        }
    }
}
