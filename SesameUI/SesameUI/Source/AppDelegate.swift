//
//  AppDelegate.swift
//  sesame-sdk-test-app
//  [Auto Unlock]
//  Created by Cerberus on 2019/08/05.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import UserNotifications
import SesameSDK
import AWSCognitoIdentityProvider
import WatchConnectivity
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private struct AutoUnlockRegionStatus {
        let leave: Bool
        let enter: Bool
    }
    
    var window: UIWindow?
    private let extensionListener = CHExtensionListener()
    private var autoUnlockRegionStatus = AutoUnlockRegionStatus(leave: false, enter: false)
    private var locationManager: CLLocationManager = CLLocationManager()
    private var autoUnlockDevices = [CHSesameLock]()
    private var autoUnlockTimer: Timer?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UserDefaults.standard.setValue(true, forKey: "refreshDevice")
        // 啟動通知
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert,.badge,.sound]) { _,_ in }
        UIApplication.shared.registerForRemoteNotifications()
        
        // 設定 UI style
        UITextField.appearance().tintColor = .sesame2Green // 全局的輸入匡光標顏色 |
        UINavigationBar.appearance().tintColor = UIColor.darkText //navagation 上所有圖標的顏色
        
        // active session 傳送資料到手錶
        WatchKitFileTransfer.shared.active()
        
        // 系統級通知 為了與 today extension, siri short cut 的互動
        extensionListener.registerObserver(self, withIdentifier: CHExtensionListener.widgetDidBecomeActive)
        extensionListener.registerObserver(self, withIdentifier: CHExtensionListener.widgetWillResignActive)
        extensionListener.registerObserver(self, withIdentifier: CHExtensionListener.shortcutDidBecomeActive)
        extensionListener.registerObserver(self, withIdentifier: CHExtensionListener.shortcutWillResignActive)
        
        // 設定 location manager
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = false
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        
        // 清除 auto unlock flag
        CHDeviceManager.shared.getCHDevices(result: {
            if case let .success(devices) = $0 {
                self.autoUnlockDevices = devices.data.compactMap({ device in device as? CHSesameLock }).filter({ $0.autoUnlockStatus() == true })
                for device in self.autoUnlockDevices { device.setAutoUnlockFlag(false) } // auto unlock 完清除 auto unlock flag
            }
        })
        // 設定顯示初始畫面
        let rootNavigationController = UINavigationController(rootViewController: GeneralTabViewController.instance())
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = rootNavigationController
        window!.makeKeyAndVisible()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        L.d("[noti][deviceToken:\(deviceToken.toHexString())]")
        UserDefaults.standard.setValue(deviceToken.toHexString(), forKey: "devicePushToken")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // [系統級通知] 通知 app 要進入背景
        CHExtensionListener.post(notification: CHExtensionListener.containingAppWillResignActive)
