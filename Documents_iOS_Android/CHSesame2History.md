```swift
public class CHSesame2History {
    public var recordID: Int32       // 連続でない(将来的に連続になるように修正する予定)、セサミデバイスがリセットされるまで当履歴の唯1つのID、 小→大
    public var type: CHSesame2HistoryType  // 事件のタイプ    
    public var timeStamp: Int32      // 1970/1/1 00:00:00 から秒単位のタイムスタンプ  ex:166
    public var historyTag: Data?     // 鍵に付いてるタグやメモ 0 ~ 21bytes
    public var registrationTimes: Int?     // このセサミデバイスが CANDY HOUSEサーバー に登録された回数 
}
```
