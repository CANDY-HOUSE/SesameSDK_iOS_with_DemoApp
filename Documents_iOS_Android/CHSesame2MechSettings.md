## iOS
```Swift
public protocol CHSesame2MechSettings {
    func lockPosition() -> Int16?    // 施錠範囲内にあるか否か?
    func unlockPosition() -> Int16?  // 解錠範囲内にあるか否か?
    func isConfigured() -> Bool      // セサミデバイスが登録後、設定された事あるか否か?
}
```
## Android

```Kotlin
class CHSesame2MechSettings() {
     val lockPosition: Short
     val unlockPosition: Short
     val isConfigured:Boolean
}

```
