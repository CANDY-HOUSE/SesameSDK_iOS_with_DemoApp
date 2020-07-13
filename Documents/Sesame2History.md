```Swift
public class Sesame2History {
    public var recordID: Int32       // 連続でない(将来的に連続になるように修正する予定)、セサミデバイスがリセットされるまで当履歴の唯1つのID、 小→大
    public var type: SS2HistoryType  // 事件のタイプ
    public var timeStamp: Int32      // タイムスタンプ  ex:166
    public var historyTag: Data?     // 鍵に付いてるタグやメモ 22bytes
    public var enableCount: Int?     // このセサミデバイスが登録された回数 また レセットされた回数         
}
```
