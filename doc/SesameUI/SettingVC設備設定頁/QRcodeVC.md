# QRCodeViewController 類別說明

繼承 CHBaseViewController，用於生成和展示 QR Code，並將其分享。

## 變數

- `device`: CHDevice!
- `user`: CHUser!

## 方法

```Swift
func generateDeviceQRCode()
// (instanceWithCHDevice)產生設備QR code.png(qrCodeImageView)。重點為:device.qrCodeWithKeyLevel(keyLevel)

func  generateFriendQRCode()
// (instanceWithUser)產生好友QR code.png，所需資料為CHUser

@objc func presentShareViewController(sender: UIView)
// QR code type為設備或用戶，顯示不同內容的QR code
```
