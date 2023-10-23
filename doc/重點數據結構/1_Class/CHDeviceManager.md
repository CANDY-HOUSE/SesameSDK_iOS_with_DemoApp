# CHDeviceManager 類別說明

Sesame 設備管理中心，包括了連接、檢索設備、接收設備鑰匙功能。以`shared` 建立單例

### 初始化

- 在 iOS ：`CHIoTManager.shared.reconnect()` 從背景列隊獲取設備
- 在 watchOS：從主線程中獲取設備

## 方法

```Swift
func getCHDevices(result: @escaping (CHResult<[CHDevice]>))
// 抓快取中現有設備列表備列表，從藍芽中心獲取相應的設備，並回傳結果。

public func receiveCHDeviceKeys(_ deviceKeys: [CHDeviceKey],result: @escaping (CHResult<[CHDevice]>))
// 收鑰匙列表
public func receiveCHDeviceKeys(_ deviceKeys: CHDeviceKey...,result: @escaping (CHResult<[CHDevice]>))
// 收鑰匙

public func disableNotification(deviceId: String, token: String, name: String, result: @escaping CHResult<CHEmpty>)
/*
取消通知: 把sns用的push token刪除
API Gateway:[jhcr1i3ecb]/device/v1/token/DELETE
Lambda: sesame_delete_device_token
DB: device_push_token
**/
```
