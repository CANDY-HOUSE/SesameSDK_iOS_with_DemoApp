# CHSesameOS3 類別解說

用於 SesameOS3() 裝置進行藍牙通信的類別。主要用途:

1.建立和管理與裝置的藍牙連接 2.接收和處理來自裝置的通知或消息 3.向裝置發送命令或請求 4.加解密通信數據

## 屬性

- mSesameToken: OS3 設備傳給手機 APP 的四 bytes 亂數，用於兩端的通信驗證
- cipher: SesameOS3BleCipher

## 方法

```Swift
func sendCommand(_ payload:SesameOS3Payload,
                isCipher: SesameBleSegmentType = .ciphertext,
                onResponse: @escaping SesameOS3ResponseCallback)
// 向Sesame OS3 裝置發送指令，將 payload 進行加密(isCipher?需要:不用)，並回調onResponse

func transmit()
// 向Sesame OS3 裝置傳輸數據，先檢查是否有待發送的數據。有=>它會將數據寫入藍牙裝置，此方法可能會遞迴調用自己，以確保所有的數據都被發送。

func onGattSesamePublish(_ payload: SesameOS3PublishPayload)
// 根據 SesameOS3設備發送給手機的 payload 內容進行對應操作。
```

## SesameOS3BleCipher 類別:

處理手機 APP 和 Sesame 設備間的數據傳輸加解密，使用 sessionKey 作為密鑰。

- 加密(`encrypt`):用於 APP 要發送到 Sesame 設備的訊息
- 解密(`decrypt`):用於 Sesame 設備發送到手機端的訊息

### 屬性

- `encryptCounter` 和 `decryptCounter` 追踪加密和解密操作的次數。每次加密或解密後，相應的計數器會加 1。
- `name` 設備名稱
- `sessionKey` 用作 AES 加密的密鑰
- `sessionToken`

### 方法

```Swift
public func encrypt(_ plaintext: Data)  -> Data
//使用 AES CCM加密

public func decrypt(_ ciphertext: Data)  -> Data
//AES CCM 解密
```
