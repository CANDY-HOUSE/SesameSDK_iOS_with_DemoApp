```Swift
public class Sesame2History {
    public var recordID: Int32       // 連続でない(将来的に連続になるように修正予定)、唯1つ、 小→大
    public var type: SS2HistoryType  // 事件    
    public var timeStamp: Int32      // タイムスタンプ  ex:166
    public var historyTag: Data?     // 鍵に付いてるタグやメモ 22bytes
    public var enableCount: Int?     // このセサミデバイスが登録された回数 また レセットされた回数         
}
```