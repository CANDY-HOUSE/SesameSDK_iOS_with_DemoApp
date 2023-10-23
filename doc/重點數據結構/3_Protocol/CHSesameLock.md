# public protocol CHSesameLock

繼承自 CHDeivice，為 Sesame 所有可開關型產品

## 方法

```Swift
- getHistoryTag() -> Data? //取得Sesame歷史紀錄上的顯示名稱(Tag)
- setHistoryTag(_ tag: Data, result: @escaping (CHResult<CHEmpty>))
- cenableNotification(token: String, name: String, result: @escaping CHResult<CHEmpty>)//啟用該Sesame的通知功能
- disableNotification(token: String, name: String, result: @escaping CHResult<CHEmpty>)//停用該Sesame的通知功能
isNotificationEnabled(token: String, name: String, result: @escaping CHResult<Bool>): // 檢查Sesame通知是否啟用
```
