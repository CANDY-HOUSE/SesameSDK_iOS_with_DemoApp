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
    var extensionListener = CHExtensionListener()

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
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        CHConfiguration.shared.setAPIKey("SNUrRpqs9P8fFQJfmX94e1if1XriRw7G3uLVMqkK")
        CHConfiguration.shared.setIdentityPoolId("ap-northeast-1:0a1820f1-dbb3-4bca-9227-2a92f6abf0ae")
        BackgroundLockManager.activeIfNeeded()
        
        extensionListener.registerObserver(self, withIdentifier: CHExtensionListener.widgetDidBecomeActive)
        extensionListener.registerObserver(self, withIdentifier: CHExtensionListener.widgetWillResignActive)
        
        makeWindowVisible()
        
        return true
    }
    
    func makeWindowVisible() {
        let rootNavigationController = UINavigationController()
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        rootNavigationController.pushViewController(GeneralTabViewController.instance(), animated: false)
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = rootNavigationController
        window!.makeKeyAndVisible()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UserDefaults.standard.setValue(deviceToken.toHexString(), forKey: "devicePushToken")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        L.d("error",error)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        CHExtensionListener.post(notification: CHExtensionListener.containingAppWillResignActive)
        
        CHBleManager.shared.disableScan() { res in
            BackgroundLockManager.didEnterBackground()
        }
        CHBleManager.shared.disConnectAll(){res in}
        
        iterateViewControllers { viewController in
            (viewController as? CHBaseViewController)?.didEnterBackground()
            (viewController as? DFUAlertController)?.didEnterBackground()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        CHExtensionListener.post(notification: CHExtensionListener.containingAppDidBecomeActive)
        
        BackgroundLockManager.didBecomeActive()
        
        CHBleManager.shared.enableScan(){ res in

        }
        iterateViewControllers { viewController in
            (viewController as? CHBaseViewController)?.didBecomeActive()
        }
    }
    
    @discardableResult
    func iterateViewControllers(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController,
                           event: (UIViewController)->Void) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            event(navigationController)
            return iterateViewControllers(controller: navigationController.visibleViewController, event: event)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                event(selected)
                return iterateViewControllers(controller: selected, event: event)
            }
        }
        if let presented = controller?.presentedViewController {
            event(presented)
            return iterateViewControllers(controller: presented, event: event)
        }
        if let controller = controller {
            event(controller)
        }
        return controller
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return true
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

extension AppDelegate: CHExtensionListenerDelegate {
    func receiveNotification(_ notificationIdentifier: String) {
        if notificationIdentifier == CHExtensionListener.widgetDidBecomeActive {

            switch UIApplication.shared.applicationState {
            case .active:
                break
            case .inactive, .background:
                CHBleManager.shared.disableScan { _ in
                    
                }
                CHBleManager.shared.disConnectAll { _ in
                    
                }
            @unknown default:
                break
            }
        } else if notificationIdentifier == CHExtensionListener.widgetWillResignActive {
            switch UIApplication.shared.applicationState {
            case .active:
                break
            case .background:
                applicationDidEnterBackground(UIApplication.shared)
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}

extension AppDelegate: WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
        L.d("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        L.d("sessionDidDeactivate")
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        L.d("activationDidCompleteWith", error)
    }
}
