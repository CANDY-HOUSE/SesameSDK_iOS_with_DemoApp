//
//  CHExtensionListener.swift
//  SesameSDK
//
//  Created by Wayne Hsiao on 2020/9/23.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

public protocol CHExtensionListenerDelegate: AnyObject {
    func receiveExtensionNotification(_ notificationIdentifier: String)
}

final public class CHExtensionListener {
    public static let containingAppDidBecomeActive = "containingAppDidBecomeActive"
    public static let containingAppWillResignActive = "containingAppWillResignActive"
    public static let widgetDidBecomeActive = "widgetDidBecomeActive"
    public static let widgetWillResignActive = "widgetWillResignActive"
    public static let shortcutDidBecomeActive = "shortcutDidBecomeActive"
    public static let shortcutWillResignActive = "shortcutWillResignActive"

    private let center = CFNotificationCenterGetDarwinNotifyCenter()

    private var observers = NSMapTable<NSString, AnyObject>(keyOptions: .copyIn,
                                                            valueOptions: .weakMemory)

    public init() {

    }

    public func registerObserver<P>(_ listener: P, withIdentifier identifier: String) where P: CHExtensionListenerDelegate {
        let notificationName = CHExtensionListener.generateNotificationIdentifier(identifier) as CFString
        observers.setObject(listener, forKey: CHExtensionListener.generateNotificationIdentifier(identifier) as NSString)
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterAddObserver(center, Unmanaged.passUnretained(self).toOpaque(), { (center, observer, name, object, userInfo) in
            if let observer = observer, let name = name {
                let unmanagedSelf = Unmanaged<CHExtensionListener>.fromOpaque(observer).takeUnretainedValue()
                
                let originIdentifier = (name.rawValue as String).replacingOccurrences(of: "co.candyhouse.SesameSDK.",
                                                                             with: "",
                                                                             options: NSString.CompareOptions.literal, range: nil)

                if let listener = unmanagedSelf.observers.object(forKey: name.rawValue as NSString) as? CHExtensionListenerDelegate {
                    listener.receiveExtensionNotification(originIdentifier as String)
                }
            }
        }, notificationName, nil, .deliverImmediately)
    }

    public func unregisterIdentifier(_ identifier: String) {
        let notificationName = CHExtensionListener.generateNotificationIdentifier(identifier) as CFString
        CFNotificationCenterRemoveObserver(center, Unmanaged.passUnretained(self).toOpaque(), CFNotificationName(rawValue: notificationName), nil)
    }

    public func unregisterAll() {
        CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
    }

    public static func post(notification: String) {
        let notificationIdentifier = CHExtensionListener.generateNotificationIdentifier(notification) as CFString
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName(rawValue: notificationIdentifier), nil, nil, true)
    }

    private static func generateNotificationIdentifier(_ originIdentifier: String) -> String {
        "co.candyhouse.SesameSDK.\(originIdentifier)"
    }
}
