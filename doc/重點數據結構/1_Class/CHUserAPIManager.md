# CHUserAPIManager 類別說明

Sesame 用戶 <-> Server 端(AWS)

## AWS SDK for iOS

- `AWSMobileClient` 負責所有和授權相關的後端運作
- `AWSMobileClient.default()` 返回`AWSMobileClient`默認實例(default instance)，默認實例是從 awsconfiguration.json 檔案中載入配置的。
- 官方文件: https://aws-amplify.github.io/aws-sdk-ios/docs/reference/AWSMobileClient/index.html

## 用戶註冊登入登出(AWS cognito)/用戶頁

跟 Sesame 用戶有關的互動使用 AWS Cognitto 服務進行，AWS cognito 可輕鬆讓手機 APP 與 Web 應用程式擁有`使用者註冊`和`身份驗證` 的功能。

<p align="left" >
  <img src="../src/imgs/cognito.png" alt="" title="">
</p>

### Sesame 用戶註冊/登入流程

## 設備

```swift

```

## 好友頁

- 好友 CRUD 相關

```swift
func postFriend(_ userId: String, _ result: @escaping CHResult<Any>)

func getFriends(_ last:String? = nil,_ result: @escaping CHResult<[CHUser]>)

func deleteFriend(_ subId: String, _ result: @escaping CHResult<Any>)

/**
API Gateway:[0dkzum4jzg]/friend
DB:user_friend
以上三個函數input皆為subUUID
*/
```

- 分享鑰匙相關

```Swift
func getUserKeysOfFriend(_ subId: String, _ result: @escaping CHResult<[CHUserKey]>)

func shareKey(_ userKey: CHUserKey, toFriend subId: String, _ result: @escaping CHResult<NSNull>)

func revokeKey(_ key: String, ofFriend friend: String, _ result: @escaping CHResult<NSNull>)

func uploadUserDeviceToken(_ result: @escaping CHResult<NSNull>)

/**
API Gateway:[0dkzum4jzg]/friend/device
DB:user_devices
*/
```

- 用戶頁相關

```Swift
func signUpWithEmail(_ email: String, _ result: @escaping ((SignUpResult?, Error?) -> Void))

func signInWithEmail(_ email: String)//app自動登入用，例如驗證碼錯誤，再次觸發登入流程得到新驗證碼

func signOut(_ completeHandler: (()->Void)? = nil)

----
/**
更新/拿取用戶在AWS cognito中的user attributes(屬性)
例: AWSMobileClient.default().updateUserAttributes
*/
func getSubId(_ handler: @escaping (String?)->Void)

func updateNickname(_ nickname: String, _ result: @escaping (Result<String, Error>) -> Void)

public func getNickname(_ result: @escaping (Result<String?, Error>) -> Void) -> String

public func getEmail(_ result:@escaping (Result<String?, Error>) -> Void) -> String
```
