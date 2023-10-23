# AppDelegate

初始化全局的設定、配置

## App 生命週期

### UIApplicationDelegate

1.application didFinishLaunchingWithOptions
App 程式啟動後被呼叫。設定基本初始化工作:

- 註冊推送通知 `UIApplication.shared.registerForRemoteNotifications()`
  推送通知使用 AWS sns 服務:
  https://ap-northeast-1.console.aws.amazon.com/sns/v3/home?region=ap-northeast-1#/mobile/push-notifications
- 設定全局 UI
- 設定 API key, client id, app group
- 註冊監聽 Today Widget && Short cut
- 自動解鎖後清除自動解鎖的 flag
- App 初始畫面:`GeneralTabViewController.instance()`

```Swift
    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool{

        }
```

2.applicationDidEnterBackground

```Swift
func applicationDidEnterBackground(_ application: UIApplication) {
    // 處理自動解鎖功能的啟動
}
```

3.applicationDidBecomeActive

- 停止更新地理位置`locationManager.stopUpdatingLocation()`
- 找到`CHBaseViewController` 時使其進入 `didBecomeActive()` 開啟藍芽掃描
- 啟動藍芽掃描`CHBluetoothCenter.shared.enableScan { res in }`
- 清除任何現有的緩存，然後從持久性存儲中刷新所有的物件

```swift
func applicationDidBecomeActive(_ application: UIApplication){
    //
}
```

## CHExtensionListener

- 註冊 4 個通知:
  `widgetDidBecomeActive`, `widgetWillResignActive`, `shortcutDidBecomeActive`, `shortcutWillResignActive`
  這四個事件被觸發時，AppDelegate 會收到通知。

- 發送通知:在 App 生命週期 `applicationDidEnterBackground` 和 `applicationDidBecomeActive` 方法中，使用 CHExtensionListener.post 通知所有註冊了相應事件的 Observer