//        (iterateViewControllers() as? DFUAlertController)?.didEnterBackground()
        
        // 啟動 auto unlock
        CHDeviceManager.shared.getCHDevices(result: {
            if case let .success(devices) = $0 {
                self.autoUnlockDevices = devices.data.compactMap({ device in device as? CHSesameLock }).filter({ $0.autoUnlockStatus() == true })
                for device in self.autoUnlockDevices {
                    L.d("啟動自動解鎖，設備",device)
                    device.delegate = nil
                }
                if self.autoUnlockDevices.count > 0 {
                    // Start update user's location.
                    self.locationManager.delegate = self
                    self.locationManager.startUpdatingLocation()
                    self.startAutoUnlock()
                } else {
                    CHBluetoothCenter.shared.disableScan { _ in }
                    CHBluetoothCenter.shared.disConnectAll { _ in }
                }
            }
        })
    }
    
    // auto unlock, 每兩秒去嘗試開鎖
    func startAutoUnlock() {
        executeOnMainThread {
            self.autoUnlockTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true, block: { [unowned self] _ in
                for sesame2 in self.autoUnlockDevices.filter({ $0.autoUnlockFlag() == true }) {
                    // 在背景模式下掃描藍芽外圍設備不同於前景模式，會花更多時間掃描到設備，舉例 在背景模式下 CBCentralManagerScanOptionAllowDuplicatesKey 設定會失效 。
                    // 詳細參考以下網址搜尋關鍵字 The bluetooth-central Background Execution Mode
                    // https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html
//                    self.notification(body: sesame2.deviceStatus.description)
                    if sesame2.deviceStatus.loginStatus == .logined && sesame2.deviceStatus != .unlocked() {
                        (sesame2 as? CHSesame5)?.unlock(historytag: sesame2.hisTag) { unlockResult in }
                        (sesame2 as? CHSesame2)?.unlock { unlockResult in }
                        sesame2.setAutoUnlockFlag(false)
                    } else {
                        sesame2.connect { _ in }
                    }
                }
            })
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // [系統級通知] 通知 app 要回到前景
        CHBluetoothCenter.shared.enableScan { res in }
        CHExtensionListener.post(notification: CHExtensionListener.containingAppDidBecomeActive)
        Sesame2Store.shared.refreshDB() // 刷新 DB
        locationManager.stopUpdatingLocation()// 停止更新地理位置
        autoUnlockTimer?.invalidate() // 移除 auto unlock timer
        (iterateViewControllers() as? CHBaseViewController)?.didBecomeActive()  // 開啟藍芽掃描
    }
    
    /// 遍歷找到最上層 UI
    @discardableResult
    func iterateViewControllers(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController,
                           event: ((UIViewController)->Void)? = nil) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            event?(navigationController)
            return iterateViewControllers(controller: navigationController.visibleViewController, event: event)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                event?(selected)
                return iterateViewControllers(controller: selected, event: event)
            }
        }
        if let presented = controller?.presentedViewController {
            event?(presented)
            return iterateViewControllers(controller: presented, event: event)
        }
        if let controller = controller {
            event?(controller)
        }
        return controller
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
//     使用 BackgroundModes 的 remote notifications 功能時，在通知 aps 結構中有 "content-available" = 1 時會呼叫
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard application.applicationState == .background else { return }
        UserDefaults.standard.setValue(true, forKey: "refreshDevice")
        completionHandler(UIBackgroundFetchResult.newData)
    }

    /// 收到通知，決定是否顯示
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
//        L.d("[noti][willPresent]",userInfo)
        if let event = userInfo["event"] as? String {
//            L.d("[noti][willPresent] event:",event)
            if (event == "friend"){
                if let navController = GeneralTabViewController.switchTabByIndex(1) as? UINavigationController, let listViewController = navController.viewControllers.first as? FriendListViewController {
                    listViewController.getFriends()
                }
                completionHandler([])
                return
            }
            
            if (event == "device"){
                if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
//                    L.d("[noti][willPresent] getKeysFromServer!!!:",event)
                    listViewController.getKeysFromServer()
                    for controller in navController.viewControllers {
                        if let refController = controller as?  Sesame2SettingViewController {
                            refController.reloadFriends()
                        } else if let refController = controller as? Sesame5SettingViewController {
                            refController.reloadFriends()
                        } else if let refController = controller as? BikeLockSettingViewController {
                            refController.reloadFriends()
                        } else if let refController = controller as? BikeLock2SettingViewController {
                            refController.reloadFriends()
                        } else if let refController = controller as? Bot2SettingViewController {
                            refController.reloadFriends()
                        } else if let refController = controller as? SesameBiometricDeviceSettingVC {
                            refController.reloadFriends()
                        }
                    }
                }
                completionHandler([])
                return
            }
        }

        if let deviceId = userInfo["deviceId"] as? String {
//            L.d("[noti][willPresent]",deviceId)
            CHDeviceManager.shared.getCHDevices { getResult in
                if case let .success(devices) = getResult {
                    if devices.data.filter({ $0.deviceId.uuidString == deviceId }).count == 0 {
                        let token = UserDefaults.standard.string(forKey: "devicePushToken")!
                        CHDeviceManager.shared.disableNotification(deviceId: deviceId, token: token, name: "Sesame2") { _ in }
                        completionHandler([])
                        return
                    }
                }
            }
        }
        
        shouldShowFullNotification(userInfo: userInfo) { shouldShow in
            if shouldShow {
                completionHandler([.alert, .sound, .badge])
            } else {
                completionHandler([])
            }
        }
    }
    
    private func shouldShowFullNotification(userInfo: [AnyHashable: Any], completion: @escaping (Bool) -> Void) {
        var shouldShowFull = true
        
        if let triggerUserSubObject = userInfo["triggerUserSub"] as? [String: Any],
           let triggerUserSub = triggerUserSubObject["data"] as? [UInt8] {
            if triggerUserSub.count == 0 {
                completion(true)
                return
            }
            let triggerUserSubHex = triggerUserSub.toHexString()
            let group = DispatchGroup()
            group.enter()
            
            CHUserAPIManager.shared.getSubId { subId in
                defer { group.leave() }
                if let subId = subId {
                    let cleanSubId = subId.replacingOccurrences(of: "-", with: "")
                    if triggerUserSubHex == cleanSubId {
                        shouldShowFull = false
                    }
                }
            }
            _ = group.wait(timeout: .now() + 1.0)
            completion(shouldShowFull)
            return
        }
        completion(true)
    }
}

