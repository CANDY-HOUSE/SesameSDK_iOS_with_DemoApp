# BleAdv 次類別說明

`BleAdv` 用來解析藍牙廣播的架構，並把接收到的藍牙廣播數封裝為一個物件。當 `CHBluetoothCenter` 接收到新的藍牙裝置廣播時，會創建一個新的 `BleAdv`實例

### 初始化

解析收到的廣播資訊後儲存於以下的屬性中

### 變數與屬性

- `manufacturerData(0xff)`
  | Byte | 20 ~ 5 | 4 | 3 | 2 | 1 ~ 0 |
  |------|:------:|:----:|:--:|:----:|:-----:|
  | Data | IC 序號 | 是否註冊 | 保留 | 產品編號 | 公司代碼 |
  公司代碼 : 0x055A

| 產品編號 |       機型       |
| :------: | :--------------: |
|    0     |     Sesame 3     |
|    1     |  WiFi Module 2   |
|    2     |   Sesame Bot 1   |
|    3     |  Sesame Bike 1   |
|    4     |     Sesame 4     |
|    5     |     Sesame 5     |
|    6     |  Sesame Bike 2   |
|    7     |    Sesame Pro    |
|    8     |   Open Sensor    |
|    9     | Sesame Touch Pro |
|    10    |   Sesame Touch   |

- `deviceID`: 設備的 UUID
- `connectCount`: 連接次數
- `rssi`: 手機端接收到的廣播信號強度
- `txPowerLevel`: 發送功率等級
- `isRegistered`: 是否已註冊
- `adv_tag_b1`: 廣播標籤，這裡的具體含義可能需要查詢具體的硬體說明
- `productType`: 設備的產品型號，使用 CHProductModel 枚舉類型來表示
- `mPeripheral`: 與此廣播相關聯的 CBPeripheral 物件
- `mAdvertisementData`: 廣播的原始數據
- `timestamp`: 接收到廣播的時間戳
- `isConnectable`: 這個設備是否可以被連接
