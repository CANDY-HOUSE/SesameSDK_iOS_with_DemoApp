```Swift
public protocol CHSesameMechStatus {
    //電池の電圧の取得、単位: 0V ~ 7.2V
	func getBatteryVoltage() -> Float
	
    //セサミのリアルタイムの角度
	func getPosition() -> Int64?
    
    //施錠範囲であるか否か　の判断
	func isInLockRange() -> Bool?
    
    //解錠範囲であるか否か　の判断
	func isInUnlockRange() -> Bool?
}
```
