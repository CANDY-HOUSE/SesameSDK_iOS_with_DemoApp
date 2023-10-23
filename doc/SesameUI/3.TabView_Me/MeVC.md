# class MeViewController

繼承自 `CHBaseViewController`

## 方法與屬性(重點項目)

- `userState` 用戶的登入狀態 從 `AWSMobileClient.default().currentUserState`獲取
  - userState = `.signedIn` 顯示用戶名, email, qrCode
- `userNameView` 顯示用戶名(及 historyTag,和 cognito 中用戶屬性的 nick name)
- `ctaView` "signedIn"狀態下，點擊登出鍵會顯示的 AlertController，選擇確認或取消登出。
- `VersionLabel` APP 版號及 git commit 號顯示

```swift
@objc func changeNameTapped()
// 登入狀態為.signedIn，顯示ChangeValueDialog修改名稱/ .signedOut則導頁至SignUpViewController
@objc func shareUser()
// 建立QRCodeViewControllert實例(instanceWithUser)，並導頁至qrcodeVC
```
