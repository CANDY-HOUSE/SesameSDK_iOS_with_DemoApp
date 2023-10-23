# RegisterSesameDeviceViewController

`RegisterSesameDeviceViewController` 此 class 處理 Sesame 設備的註冊 => 發現、選擇和註冊新 Sesame 設備
此類別是`CHBaseTableViewController`的子類別，實現`CHBleManagerDelegate`和`CHDeviceStatusDelegate`協議。

```swift
class RegisterSesameDeviceViewController: CHBaseTableViewController{
    var devices: [CHDevice] = []
    var registeredDevice: CHDevice?
    var dismissHandler: ((CHDevice?)->Void)?
}
```

## 屬性

- `devices`：CHDevice 陣列，代表已經被藍芽發現、並可註冊的 Sesame 設備
- `registeredDevice`：一個 CHDevice 物件，代表當前正在註冊的 Sesame 設備
- `dismissHandler`：一個在視圖控制器 dismiss 時調用的 Closure，為傳進此 Closure 的參數是以註冊的設備。

## 方法

- `registerCHDevice(_:)`:Sesame 註冊至 APP 與 Sesame 帳戶的過程

  1.`device.register { result in：` 代碼調用 device 的 register 方法來開始註冊過程。此過程可能會需要一些時間，因此這個函數是異步的，它在完成後會調用一個回調函數並傳遞結果。

  2.`Sesame2Store.shared.deletePropertyFor(device)：` 刪除此 Sesame 設備的所有本地儲存的屬性。避免註冊過的資料影響新的註冊

  3. `Sesame2Store.shared.getHistoryTag()`：取得存在 Sesame2Store 中的 HistoryTag(預設為登入的 email)

  4.若 Sesame 為 Sesame3/4，鎖的 lock range 設定為 0~256 度

  5.設定權限與設備名稱

  6.`CHUserAPIManager.shared.getSubId { subId in ... }`：這部分從 CHUserAPIManager 獲的登入用戶的 subId，該 ID 和設備創建一個新的 CHUserKey，後傳送到 Server 端
