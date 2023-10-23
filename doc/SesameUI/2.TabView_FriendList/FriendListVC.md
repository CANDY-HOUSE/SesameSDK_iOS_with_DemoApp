# 好友列表頁

顯示登入中 Sesame 帳戶擁有的 Sesame 好友

## FriendListViewController 類別說明

### 組成

- UI: TableView/UITableViewCell(`FriendListCell`)
- 所需資料:[CHUser]
- 顯示條件: 使用者須在 app 登入 Sesame 帳戶，否則清空列表

### 方法/功能

- `CHUserAPIManager.shared.getFriends()` 獲取 server 端好友列表
- 點擊單一`FriendListCell` 導至 好友設備頁(`FriendKeyListViewController`)

## FriendKeyListViewController 視圖控制器 類別說明

顯示單一好友、該好友被你分享過的設備，及可分享的設備

### 組成

- UI: TableView
- 所需資料:[CHUser],[CHUserKey]

### 方法/功能

```Swift
- CHUserAPIManager.shared.getUserKeysOfFriend(好友SubID)// 分享鑰匙給好友
- CHUserAPIManager.shared.revokeKey({設備UUID,好友SubID})// 刪除好友鑰匙
- CHUserAPIManager.shared.deleteFriend(好友SubID)// 刪除好友
```

### FriendKeyShareSelectionVC

#### 方法/功能

```Swift
CHUserAPIManager.shared.shareKey(userKey, 好友SubID) // 分享三種權限的鑰匙給好友

/*
- OwnerKey: keyLevel 為 0
- ManagerKey: keyLevel 為 1
- GuestKey: keyLevel 為 2
**/
```

#### Sesame key 權限解說

- OwnerKey 擁有者鑰匙: 所有頁面的瀏覽、分享所有權限的鑰匙、撤銷訪客鑰匙
- ManagerKey 管理員鑰匙: 同 owner key
- GuestKey 訪客鑰匙: 無法瀏覽該設備歷史頁、無法更改設備設定、無法瀏覽設備使用者

## 新增好友的方法 說明

透過 QR code 掃描，獲得對方的 subID

```Swift
// QR code scan
- static func parseSesameQRCode(_ qrCodeURL: String, handler: @escaping ((Result<QRcodeType, Error>)->Void))
- func receivedQRCode(_ qrCodeURL: String?)
// 新增好友
CHUserAPIManager.shared.postFriend(好友subID)
```
