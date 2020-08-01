## iOS
```Swift
public protocol CHSesame2MechSettings {
    func lockPosition() -> Int16?    // Get the specific value of lock position.
    func unlockPosition() -> Int16?  // Get the specific value of unlock position.
    func isConfigured() -> Bool         // Indicate is sesame device in the initial setting.
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
