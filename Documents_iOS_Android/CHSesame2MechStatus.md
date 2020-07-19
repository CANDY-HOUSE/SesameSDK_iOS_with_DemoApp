```Swift
public protocol CHSesame2MechStatus {

    func getBatteryVoltage() -> Float
    //電池の電圧の取得、単位: 0V ~ 7.2V

    func getPosition() -> Int64?
    //セサミのリアルタイムの角度     

    func isInLockRange() -> Bool?
    //施錠範囲であるか否か　の判断   
    
    func isInUnlockRange() -> Bool?
    //解錠範囲であるか否か　の判断
}
```
