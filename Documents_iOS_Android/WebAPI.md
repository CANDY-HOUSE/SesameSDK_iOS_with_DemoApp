# WebAPI (baseurl 変動の予定あり、APIKeyが必須になる予定あり)

## 1. Sesame2 History

### Request
```http
GET https://jhcr1i3ecb.execute-api.ap-northeast-1.amazonaws.com/prod/device/sesame2/CC3E2AD0-E65F-A194-8486-07E3D0CF110C/webhistory?page=0&lg=3
```
```javascript
/*
HTTP: Get
baseurl: "https://jhcr1i3ecb.execute-api.ap-northeast-1.amazonaws.com/prod"
path: "/device/sesame2/{sesame2_uuid}/webhistory"
Parameters:
    name = "sesame2_uuid", location = "path"
    name = "page", location = "query",page: Int ; ページ数。ページ数の0から、新→旧の履歴順番で、1ページの中に最多50件の履歴が入ってる。
    name = "lg", location = "query",lg: Int     ; 指定されたページの中に、新→旧の履歴順番で取得したい履歴件数。
*/
```
### Response
```javascript
[
   {
      "type":2,                                        
      "timeStamp":1597492862.0,                        // 1970/1/1 00:00:00 から秒単位のタイムスタンプ
      "historyTag":"44OJ44Op44GI44KC44KT",             // 鍵に付いてるタグやメモ 0 ~ 21bytes
      "devicePk":"5469bc01e40fe65ca2b7baaf55171ddb",   // スマホのPublic Keyの前の16 bytes. 例え同じセサミデバイスの鍵でセサミデバイスを操作したとしても、スマホ毎に異なる。但し、アプリを削除し再度インストールすると、Public Keyが変わる。アプリを再インストールしない限り、Public Keyが変わらない。
      "recordID":255,                                  // 連続でない(将来、連続になるように修正する予定)、セサミデバイスがリセットされるまで当履歴の唯1つのID、 小→大
      "parameter":null                                 // 解析する予定
   },
   {
      "type":11,
      "timeStamp":1597492864.0,
      "historyTag":null,
      "devicePk":null,
      "recordID":256,
      "parameter":null
   },
   {
      "type":0,
      "timeStamp":2147483647.0,
      "historyTag":null,
      "devicePk":null,
      "recordID":740294720,
      "parameter":null
   },
]
   

/*
type :

    0 この条の履歴は既にセサミデバイス内部メモリから削除されました。 シーンの例:セサミデバイスが複数のスマホに接続され、この条の履歴がもう既に他のスマホにクラウドにアップされて、クラウドからの指令に従ってセサミデバイス内部メモリ削除されました。
    1 セサミデバイスが 施錠のBLEコマンド を受付ました。
    2 セサミデバイスが 解錠のBLEコマンド を受付ました。
    3 セサミデバイスの内部時計が校正された。
    4 オートロックの設定が変更されました。
    5 施解錠角度の設定が変更されました。
    6 セサミデバイスがオートロックしました。
    7 手動で施錠 (下記  ケース2またケース3 から ケース1 になった場合 )
    8 手動で解錠 (下記  ケース1またケース3 から ケース2 になった場合 )
    9 解錠の点または施錠の点から、サムターンに動きがあった場合（下記 　ケース１からケース３になった場合、またはケース２からケース３になった場合）
   10 モーターが確実に施錠しました。
   11 モーターが確実に解錠しました。
   12 モーターが施解錠の途中に失敗しました。
   13 セサミデバイスが発信しているBluetooth advertisement の Interval と TXPower の設定が変更されました。


補足１：現時点では状態は以下の３つのみとなっています。
  ＜ケース１：施錠＞
    サムターンが施錠の点にある場合、
    施錠　1
    解錠　0　
  ＜ケース２：解錠＞
    サムターンが解錠の点にある場合、
    施錠　0
    解錠　1
  ＜ケース３：それ以外（※現時点では「解錠」とUI上で表示しています。 ＞
    サムターンが以上の２点以外にある場合、
    施錠　0
    解錠　0


補足２：現時点のSDKとAPPでは解錠と施錠は「点」となっておりますが、今後ユーザー様が解錠/施錠状態を範囲で設定出来る様に変更予定で、ファームウェアには既にその機能は実装しております。
*/

```

## 2. Sesame2 Shadow

### Request
```http
GET https://jhcr1i3ecb.execute-api.ap-northeast-1.amazonaws.com/prod/device/sesame2/214A9AD8-8B4A-13D0-DB7E-ED62270A6663
```
```javascript
/*
HTTP: Get
baseurl: "https://jhcr1i3ecb.execute-api.ap-northeast-1.amazonaws.com/prod"
path: "/device/sesame2/{sesame2_uuid}"
Parameters:
    name = "sesame2_uuid", location = "path"
*/
```
### Response
``` javascript
{
   "batteryPercentage":94,             // 電池残量94%
   "batteryVoltage":5.869794721407625, // 電池の電圧, 単位: ボルト(V)
   "position":0,                       // セサミデバイスの角度, 360˚ は 1024
   "deviceStatus":"locked"
}
```

[Message]: README.md
