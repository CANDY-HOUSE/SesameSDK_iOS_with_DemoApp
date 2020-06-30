```Swift
public protocol CHSesameBleInterface: class {
    var deviceId: UUID! { get } // UUID for each Sesame device, never changes

    typealias AutolockSettingCallback = (_ delay: Int) -> Void
    
    var delegate: CHSesameBleDeviceDelegate? { get set }　
    //このメソッドを使用するとCHDeviceStatus/CHSesameMechStatus/CHSesameMechSettingsの変化があればSDKからアプリ内部に通知します

    var rssi: NSNumber { get } //セサミのBluetooth電波の強さ
    var model: CHDeviceModel { get } //Sesame2, Sesame2 mini, Sesame1, Sesame1 mini, WiFi Access Point 2 , WiFi Access Point 1
    var isRegistered: Bool { get } //既に登録済みか否か
    var deviceStatus: CHDeviceStatus { get } //BLE接続状況：セサミ発見->接続中->認証済->接続成功
    var mechStatus: CHSesameMechStatus? { get } //電池の電圧の取得、セサミのリアルタイムの角度の取得、施解錠範囲であるか否かの確認
    var mechSetting: CHSesameMechSettings? { get } //セサミの解錠・施錠の角度
    var intention: CHSesameIntention { get }

    func connect() //このセサミデバイスとアプリとの間のBluetooth接続を築く
    func disconnect() //このセサミデバイスとアプリとの間のBluetooth接続を切断。
    func disConnectAll() //全てのセサミデバイスとアプリとの間のBluetooth接続を切断。
    // disconnect() や disConnectAll()を叩かないと、アプリをバックグラウンドに送った時にセサミデバイスとアプリとの間のBluetooth接続がされたのままなので、セサミデバイスとWidgetとの間のBluetooth接続に切り替えできない。逆に、叩かないとWidgetをバックグラウンドに送った時に、セサミデバイスとアプリとの間のBluetooth接続への切り替えができない。
    
    /// Register this device.　CANDY HOUSEサーバーへセサミの登録
    /// - Parameters:
    ///   - completion: `CHResult<Any>`
    func registerSesame( _ completion: @escaping CHResult<CHDeviceKey>)
    
    /// セサミを初期化（リセット）
    func resetSesame()
    
    /// Set sesame devices's lock position. 施解錠の回転位置設定
    /// - Parameter configure: `CHSesameLockPositionConfiguration`
    func configureLockPosition(configure: inout CHSesameLockPositionConfiguration) 
    
    /// Move lock to the lock position.　施錠
    //    func lock() 
    func lock(result: @escaping (CHResult<SSM2CmdResultCode>))
    
    /// Move lock to the unlock position.　解錠
    //    func unlock() 
    func unlock(result: @escaping (CHResult<SSM2CmdResultCode>))

    /// Perform `lock`/`unlock`
    //    func toggle()
    func toggle(result: @escaping (CHResult<SSM2CmdResultCode>))
    
    /// Get the period of time for autolock setting.　オートロック機能の状態を取得
    /// - Parameter completion: `AutolockSettingCallback`
    func getAutolockSetting(completion: @escaping AutolockSettingCallback)
    
    /// Lock automatically after a period of time whenever unlocked.　オートロック機能の秒数を入力しオン
    /// - Parameters:
    ///   - delay: Autolock in specific second.
    ///   - completion: `AutolockSettingCallback`
    func enableAutolock(delay: Int, completion: @escaping AutolockSettingCallback)
    
    /// Disable sesame device autolock.　オートロック機能をオフ
    /// - Parameter completion: `AutolockSettingCallback`
    func disableAutolock(completion: @escaping AutolockSettingCallback)
   
    func dropKey() //SesameSDKからこのセサミの鍵を削除
    func getKey() -> String?

}
```
