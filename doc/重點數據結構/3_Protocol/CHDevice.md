# CHDevice 協議

所有 Sesame 裝置都需要實現這些屬性和方法

## 屬性

- `delegate`: 這是 `CHDeviceStatusDelegate` 的代理，用於監聽裝置狀態的變化
- `rssi` : 接收藍芽信號強度指示符 (RSSI) = Sesame 與手機的距離
- `deviceId`: Sesame 唯一識別碼(UUID)
- `isRegistered`:該 Sesame 是否已被註冊
- `txPowerLevel`: Sesame 的藍芽功率等級
- `productModel`: Sesame 產品型號
- `deviceStatus`: `CHDeviceStatus` 的值，表示裝置的當前狀態
- `deviceShadowStatus` : AWS Iot 影子狀態(Optional)
- `mechStatus` : Sesame 機械狀態(Optional)

## 方法

```Swift
- getKey() -> CHDeviceKey? //如果裝置已註冊，則會返回鑰匙；否則，會返回 nil

- connect(result: @escaping (CHResult<CHEmpty>))// 建立藍芽連線到裝置

- dropKey(result: @escaping (CHResult<CHEmpty>)): // 刪除鑰匙

- disconnect(result: @escaping (CHResult<CHEmpty>))// 斷開與Sesame藍芽連線

- getVersionTag(result: @escaping (CHResult<String>)) // 取得固件版本號

- updateFirmware(result: @escaping CHResult<CBPeripheral?>) // 更新Sesame固件

- getTimeSignature() -> String //???

- reset(result: @escaping CHResult<CHEmpty>) //(循序圖)
- register(result: @escaping CHResult<CHEmpty>) //(循序圖)

- createGuestKey(result: @escaping CHResult<String>) // (循序圖)

- getGuestKeys(result: @escaping CHResult<[CHGuestKey]>) // (循序圖)

- removeGuestKey(_ guestKeyId: String, result: @escaping CHResult<CHEmpty>) // 移除(revoke?)訪客鑰匙

- updateGuestKey(_ guestKeyId: String, name: String, result: @escaping CHResult<CHEmpty>)

```

## 擴展

### 方法

```Swift
getFirZip() -> URL: 取得Sesame的固件壓縮檔的 URL
errorFromResultCode(_ resultCode: SesameResultCode) -> Error: 將 SesameResultCode 轉換為 Error。
```

## 分類

### 開關型產品

Sesame3/4/5/5 Pro, Bot1, Bike1/2

```Swift
public protocol CHSesameLock: CHDevice {
    var mechStatus: CHSesameProtocolMechStatus? { get set }
    func getHistoryTag() -> Data?
    func setHistoryTag(\_ tag: Data, result: @escaping (CHResult<CHEmpty>))
}
```

## 連接型產品

Wifi2, Sesame Touch/Touch Pro, Open Sensor ,Ble Connector

```Swift
public protocol CHSesameConnector {
    var sesame2Keys: [String: String] { get }
    func insertSesame(_ device: CHDevice, result: @escaping CHResult<CHEmpty>)
    func removeSesame(tag: String, result: @escaping CHResult<CHEmpty>)
}
```
