<img src="https://img.shields.io/badge/Bluetooth-4.0LE-0082FC" /> <img src="https://img.shields.io/badge/iOS-11-000000" /> <img src="https://img.shields.io/badge/Android-5.0-3DDC84" /> <img src="https://img.shields.io/badge/Xcode-11.7-1575F9" /> <img src="https://img.shields.io/badge/Android Studio-4.0.1-3DDC84" /> <img src="https://img.shields.io/badge/Swift-5.2.4-FA7343" /> <img src="https://img.shields.io/badge/Kotlin-1.3-0095D5" />
<!-- https://simpleicons.org/ -->
<p align="center" >
  <img src="https://raw.github.com/CANDY-HOUSE/SesameSDK_iOS_with_DemoApp/assets/SesameSDK_Swift.png" alt="CANDY HOUSE Sesame SDK" title="SesameSDK">
</p>

# ご挨拶
SesameSDK は簡単かつパワフルかつ無料な、iOS/Androidアプリ用の Bluetooth/IoT(Internet of Things)ライブラリ です。公式 セサミアプリ もこの SesameSDK を用いて構築されており、この SesameSDK にて、あなたのアプリでもセサミアプリが有する**全て**の機能を持たせることが可能です。すなわちあなたのアプリにて以下のことが可能です。  

- セサミデバイスの登録
- 施錠
- 解錠
- 鍵のシェア
- 履歴の取得
- セサミデバイスのファームウェアのアップデートする
- セサミデバイスの各種の設定
- 電池残量の取得
- iOS/iPadOS Widget 対応
- Apple Watch app 対応  

この SesameSDK は現時点では、Sesame2 シリーズ のみ対応しております。また今後リリース予定の SesameOS2 にアップデートした Sesame1 でも対応予定です。  

### Requirements

| Minimum Targets | Minimum Bluetooth Target | Minimum IDE |
|:------------------:|:------------------------:|:-----------:|
| iOS 11 <br> iPadOS 13.1 | Bluetooth 4.0 LE | Xcode 11.7 | 
| Android 5.0 | Bluetooth 4.0 LE | Android Studio 4.0.1 | 

### Essential dependencies
- iOS
  - SesameSDK.framework
  - AWSAPIGateway.framework 
- Android
  - SesameSDK.aar

