```Swift
public protocol CHSesame2: class {
    var deviceId: UUID! { get } // UUID for each Sesame device, never changes

    typealias AutolockSettingCallback = (_ delay: Int) -> Void
    
    var delegate: CHSesameBleDeviceDelegate? { get set }　
    //このメソッドを使用するとCHDeviceStatus/CHSesameMechStatus/CHSesameMechSettingsの変化があればSDKからアプリUIにイベントを送る

    var rssi: NSNumber { get } //セサミのBluetooth電波の強さ
    var model: CHDeviceModel { get } //Sesame2, Sesame2 mini, Sesame1, Sesame1 mini, WiFi Access Point 2 , WiFi Access Point 1
    var isRegistered: Bool { get } //既に登録済みか否か
    var deviceStatus: CHDeviceStatus { get } //BLE接続状況：セサミ発見->接続中->認証済->接続成功
    var mechStatus: CHSesameMechStatus? { get } //電池の電圧の取得、セサミのリアルタイムの角度の取得、施解錠範囲であるか否かの確認
    var mechSetting: CHSesameMechSettings? { get } //セサミの解錠・施錠の角度
    var intention: CHSesameIntention { get } // locking：現在締めようとしている途中 ; unlocking：現在開けようとしている途中

    func connect(result: @escaping (CHResult<CHEmpty>)) //このセサミデバイスとアプリとの間のBluetooth接続を築く
    func disconnect(result: @escaping (CHResult<CHEmpty>)) //このセサミデバイスとアプリとの間のBluetooth接続を切断。
    func disConnectAll() //全てのセサミデバイスとアプリとの間のBluetooth接続を切断。
    // disconnect() や disConnectAll()を叩かないと、アプリをバックグラウンドに送った時にセサミデバイスとアプリとの間のBluetooth接続がされたのままなので、セサミデバイスとWidgetとの間のBluetooth接続に切り替えできない。逆に、叩かないとWidgetをバックグラウンドに送った時に、セサミデバイスとアプリとの間のBluetooth接続への切り替えができない。
    
    // Register this device.　CANDY HOUSEサーバーへセサミの登録
    func registerSesame( _ completion: @escaping CHResult<CHDeviceKey>)
    
    // セサミデバイスを初期化（リセット）
    func resetSesame(result: @escaping (CHResult<CHEmpty>))
    
    // Set sesame devices's lock position. 施解錠の回転位置設定
    func configureLockPosition(lockTarget: Int16, unlockTarget: Int16, result: @escaping (SesameSDK.CHResult<SesameSDK.BLECmdResultCode>)) 
    
    // Move lock to the lock position.　施錠
    func lock(result: @escaping (CHResult<CHEmpty>))
    
    // Move lock to the unlock position.　解錠
    func unlock(result: @escaping (CHResult<CHEmpty>))

    // Perform `lock`/`unlock`
    func toggle(result: @escaping (CHResult<CHEmpty>))
    
    // Get the period of time for autolock setting.　オートロック機能の状態を取得
    func getAutolockSetting(result: @escaping (CHResult<Int>))
    
    // Lock automatically after a period of time whenever unlocked.　オートロック機能の秒数を入力しオン
    // - delay: オートロック機能の秒数
    func enableAutolock(delay: Int, result: @escaping (CHResult<Int>))
    
    // Disable sesame device autolock.　オートロック機能をオフ
    func disableAutolock(result: @escaping (CHResult<Int>))

    func setHistoryTag( _ tag:Data,result: @escaping (CHResult<Data>)) //履歴にタグやメモをつける
    func getHistoryTag() -> Data?　//履歴に付いてるタグやメモを取得
   
    func dropKey() //SesameSDKからこのセサミの鍵を削除
    func getKey() -> String?
    
    // SDKを経由して、履歴を取得する
    func getHistorys(page:Int, pageLength: Int, _ callback: @escaping CHResult<[Sesame2History]>)

}
```
