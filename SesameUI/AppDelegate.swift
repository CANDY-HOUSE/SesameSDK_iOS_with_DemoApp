//
//  AppDelegate.swift
//  sesame-sdk-test-app
//
//  Created by Cerberus on 2019/08/05.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import UserNotifications
import SesameSDK
import AWSCognitoIdentityProvider
import AWSMobileClient
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert,.badge,.sound], completionHandler: {
            granted,error in
        })
        
        UITextField.appearance().tintColor = .sesame2Green
        UINavigationBar.appearance().barTintColor = .sesame2DarkText
        UINavigationBar.appearance().tintColor = .sesame2DarkText
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.sesame2DarkText]

        window = UIWindow(frame: UIScreen.main.bounds)
        let applicationCoordinator = ApplicationCoordinator(window: window!)
        applicationCoordinator.start()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = WCSession.default
            WCSession.default.activate()
        }
        CHConfiguration.shared.setAPIKey("SNUrRpqs9P8fFQJfmX94e1if1XriRw7G3uLVMqkK")
        CHConfiguration.shared.setIdentityPoolId("ap-northeast-1:0a1820f1-dbb3-4bca-9227-2a92f6abf0ae")


        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UserDefaults.standard.setValue(deviceToken.toHexString(), forKey: "devicePushToken")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        L.d("error",error)
    }

    func applicationWillResignActive(_ application: UIApplication) {//退出
        CHBleManager.shared.disableScan(){res in}
        CHBleManager.shared.disConnectAll(){res in}
        if let enableHistoryStore = CHConfiguration.shared.getValueForKey("EnableHistoryStore") as? Bool,
            enableHistoryStore == true {
            Sesame2Store.shared.saveIfNeeded()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {//進入
        CHBleManager.shared.enableScan(){ res in

        }
    }

}

extension AppDelegate:UNUserNotificationCenterDelegate{

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let sessions = userInfo["aps"] as? [String: Any]{
            if  let action:String = sessions["action"] as? String {
                if action == "KEYCHAIN_FLUSH" {
                    L.d("我收到請求刷新")
                }
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound,.badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Determine the user action
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            L.d("Dismiss Action")
        case UNNotificationDefaultActionIdentifier:
            L.d("Default",response.notification.request)
        case "Snooze":
            L.d("Snooze")
        case "Delete":
            L.d("Delete")
        default:
            L.d("Unknown action")
        }
        completionHandler()
    }
}

extension WCSession: WCSessionDelegate {
    public func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    public func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
//        NotificationCenter.default.post(name: .WCSessioinDidReceiveMessage, object: message)
    }
}