extension AppDelegate: CHExtensionListenerDelegate {
    /// [系統級別通知]
    func receiveExtensionNotification(_ notificationIdentifier: String) {
        /// Today extension 或 Siri short cut 開始
        if notificationIdentifier == CHExtensionListener.widgetDidBecomeActive || notificationIdentifier == CHExtensionListener.shortcutDidBecomeActive {
            switch UIApplication.shared.applicationState {
            case .active:
                break
            case .inactive, .background:
                autoUnlockTimer?.invalidate()
                CHBluetoothCenter.shared.disableScan { _ in }
                CHBluetoothCenter.shared.disConnectAll { _ in }
            @unknown default:
                break
            }
        }
        
        /// Today extension 或 Siri short cut 結束工作
        if notificationIdentifier == CHExtensionListener.widgetWillResignActive ||
                    notificationIdentifier == CHExtensionListener.shortcutWillResignActive {
            switch UIApplication.shared.applicationState {
            case .active:
                break
            case .background:
                Sesame2Store.shared.refreshDB()
                CHBluetoothCenter.shared.enableScan { _ in }
                startAutoUnlock()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    /// 用戶地理位置更新，決定顯示出圈入圈的通知
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // No sesame was set as auto-unlock or sesame is connected
        if self.autoUnlockDevices.count == 0 || self.autoUnlockDevices.filter({ $0.deviceStatus.loginStatus == .logined }).count > 0 {
            return
        }
        let regionsContainsLocation = autoUnlockDevices.filter({ $0.region()?.contains(locations.last!.coordinate) == true })
        // 出圈: 開啟 auto unlock flag
        if regionsContainsLocation.count == 0 && autoUnlockRegionStatus.leave == false {
            autoUnlockRegionStatus = AutoUnlockRegionStatus(leave: true, enter: false)
            notification(body: "co.candyhouse.sesame2.exitAutoUnlockRegion".localized)
            for autoUnlockDevice in autoUnlockDevices { autoUnlockDevice.setAutoUnlockFlag(true) }
        }
        // 入圈
        if regionsContainsLocation.count > 0 && autoUnlockRegionStatus.leave == true && autoUnlockRegionStatus.enter == false {
            autoUnlockRegionStatus = AutoUnlockRegionStatus(leave: false, enter: true)
            notification(body: "co.candyhouse.sesame2.enterAutoUnlockRegion".localized)
        }
    }
}

extension AppDelegate {
    func notification(body: String) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = ""
        content.body = body
        content.categoryIdentifier = "alarm"
        content.userInfo = ["customData": "fizzbuzz"]
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: trigger)
        center.add(request)
    }
}

extension AppDelegate {
    
    /// 用戶掃了鑰匙 qr-code
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        parserQRCodeURL(url)
        return UIApplication.shared.canOpenURL(url)
    }
    
    /// 用戶掃了鑰匙 qr-code
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            parserQRCodeURL(userActivity.webpageURL!)
        }
        return true
    }
    
    func parserQRCodeURL(_ url: URL) {
        
        guard url.scheme! + "://" + url.host! == URL.sesameURLSchemePrefix
        else { return }
        
        QRCodeScanViewController.parseSesameQRCode(url.absoluteString) { parseResult in
            executeOnMainThread {
                if case let .success(qrCodeType) = parseResult {
                    switch qrCodeType {
                    case .sesameKey:
                        if let navController = GeneralTabViewController.switchTabByIndex(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
                            listViewController.getKeysFromCache()
                        }
                    case .friend:
                        if let nav = GeneralTabViewController.switchTabByIndex(1) as? UINavigationController,
                           let friendViewController = nav.viewControllers.first as? FriendListViewController {
                            friendViewController.getFriends()
                        }
                    case .matter: break
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
