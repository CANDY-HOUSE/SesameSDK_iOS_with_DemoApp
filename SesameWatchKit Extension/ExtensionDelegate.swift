//
//  ExtensionDelegate.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/7/1.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import WatchKit
import WatchConnectivity
import SesameWatchKitSDK

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    override init() {
        if WCSession.isSupported() {
            WCSession.default.delegate = WCSession.default
            WCSession.default.activate()
        }
    }

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NotificationCenter.default.post(name: Notification.Name.ApplicationDidBecomeActive, object: nil)
    }

//    func applicationWillResignActive() {
//        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
//        // Use this method to pause ongoing tasks, disable timers, etc.
//        NotificationCenter.default.post(name: Notification.Name.ApplicationWillResignActive, object: nil)
//    }
    
    func applicationDidEnterBackground() {
        NotificationCenter.default.post(name: Notification.Name.ApplicationDidEnterBackground, object: nil)
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}

extension WCSession: WCSessionDelegate {
    public func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
    }
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        WatchKitFileTransfer.receiveUserInfoFromIPhone(userInfo)
    }
}

class SessionDataManager {
    static let shared = SessionDataManager()
    var dbURL: URL? {
        didSet {
            guard let url = dbURL else {
                return
            }
            NotificationCenter.default.post(name: .SessionDataManagerDidReceiveFile, object: nil, userInfo: ["dbURL": url])
        }
    }
    
    func sendMessageToiPhone(_ message: [String: Any]) {
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
}
