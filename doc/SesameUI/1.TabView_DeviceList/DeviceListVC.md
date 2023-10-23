# SesameDeviceListViewController

`SesameDeviceListViewController` - App 的首頁，由 TableView 組成。管理和顯示 Sesame 設備列表，此視圖控制器顯示用戶已經註冊的所有 Sesame 設備，並提供操作方法。

## 功能

- 設備列表顯示：用戶的所有 Sesame 裝置(`CHDevice`)，單列為一個設備(`ListCell`)。監聽`AWSMobileClient` 的登入狀態變化來整合本地端與 server 的設備列表
<p align="left" >
  <img src="../DeviceList/整合設備列表.png" alt="" title="">
</p>

`ListCell` 顯示

- APP 與 Sesame 的藍芽連線與否
- Sesame 與 wifi 連接與否
- Sesame 電量

<p align="left" >
  <img src="../DeviceList/顯示設備.png" alt="" title="">
</p>

- 重新排序：長按設備並拖動它來重新排序

```Swift
LongPressReorderTableView(tableView,selectedRowScale: .big)
```

<p align="left" >
  <img src="../DeviceList/手動排序.png" alt="" title="">
</p>

- 操作：
  - 點擊右側`sesame2Circle` 實施開關鎖
  - 點及單一設備進入歷史頁或設定頁
