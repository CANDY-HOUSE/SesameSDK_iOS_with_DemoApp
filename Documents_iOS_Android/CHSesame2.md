# iOS

```Swift
public protocol CHSesame2: class {
    var deviceId: UUID! { get } // UUID for each Sesame device, never changes
    var delegate: CHSesame2Delegate? { get set } //このメソッドを使用するとCHDeviceStatus/CHSesameMechStatus/CHSesameMechSettingsの変化があればSDKからアプリUIにイベントを送る
    var rssi: NSNumber { get } //セサミのBluetooth電波の強さ
    var isRegistered: Bool { get } //既に登録済みか否か
    var deviceStatus: CHSesame2Status { get } //BLE接続状況：セサミ発見->接続中->認証済->接続成功

    var mechStatus: CHSesame2MechStatus? { get } //電池の電圧の取得、セサミのリアルタイムの角度の取得、施解錠範囲であるか否かの確認
    var mechSetting: CHSesame2MechSettings? { get } //セサミの解錠・施錠の角度など
    var intention: CHSesame2Intention { get } // locking：現在締めようとしている途中 ; unlocking：現在開けようとしている途中

    func lock(result: @escaping (CHResult<CHEmpty>)) // Move lock to the lock position.　施錠
    func unlock(result: @escaping (CHResult<CHEmpty>)) // Move lock to the unlock position.　解錠
    func toggle(result: @escaping (CHResult<CHEmpty>)) // Perform `lock`/`unlock`

    func connect(result: @escaping (CHResult<CHEmpty>)) //このセサミデバイスとアプリとの間のBluetooth接続を築く
    func disconnect(result: @escaping (CHResult<CHEmpty>)) //このセサミデバイスとアプリとの間のBluetooth接続を切断。
    // disconnect() や disConnectAll()を叩かないと、アプリをバックグラウンドに送った時にセサミデバイスとアプリとの間のBluetooth接続がされたのままなので、セサミデバイスとWidgetとの間のBluetooth接続に切り替えできない。逆に、叩かないとWidgetをバックグラウンドに送った時に、セサミデバイスとアプリとの間のBluetooth接続への切り替えができない。

    func registerSesame( _ result: @escaping CHResult<CHDeviceKey>) // Register this device.　CANDY HOUSEサーバーへセサミの登録
    func resetSesame(result: @escaping (CHResult<CHEmpty>))
    /* CANDY HOUSEのサーバーと関係なく、セサミデバイスと接続済のみに使う。
     セサミデバイスを初期化（リセット）し、そしてSesameSDKの内部データベースに保存されてるこのセサミの鍵を削除する。
    　何処かから同じ鍵を取って来ても再度使えない。ユーザは新規登録のみできる。
    */

    func configureLockPosition(lockTarget: Int16, unlockTarget: Int16,result: @escaping (CHResult<CHEmpty>))
    // Set sesame devices's lock position. 施解錠の回転位置設定   

    func getAutolockSetting(result: @escaping (CHResult<Int>)) // Get the period of time for autolock setting.　オートロック機能の状態を取得
    func enableAutolock(delay: Int, result: @escaping (CHResult<Int>)) 
    // Lock automatically after a period of time whenever unlocked.　オートロック機能の秒数を入力しオン ; delay: オートロック機能の秒数
    func disableAutolock(result: @escaping (CHResult<Int>)) // Disable sesame device autolock.　オートロック機能をオフ

    func updateFirmware(_ result: @escaping CHResult<CBPeripheral?>)
    func getVersionTag(result: @escaping (CHResult<String>))

    func setHistoryTag( _ tag:Data,result: @escaping (CHResult<Data>)) //履歴にタグやメモをつける
    func getHistoryTag() -> Data? //履歴に付いてるタグやメモを取得

    func dropKey() //SesameSDKの内部データベースに保存されてるこのセサミの鍵を削除するだけ。再度何処かから同じ鍵を取ってこれば再度使える状態になる。
    func getKey() -> String?  //SesameSDKの内部データベースに保存されてるこのセサミデバイスの 「Base64 encoded 鍵」 を取り出す

    func getHistories(page: UInt, _ callback: @escaping CHResult<[CHSesame2History]>) 
    // SDK経由で最新の履歴から取得する; page:ページ数、1ページの中に新→旧の順番で最大50個の履歴が入ってる。
}
```

# Android

```kotlin
public interface CHSesame2 {
    var deviceId: UUID?
    var delegate: CHSesame2Delegate?
    var rssi: Int
    var isRegistered: Boolean
    var deviceStatus: CHSesame2Status

    var mechStatus: CHSesame2MechStatus?
    var mechSetting: CHSesame2MechSettings?
    var intention: CHSesame2Intention

    fun lock(result: CHResult<CHEmpty>)
    fun unlock(result: CHResult<CHEmpty>)
    fun toggle(result: CHResult<CHEmpty>)

    fun connnect(result: CHResult<CHEmpty>)
    fun disconnect(result: CHResult<CHEmpty>)

    fun registerSesame(result: CHResult<CHEmpty>)
    fun resetSesame(result: CHResult<CHEmpty>)

    fun configureLockPosition(lockTarget: Short, unlockTarget: Short, result: CHResult<CHEmpty>)

    fun getAutolockSetting(result: CHResult<UShort>)
    fun enableAutolock(delay: Int, result: CHResult<UShort>)
    fun disableAutolock(result: CHResult<UShort>)

    fun updateFirmware(onResponse: CHResult<BluetoothDevice>)
    fun getVersionTag(result: CHResult<String>)

    fun setHistoryTag(tag: ByteArray, result: CHResult<CHEmpty>)
    fun getHistoryTag(): ByteArray?

    fun dropKey()
    fun getKey(): String

}
```
