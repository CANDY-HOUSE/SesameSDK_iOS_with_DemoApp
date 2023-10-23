# CHBaseViewController 類別說明

繼承自 `UIViewController`，所有子類別都可以利用它所提供的共享功能(popup menu 和 導頁)，並根據自己的需求覆寫或添加

## 主要屬性

- `titleLabel`: 顯示視圖控制器的標題
- `popUpMenuControl`: PopUpMenu 控制項，點擊按鈕時出現掃描添加設備和掃描選單。
- `soundPlayer`
- `previouseNavigationTitle`: 紀錄前一個視圖控制器的標題。

## 主要方法

- `presentScanViewController()`
  顯示 QR code 掃瞄器，掃描完成後，根據得到的`qrCodeType`執行對應操作
  - .sesameKey => 切換至 APP 第一個 tab(設備列表頁)，getKeysFromCache()
  - .friend => 切換至第二個 tab(好友頁)，並抓取好友列表
- `presentRegisterSesame2ViewController()`

生成註冊列表用，並於註冊設備完成後導頁，導頁流向如下圖:

<p align="left" >
  <img src="../src/imgs/註冊導頁.png" alt="" title="">
</p>
