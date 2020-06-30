```Swift
public protocol CHSesameMechSettings {
    
    /// Get the specific value of lock position.
    func getLockPosition() -> Int64?
    
    /// Get the specific value of unlock position.
    func getUnlockPosition() -> Int64?
   
    /// Indicate is sesame device in the initial setting.
    func isConfigured() -> Bool
}
```