//
//  AppDelegate.swift
//  sesame-sdk-test-app
//
//  Created by Cerberus on 2019/08/05.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import UIKit
import UserNotifications
import SesameSDK
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var extensionListener = CHExtensionListener()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UITextField.appearance().tintColor = .sesame2Green
        UINavigationBar.appearance().barTintColor = .sesame2DarkText
        UINavigationBar.appearance().tintColor = .sesame2DarkText
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.sesame2DarkText]
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        
        extensionListener.registerObserver(self, withIdentifier: CHExtensionListener.widgetDidBecomeActive)
        extensionListener.registerObserver(self, withIdentifier: CHExtensionListener.widgetWillResignActive)
        
        let rootNavigationController = UINavigationController()
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        rootNavigationController.pushViewController(GeneralTabViewController.instance(), animated: false)
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = rootNavigationController
        window!.makeKeyAndVisible()
        
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UserDefaults.standard.setValue(deviceToken.toHexString(), forKey: "devicePushToken")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        CHExtensionListener.post(notification: CHExtensionListener.containingAppWillResignActive)
        iterateViewControllers { viewController in
            (viewController as? CHBaseViewController)?.didEnterBackground()
            (viewController as? DFUAlertController)?.didEnterBackground()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        CHExtensionListener.post(notification: CHExtensionListener.containingAppDidBecomeActive)
        CHBleManager.shared.enableScan() { res in }
        let topViewController = iterateViewControllers { viewController in
        }
        if let chBaseViewController = topViewController as? CHBaseViewController {
            chBaseViewController.didBecomeActive()
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
    
    func applicationWillTerminate(_ application: UIApplication) {
//        notification(body: "App been terminated")
    }
}

extension AppDelegate: CHExtensionListenerDelegate {
    func receiveExtensionNotification(_ notificationIdentifier: String) {
        if notificationIdentifier == CHExtensionListener.widgetDidBecomeActive || notificationIdentifier == CHExtensionListener.shortcutDidBecomeActive {
            switch UIApplication.shared.applicationState {
            case .active:
                break
            case .inactive, .background:
                CHBleManager.shared.disableScan { _ in }
                CHBleManager.shared.disConnectAll { _ in }
            @unknown default:
                break
            }
        } else if notificationIdentifier == CHExtensionListener.widgetWillResignActive ||
                    notificationIdentifier == CHExtensionListener.shortcutWillResignActive {
            switch UIApplication.shared.applicationState {
            case .active:
                break
            case .background:
                Sesame2Store.shared.refreshDB()
                CHBleManager.shared.enableScan { _ in }
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}

extension AppDelegate: WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) { }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
}

extension AppDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        parserQRCodeURL(url.absoluteString)
        return UIApplication.shared.canOpenURL(url)
    }
    
    func parserQRCodeURL(_ url: String) {
        QRCodeScanViewController.parseSesameQRCode(url) { parseResult in
            executeOnMainThread {
                if case let .success(qrCodeType) = parseResult {
                    switch qrCodeType {
                    case .sk:
                        if let navController = GeneralTabViewController.switchTabByIndex(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
                            listViewController.getKeysFromCache()
                        }
                    case .friend:
                        break
                    }
                } else if case let .failure(error) = parseResult {
                    executeOnMainThread {
                        // https://stackoverflow.com/a/60393872/4276890
                        if (error as NSError).code == -1005 {
                            self.parserQRCodeURL(url)
                        }
                    }
                }
            }
        }
    }
}
