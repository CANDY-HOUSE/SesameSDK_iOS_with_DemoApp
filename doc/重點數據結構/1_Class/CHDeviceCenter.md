# CHDeviceCenter 類別說明

此 APP 的 Core Data 本地儲存管理中心，以`shared` 建立單例，用來緩存數據以提高性能。將`CHDeviceKey` 存入 Core Data 前須轉換為 `CHDeviceMO`(MO = manage object)。 `CHDeviceMO` 即代表本地數據庫中的 Sesame 設備。

## 屬性

- `backgroundContext` 一個 Core Data 的 `NSManagedObjectContext`，允許在背景執行緒中執行數據操作。
- `persistentContainer`
- `cacheDevices` 存`CHDeviceMO` 用的陣列

### 初始化

- iOS 在背景列獲取設備

## 方法

```Swift
//---初始化---
func initDevices()
// 從 Core Data 中提取所有的 CHDeviceMO 並將它們儲存到 cacheDevices

private init()
//設置 Core Data 的存儲、獲取數據模型、轉換名稱、設置存儲的位置等。
//---

func appendDevice(_ CHDeviceKey: CHDeviceKey)
//把`CHDeviceKey`轉成`CHDeviceMO`，並添加到 Core Data 和快取中。

func getDevice(deviceID: UUID?) -> CHDeviceMO?
//根據設備 UUID 在緩存中搜尋特定 CHDeviceMO 對象

func deleteDevice(_ device: CHDeviceMO)
// 刪除指定`DeviceMO`

func saveifNeed()
//如果有任何未保存的變更，則保存到 Core Data

func lastCachedevices() -> [CHDeviceMO]
//從 Core Data 中抓到所有`DeviceMO`

func logout()
//刪除所有` CHDeviceMO` 對象並清空緩存
```
