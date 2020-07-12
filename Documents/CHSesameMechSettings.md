```Swift
public protocol CHSesameMechSettings {
    
    func getLockPosition() -> Int64?
    // Get the specific value of lock position.

    func getUnlockPosition() -> Int64?
    // Get the specific value of unlock position.
   
    func isConfigured() -> Bool
    // Indicate is sesame device in the initial setting.
}
```
