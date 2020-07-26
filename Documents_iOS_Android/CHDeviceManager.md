## iOS
```swift
CHDeviceManager.shared.getSesame2s(result: @escaping (CHResult<[CHSesame2]>))
//スマホのローカルのデータベースから自分が所有しているセサミというObjectのlistを取得します。デバイスがない場合は、空の配列が返ってくる。
CHDeviceManager.shared.receiveSesame2Keys(sesame2Keys: String...,result: @escaping (CHResult<[CHSesame2]>))
CHDeviceManager.shared.receiveSesame2Keys(sesame2Keys: [String],result: @escaping (CHResult<[CHSesame2]>))
// このセサミデバイスの 「Base64 encoded 鍵」 をSesameSDKの内部データベースに伝達する/入力する/入れる/渡す
```

## Android

```kotlin
object CHDeviceManager {
    fun getSesame2s(result: CHResult<ArrayList<CHSesame2>>)
    fun receiveSesame2Keys(vararg ssm2Keys: String, result: CHResult<ArrayList<CHSesame2>>)
    fun receiveSesame2Keys(ssm2Keys: ArrayList<String>, result: CHResult<ArrayList<CHSesame2>>)
}
```
