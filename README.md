<img src="https://img.shields.io/badge/Bluetooth-4.0LE-lightblue" /> <img src="https://img.shields.io/badge/iOS-11-black" /> <img src="https://img.shields.io/badge/Android-5.0-black" /> <img src="https://img.shields.io/badge/Xcode-11.5-blue" /> <img src="https://img.shields.io/badge/Android Studio-4.0-blue" /> <img src="https://img.shields.io/badge/Swift-5.2.4-orange" /> <img src="https://img.shields.io/badge/Kotlin-1.3-orange" />
<br/>
<p align="center" >
  <img src="https://raw.github.com/CANDY-HOUSE/SesameSDK_iOS_with_DemoApp/assets/SesameSDK_Swift.png" alt="CANDY HOUSE Sesame SDK" title="SesameSDK">
</p>

- [Introduction](#Introduction)
- [Configure the SDK](#configure-the-sdk)
- [Register Sesame deivce](#Register-Sesame-device)
  - [Scan for Sesame devices](#Scan-for-Sesame-devices)
  - [Register a Sesame](#Register-a-Sesame)
- [Control Sesame deivce](#Control-Sesame-device)
  - [Retrieve Sesame](#Retrieve-Sesame)
  - [Configure Sesame](#Configure-Sesame)
  - [Get Sesame Information](#Get-Sesame-Information)
  - [Lock/Unlock Sesame](#Lockunlock-Sesame)
  - [Share Sesames' Keys](#Share-Sesame-Keys)

# Introduction
SesameSDK on iOS/Android is a delightful Bluetooth/IoT(Internet of Things) library for your iOS/Android app. The official Sesame app is built on this SesameSDK. By using SesameSDK, your app will have **ALL** functions and features that Sesame app has, which means, you will be able to

- Register Sesame
- Lock door
- Unlock door
- Share keys
- Read door history
- Update Sesame firmware
- Configure Auto-lock
- Configure angles
- Get the statuses such battery status
- iOS/iPadOS Widget
- Apple Watch app

with your app.<br>Please note, SesameSDK currently only supports ___Sesame 2___ series or Sesame 1 that runs ___SesameOS 2___ which will be available in late 2020.

# Requirements

| Minimum Targets | Minimum Bluetooth Target | Minimum IDEs |
|:------------------:|:------------------------:|:-----------:|
| iOS 11 <br> iPadOS 13.1 | Bluetooth 4.0 LE | Xcode 11.5 | 
| Android 5.0 | Bluetooth 4.0 LE | Android Studio 4.0 | 

# Essential dependencies
- SesameSDK.framework
- AWSAPIGateway.framework
# Configure the SDK
1. Download SesameSDK and play with the included iOS/Android Demo app.  または
[Apple TestFlight](https://testflight.apple.com/join/mK4OadTW) / 
[Google Drive](https://drive.google.com/file/d/15aRQl6aWBVwJSE4l3ZL-eMisPoe-f2lW/view?usp=sharing)
から Demo app をダウンロードする。
2. Drag the SesameSDK.framework and AWSAPIGateway.framework into your project.
3. Get the **API Key** and the **Identity Pool ID** from CANDY HOUSE in order to register Sesame device and access the history. 
4. Setup the **API Key** and the **Identity Pool ID** in `didFinishLaunchingWithOptions` of `AppDelegate`.
```swift
import SesameSDK

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
...
    CHConfiguration.shared.setAPIKey("API_KEY")
    CHConfiguration.shared.setIdentityPoolId("IDENTITY_POOL_ID")
...
}
```

# Register Sesame device
<p align="center" >
  <img src="https://raw.github.com/CANDY-HOUSE/SesameSDK_iOS_with_DemoApp/assets/RegisterSesameDevice.png" alt="CANDY HOUSE Sesame SDK" title="SesameSDK">
</p>

### Scan for Sesame devices
1. Scan for Sesame devices.
```Swift
CHBleManager.shared.enableScan()
```

2. Disconnect Sesame devices and stop Bluetooth scanning when entering the background.
```Swift
CHBleManager.shared.disableScan()
CHBleManager.shared.disConnectAll()
```

### Register a Sesame
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
# Control Sesame device
After successfully registering Sesame device with `device.registerSesame`, you can operate the Sesame device. The following examples demonstrate how to operate the Sesame device.

<p align="center" >
  <img src="https://raw.github.com/CANDY-HOUSE/SesameSDK_iOS_with_DemoApp/assets/ControlSesameDevice.png" alt="CANDY HOUSE Sesame SDK" title="SesameSDK">
</p>

### Retrieve Sesame
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

### Configure Sesame

1. Locked/Unlocked angle adjustment:
```swift
// Lock: 90°, Unlock: 0°
var config = CHSesameLockPositionConfiguration(lockTarget: 1024/4, unlockTarget: 0)
sesame2.configureLockPosition(configure: &config)
```
2. Enable/Disable auto-lock:
```swift
sesame2.enableAutolock(delay: second[row]) { (delay) -> Void in
    // Complete handler
}
```
```swift
sesame2.disableAutolock() { (delay) -> Void in
    // Complete handler
}
```
3. Drop Key:     
This command will clear the Sesame keys saved in SesameSDK. This means you will not able to retrieve the Sesame device via `CHBleManager.shared.getSesames()`.
```swift
sesame2.dropKey()
```
4. Reset Sesame:     
This command will reset the Sesame device and clear the Sesame keys saved in SesameSDK.
```swift
sesame2.resetSesame()
```
### Get Sesame Information

1. UUID:     
Every Sesame device has a unique identifier.
```swift
sesame2.deviceId
```
2. Sesame device status (`noSignal`, `receiveBle`, `connecting`, `loginStatus`, etc.) Please see Documents/CHSesame2Status.md
```swift
sesame2.deviceStatus 
```
3. Sesame mechanical status (angle position, battery status, etc) Please see Documents/CHSesame2MechStatus.md
```swift
sesame2.mechStatus
```
### Lock/Unlock Sesame
```swift
sesame2.toggle { result in
    // Completion handler
}
```
### Share Sesame Keys
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


# Communications

- If you **found a bug**, _and can provide steps to reliably reproduce it_, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.
- If you believe you have identified a **security vulnerability** with SesameSDK, you should report it as soon as possible via email to developers@candyhouse.co Please do not post it to a public issue tracker.

# License
SesameSDK is maintained by [CANDY HOUSE, Inc.](https://jp.candyhouse.co/) under the [MIT License](https://github.com/CANDY-HOUSE/SesameSDK_iOS_with_DemoApp/blob/master/LICENSE).
