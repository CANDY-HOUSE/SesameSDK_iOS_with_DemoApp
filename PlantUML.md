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

autonumber

あなたのアプリ -> SesameSDK : "SDKを利用する為の API Key/ID" を コードの中に書き込む
あなたのユーザー -> あなたのアプリ: ユーザー登録（ID, Passwordなど）
あなたのアプリ -> あなたのサーバー : 登録手続き
あなたのサーバー --> あなたのアプリ : ok
あなたのユーザー -> あなたのアプリ: 手元にある未登録のセサミデバイスを登録
あなたのアプリ -> SesameSDK : 指令（Bluetoothをスキャンして）
SesameSDK -> SesameSDK : Bluetoothをスキャンする
Sesame2 -> SesameSDK : セサミデバイスのUUID
SesameSDK --> あなたのアプリ : セサミデバイスObject
あなたのアプリ -> SesameSDK : 指令（このセサミデバイスと接続して）
SesameSDK -> Sesame2: BLE指令（セサミと接続）
Sesame2 --> SesameSDK: BLE_Response（問題ない）
SesameSDK --> あなたのアプリ : 状態、結果など
あなたのアプリ -> SesameSDK : 指令（このセサミデバイスを登録して）
SesameSDK -> CANDY_HOUSE_Cloud: HTTP_Request（このセサミデバイスを登録する）
CANDY_HOUSE_Cloud -> CANDY_HOUSE_Cloud: 確認
CANDY_HOUSE_Cloud --> SesameSDK: HTTP_Response（OK）
SesameSDK -> Sesame2: BLE指令（このセサミの鍵をください）
Sesame2 -> Sesame2: 「**ランダム**」な鍵を作成、メモリーに保存
Sesame2 --> SesameSDK: BLE_Response（**ランダム**なセサミの鍵）
SesameSDK --> あなたのアプリ : JSON_Objectという形のセサミの鍵
あなたのアプリ -> あなたのサーバー : "JSON_Objectという形のセサミの鍵"　を保存・管理
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

autonumber

あなたのアプリ -> SesameSDK: "SDKを利用する為の API Key/ID" を コードの中に書き込む
あなたのユーザー -> あなたのアプリ: ユーザーログイン（ID, Passwordなど）
あなたのアプリ -> あなたのサーバー : ログイン手続き
あなたのサーバー --> あなたのアプリ : OK、"JSON_Objectという形のセサミの鍵"
あなたのアプリ -> SesameSDK: 指令（"JSON_Objectという形のセサミの鍵" を伝達）
あなたのアプリ -> SesameSDK: 指令（セサミデバイスと接続して）
SesameSDK -> Sesame2: BLE指令（セサミの鍵の適合確認）
Sesame2 --> SesameSDK: BLE_Response（問題ない）
SesameSDK --> あなたのアプリ : 状態、結果など
あなたのアプリ -> SesameSDK: 指令（開閉、設定など）
SesameSDK -> Sesame2: BLE指令（開閉、設定など）
Sesame2 --> SesameSDK: BLE_Response（状態、結果など）
SesameSDK --> あなたのアプリ : 状態、結果など
|||
end
@enduml
```
