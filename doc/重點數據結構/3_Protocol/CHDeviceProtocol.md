# CHDeviceProtocol 說明

一些設備相關，藍芽訊息定義及處理的集合

## 列舉

### SesameItemCode

發送給設備的藍芽指令編號，詳見代碼
例如:

- case lock = 82:關鎖
- case unlock = 83:開鎖
- case toggle = 88
<p align="left" >
  <img src="../../docs/src/lock_unlock_toggle.png" alt="" title="">
</p>

### SesameResultCode

設備藍芽收到 APP 指令後，執行完的回傳結果，詳見代碼

### SesameBleSegmentType

藍牙資料片段的類型，用於藍芽傳輸訊息的分段

- 1:plaintext 資料段的內容是明文，沒有加密。
- 2:ciphertext 資料段的內容是密文，即已經過加密的數據。
- 99:unknown: 資料段的類型是未知的或不可識別的

## SesameBleSegmentHead

藍牙資料段的 header，用於藍芽資料分段後的標示

- 0:content 此資料片段為某段資料的內容
- 1:start 表示新的資料包開始

### CHDeviceStatus

設備藍芽狀態與狀態描述，詳見代碼

## 類別: SesameBleTransmiter

主要功能是將較大的資料分割成較小的片段(BleSegment)，便於透過藍芽傳輸

1. 創建一個`SesameBleTransmiter`實例
2. 然後，反覆調用`getChunk()`方法，每次都取出一個片段，直到`buffer`為空。
3. 將每個片段通過藍芽傳送到設備
4. 設備收到資料片段後重新組合，獲取完整資料
