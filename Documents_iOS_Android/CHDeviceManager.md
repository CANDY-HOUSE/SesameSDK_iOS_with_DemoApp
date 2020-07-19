```swift
CHDeviceManager.shared.getSesame2s(completionHandler: @escaping (Result<[CHSesame2], Error>) -> Void)
//スマホのローカルのデータベースから自分が所有しているセサミというObjectのlistを取得します。デバイスがない場合は、空の配列が返ってくる。
CHDeviceManager.shared.receiveSesame2Keys(sesame2Keys: [String],completionHandler: @escaping (Result<[CHSesame2], Error>) -> Void))
CHDeviceManager.shared.receiveSesame2Keys(sesame2Keys: String...,completionHandler: @escaping (Result<[CHSesame2], Error>) -> Void))
// このセサミデバイスの 「Base64 encoded 鍵」 をSesameSDKの内部データベースに伝達する/入力する/入れる/渡す
```
