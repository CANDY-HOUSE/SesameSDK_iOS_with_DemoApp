## iOS
```swift
public protocol CHSesame2BleAdvParameterResponse {
    var interval: Double { get }　// 単位: millisecond
    var txPower: Int8 { get }     // 単位: dBm
}
```

## Android
```kotlin
class CHSesame2BleAdvParameter(val interval: Double, val txPower: Byte)
```
