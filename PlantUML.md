```
@startuml
group 登録
participant CANDY_HOUSE_Cloud
participant Sesame2
participant SesameSDK
participant あなたのアプリ
participant あなたのユーザー
participant あなたのサーバー
|||
あなたのアプリ -> SesameSDK : [1] "SDKを利用する為の API Key" を plistファイルの中に書き込む
あなたのユーザー -> あなたのアプリ: [2] ユーザー登録（ID, Passwordなど）
あなたのアプリ -> あなたのサーバー : [3] 登録手続き
あなたのサーバー --> あなたのアプリ : [4] ok
あなたのユーザー -> あなたのアプリ: [5] 手元にある未登録のセサミデバイスを登録
あなたのアプリ -> SesameSDK : [6] 指令（Bluetoothをスキャンして）
SesameSDK -> SesameSDK : [7] Bluetoothをスキャンする
Sesame2 -> SesameSDK : [8] セサミデバイスのUUID
あなたのアプリ -> SesameSDK : [9] 指令（近くの未登録のセサミデバイスのUUIDをください）
SesameSDK --> あなたのアプリ : [10] 近くの未登録のセサミデバイスのUUID
あなたのアプリ -> SesameSDK : [11] 指令（このUUIDのセサミデバイスと接続して）
あなたのアプリ -> SesameSDK : [12] 指令（このUUIDのセサミデバイスを登録して）
SesameSDK -> CANDY_HOUSE_Cloud: [13] HTTP_Request（このUUIDのセサミデバイスを登録する）
CANDY_HOUSE_Cloud -> CANDY_HOUSE_Cloud: [14] 確認
CANDY_HOUSE_Cloud --> SesameSDK: [15] HTTP_Response（OK）
SesameSDK -> Sesame2: [16] BLE指令（このセサミの鍵をください）
Sesame2 -> Sesame2: [17] 鍵を作成、メモリーに保存
Sesame2 --> SesameSDK: [18] BLE_Response（セサミの鍵）
SesameSDK --> あなたのアプリ : [19] JSON_Objectという形のセサミの鍵
あなたのアプリ -> あなたのサーバー : [20] "JSON_Objectという形のセサミの鍵"　を保存・管理
|||
end
@enduml
```
