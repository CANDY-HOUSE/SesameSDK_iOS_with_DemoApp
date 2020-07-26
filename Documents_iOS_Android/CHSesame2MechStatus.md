## iOS
```Swift
public protocol CHSesame2MechStatus {

    func getBatteryVoltage() -> Float
    //電池の電圧の取得、単位: 0V ~ 7.2V

    func getBatteryPrecentage() -> Int
    
    func getPosition() -> Int16?
    //セサミのリアルタイムの角度。範圍： -32767~0~32767 ; -32768 は意義のない的デフォルト值。 例0˚ ⇄ 0 で 360˚ ⇄ 1024 

    func isInLockRange() -> Bool?
    //施錠範囲であるか否か　の判断   
    
    func isInUnlockRange() -> Bool?
    //解錠範囲であるか否か　の判断
}
```
## Android
```Kotlin
class CHSesame2MechStatus(data: ByteArray) {

    fun getBatteryVoltage(): Float
    
    fun getBatteryPrecentage(): Int 
    
    val position:Short

    var inLockRange:Boolean
    
    var inUnlockRange:Boolean
}

```