# 1. SesameSDK を取り入れる
- SesameSDKプロジェクトをダウンロードし、その中のiOS/Android Demo app で遊んでみてください。 または
[Apple TestFlight](https://testflight.apple.com/join/mK4OadTW) / 
[Google Drive](https://drive.google.com/file/d/15aRQl6aWBVwJSE4l3ZL-eMisPoe-f2lW/view?usp=sharing)
からも Demo app をダウンロードできます。  
- <ins>SesameSDK.framework</ins> と <ins>AWSAPIGateway.framework</ins> をあなたのアプリプロジェクトにドラッグ＆ドロップしてください。  
- Demo app から <ins>API Key</ins> と <ins>Identity Pool ID</ins> をコピーして、あなたのアプリプロジェクトの`AppDelegate`の`didFinishLaunchingWithOptions`の中にペーストすると、セサミデバイスの登録と履歴へのアクセスが可能になります。  
```swift
import SesameSDK

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
...
    CHConfiguration.shared.setAPIKey("API_KEY")
    CHConfiguration.shared.setIdentityPoolId("IDENTITY_POOL_ID")
...
}
```

# 2. セサミデバイスを登録する
<p align="center" >
  <img src="https://raw.github.com/CANDY-HOUSE/SesameSDK_iOS_with_DemoApp/assets/RegisterSesameDevice.png" alt="CANDY HOUSE Sesame SDK" title="SesameSDK">
</p>

### 2.1 まず、BLEスキャンを行う
```Swift
CHBleManager.shared.enableScan()  // 近くにあるセサミデバイスのadvertisingパケットをスキャンする。
```
```Swift
CHBleManager.shared.disableScan() // アプリをバックグラウンドに置いた時に、スマホの電池消費を抑えるために、Bluetoothスキャンを停止させる。
```

### 2.2 Register a Sesame
1.   Set up `CHBleManager`'s delegate property to discover unregistered Sesame devices.
```swift
CHBleManager.shared.delegate = self
```
Once you delegate to `CHBleManager` and also adopted the `CHBleManagerDelegate` protocol, you will recevie unregistered Sesame devices in the following methods.
```swift
class SomeClass: CHBleManagerDelegate {
    public func didDiscoverUnRegisteredSesames(sesames: [CHSesame2]) {
        // Your implementation
    }
    public func didDiscoverUnRegisteredSesame(sesame: CHSesame2) {
        // Your implementation
    }
}
```
2. Connect unregistered Sesame devices.     
Before registering a Sesame device, you have to connect to it in order to send commands to it. 
```swift
public func didDiscoverUnRegisteredSesames(sesames: [CHSesame2]) {
    for sesame2 in sesame2s {
        sesame2.connect()
    }
}
```
When you are ready to register the Sesame device, you can send the register command as long as the device's status is `.readytoRegister`, otherwise, you may want to delegate to the device so you can monitor the status updates of the Sesame device, and be able to connect to it once the status becomes `.readytoRegister`.

```swift
class SomeClass: CHSesame2Delegate {
    func register() {
        // Resiger the device if it is ready.
        if sesame2.deviceStatus == .readytoRegister {
            sesame2.registerSesame( { result in
                // Completion handler
            })
        } else {
        // Otherwise monitor the status until it is ready.
            sesame2.delegate = self as CHSesame2Delegate
        }
    }

    func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status) {
        if status == .readytoRegister {
            device.registerSesame( { result in
                // Completion handler
            })
        }
    }
}

```
# 3. セサミデバイスを操作する
After successfully registering Sesame device with `device.registerSesame`, you can operate the Sesame device. The following examples demonstrate how to operate the Sesame device.

<p align="center" >
  <img src="https://raw.github.com/CANDY-HOUSE/SesameSDK_iOS_with_DemoApp/assets/ControlSesameDevice.png" alt="CANDY HOUSE Sesame SDK" title="SesameSDK">
</p>

### 3.1 Retrieve Sesame
Every registered Sesame device can be retrieved via `CHBleManager.shared.getSesames()`.
```swift
CHBleManager.shared.getSesames() { result in
    switch result {
        case .success(let ssms):
            // Success handle
        case .failure(let error):
            // Error handle
    }
}
```
1. You may want to `connect()` the device before sending any command.
```swift
sesame2.connect()
```
2. `delegate` to the Sesame device if you would like to receive the Sesame device's status updates.
```swift
sesame2.delegate = self


class SomeClass: CHSesame2Delegate {
    
    /// Will be invoked whenever sesame device interaction status changed.
    /// - Parameters:
    ///   - device: Sesame device.
    ///   - status: `CHDeviceStatus`
    func onBleDeviceStatusChanged(device: CHSesame2, status: CHSesame2Status)

    /// Will be invoked whenever sesame device status has changed.
    /// - Parameters:
    ///   - device: Sesame device.
    ///   - status: `CHSesameMechStatus`
    ///   - intention: `CHSesameIntention`
    func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention)
}
```

### 3.2 セサミデバイスの基本設定をする

1. 施解錠の角度また位置を調整する:
```swift
// Lock: 90°, Unlock: 0°
var config = CHSesameLockPositionConfiguration(lockTarget: 1024/4, unlockTarget: 0)
sesame2.configureLockPosition(configure: &config)
```
2. オートロック機能を設定する:
```swift
sesame2.enableAutolock(delay: second[row]) { (delay) -> Void in
    // Complete handler
}

sesame2.disableAutolock() { (delay) -> Void in
    // Complete handler
}
```
3. このセサミデバイスの鍵を破棄する:  
```swift
sesame2.dropKey()
// SesameSDKの内部データベースに保存されてるこのセサミの鍵を破棄するだけ。
// You will not able to retrieve the Sesame device via `CHBleManager.shared.getSesames()`. 再度何処かから同じ鍵を取ってこれば再度使える状態になる。
```
4. このセサミデバイスをリセットする:     
```swift
sesame2.resetSesame2()
//セサミデバイスを初期化（リセット）し、そしてSesameSDKの内部データベースに保存されてるこのセサミの鍵を破棄する。何処かから同じ鍵を取って来ても再度使えない。ユーザーは新規登録のみできる。
```
### 3.3 Get Sesame Information

1. UUID:     
Every Sesame device has a unique identifier.
```swift
sesame2.deviceId
```
2. Sesame device status (`noSignal`, `receivedBle`, `connecting`, `loginStatus`, etc.) Please see Documents/CHSesame2Status.md
```swift
sesame2.deviceStatus 
```
3. Sesame mechanical status (angle position, battery status, etc) Please see Documents/CHSesame2MechStatus.md
```swift
sesame2.mechStatus
```
### 3.4 解錠する
```swift
sesame2.unlock { result in
    // Completion handler
}
```
### 3.5 セサミデバイスの鍵をシェアする
SesameSDK can export keys(Base64 encoded JSON objects) to you, and you can share the keys with other people in many ways.
1. Export Sesame keys:
```swift
sesame2.getKey()
```
2. Import Sesame keys:     
Once you imported keys(Base64 encoded JSON objects) successfully, you can retrieve the device via `CHBleManager.shared.getSesames()`.
```swift
CHDeviceManager.shared.receiveSesame2Keys(sesame2Keys: [String]) { result in
    switch result {
        case .success(_):
            // Success handler
        case .failure(let error):
            // Error handler
    }
}
```


# 最後に

- もし **バグが見つかった場合**、かつ _確実にそのバグを再現する方法がある場合_、issue を open してください。
- もし **追加機能の要望があれば**、issue を open してください。
- もし **contribute をしたい場合**、Pull Request をしてください。
- もしこの SesameSDK に **security vulnerability**(セキュリティホール) を発見された場合、メールアドレス developers@candyhouse.co まで出来るだけ早くご連絡ください。公開の issue tracker に掲載しないようお願い申し上げます。
- SesameSDK は、[MIT License](https://github.com/CANDY-HOUSE/SesameSDK_iOS_with_DemoApp/blob/master/LICENSE)の元で、[CANDY HOUSE, Inc.](https://jp.candyhouse.co/)によってメンテナンスされております。
