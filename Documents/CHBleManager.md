```Swift
CHBleManager.shared.delegate  //このメソッドを使用するとセサミのBLE電波が現れたらSDKからアプリ内部に通知します
CHBleManager.shared.receiveKey(ssm2Keys: [String],completionHandler: @escaping SendValueClosure)
CHBleManager.shared getMyDevices(completionHandler: @escaping (Result<[CHSesameBleInterface], Error>) -> Void)
//スマホのローカルのデータベースから自分が所有しているセサミというObjectのlistを取得します。

CHBleManager.shared.enableScan()　//BLEスキャンのスイッチをオンする
CHBleManager.shared.disableScan()　//BLEスキャンのスイッチをオフする
```
