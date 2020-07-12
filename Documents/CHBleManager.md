```Swift
CHBleManager.shared.delegate  //このメソッドを使用するとセサミのBLE電波が変動や現れたらSDKからアプリUIにイベントを送る
CHBleManager.shared.enableScan(result: @escaping (CHResult<CHEmpty>))　   //BLEスキャンのスイッチをオンする
CHBleManager.shared.disableScan(result: @escaping (CHResult<CHEmpty>))　  //BLEスキャンのスイッチをオフする
CHBleManager.shared.disConnectAll(result: @escaping (CHResult<CHEmpty>))  //全てのBLEデバイスとアプリとの間のBluetooth接続を切断。
CHBleManager.shared.getSesames(completionHandler: @escaping (Result<[CHSesame2], Error>) -> Void)
//スマホのローカルのデータベースから自分が所有しているセサミというObjectのlistを取得します。デバイスがない場合は、空の配列が返ってくる。

CHBleManager.shared.receiveKey(ssm2Keys: [String],completionHandler: @escaping (Result<[CHSesame2], Error>) -> Void))
CHBleManager.shared.receiveKey(ssm2Keys: String...,completionHandler: @escaping (Result<[CHSesame2], Error>) -> Void))
// 「Base64 encoded 鍵」 をSesameSDKに伝達する/入力する/入れる
```
