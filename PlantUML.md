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
あなたのアプリ -> SesameSDK : [9] 指令（このセサミデバイスと接続して）
SesameSDK -> Sesame2: [10] BLE指令（セサミと接続）
Sesame2 --> SesameSDK: [11] BLE_Response（問題ない）
SesameSDK --> あなたのアプリ : [12] 状態、結果など
あなたのアプリ -> SesameSDK : [13] 指令（このセサミデバイスを登録して）
SesameSDK -> CANDY_HOUSE_Cloud: [14] HTTP_Request（このセサミデバイスを登録する）
CANDY_HOUSE_Cloud -> CANDY_HOUSE_Cloud: [15] 確認
CANDY_HOUSE_Cloud --> SesameSDK: [16] HTTP_Response（OK）
SesameSDK -> Sesame2: [17] BLE指令（このセサミの鍵をください）
Sesame2 -> Sesame2: [18] 鍵を作成、メモリーに保存
Sesame2 --> SesameSDK: [19] BLE_Response（セサミの鍵）
SesameSDK --> あなたのアプリ : [20] JSON_Objectという形のセサミの鍵
あなたのアプリ -> あなたのサーバー : [21] "JSON_Objectという形のセサミの鍵"　を保存・管理
|||
end
@enduml
```


```
@startuml
group 操作
participant Sesame2
participant SesameSDK
participant あなたのアプリ
participant あなたのユーザー
participant あなたのサーバー
|||
あなたのアプリ -> SesameSDK: [1] "SDKを利用する為の API Key" を plistファイルの中に書き込む
あなたのユーザー -> あなたのアプリ: [2] ユーザーログイン（ID, Passwordなど）
あなたのアプリ -> あなたのサーバー : [3] ログイン手続き
あなたのサーバー --> あなたのアプリ : [4] OK、"JSON_Objectという形のセサミの鍵"
あなたのアプリ -> SesameSDK: [5] 指令（"JSON_Objectという形のセサミの鍵" を伝達）
あなたのアプリ -> SesameSDK: [6] 指令（セサミデバイスと接続して）
SesameSDK -> Sesame2: [7] BLE指令（セサミの鍵の適合確認）
Sesame2 --> SesameSDK: [8] BLE_Response（問題ない）
SesameSDK --> あなたのアプリ : [9] 状態、結果など
あなたのアプリ -> SesameSDK: [10] 指令（開閉、設定など）
SesameSDK -> Sesame2: [11] BLE指令（開閉、設定など）
Sesame2 --> SesameSDK: [12] BLE_Response（状態、結果など）
SesameSDK --> あなたのアプリ : [13] 状態、結果など
|||
end
@enduml
```
