//
//  NotificationService.swift
//  SesameNotificationServiceExtension
//
//  Created by YuHan Hsiao on 2021/01/18.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import UserNotifications
import CoreFoundation
import SesameSDK

class NotificationService: UNNotificationServiceExtension {
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        let bestAttemptContent: UNMutableNotificationContent = (request.content.mutableCopy() as! UNMutableNotificationContent)

        L.d("[noti][didReceive][UNNotificationServiceExtension]",request.content.userInfo)

        Sesame2Store.shared.refreshDB()
        if let deviceId = request.content.userInfo["deviceId"] as? String,
           let event = request.content.userInfo["event"] as? String {
            let localizedEvent = "co.candyhouse.sesame2.history\(event)".localized
            let deviceName = Sesame2Store.shared.getPropertyById(deviceId)?.name ?? deviceId
            L.d("[noti][didReceive][UNNotificationServiceExtension]",deviceName)

            if let historyTagDic = request.content.userInfo["historyTag"] as? [String: Any],
               let historyTag = historyTagDic["data"] as? [UInt8] {
                let historyTag = String(decoding: historyTag, as: UTF8.self)
                bestAttemptContent.title = "\(deviceName) \(localizedEvent), \(historyTag)"
            } else {
                bestAttemptContent.title = "\(deviceName) \(localizedEvent)"
            }
            contentHandler(bestAttemptContent)
        } else {
            contentHandler(bestAttemptContent)
        }
    }
}
