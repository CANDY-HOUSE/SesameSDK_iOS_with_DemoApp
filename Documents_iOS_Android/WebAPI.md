# WebAPI (baseurl 変動の予定あり、APIKeyが必須になる予定あり)

* baseurl:https://jhcr1i3ecb.execute-api.ap-northeast-1.amazonaws.com/prod

## 1. Sesame2 History

* HTTP: Get
* path: "/device/sesame2/{sesame2_uuid}/webhistory"
* Parameters:
	* name = "sesame2_uuid", location = "path"
   	* name = "page", location = "query",page: Int
   	* name = "lg", location = "query",lg: Int



### Request
``` http
    GET https://jhcr1i3ecb.execute-api.ap-northeast-1.amazonaws.com/prod/device/sesame2/CC3E2AD0-E65F-A194-8486-07E3D0CF110C/webhistory?page=0&lg=5&tk=3a4a6c0762a4f285f454b0c6
```
### Response
``` javascript
   [
      {
         "type":2,                                        // 説明を補足する予定
         "timeStamp":1597497519.0,                        // 1970/1/1 00:00:00 から秒単位のタイムスタンプ
         "historyTag":"44OJ44Op44GI44KC44KT",             // 鍵に付いてるタグやメモ 0 ~ 21bytes
         "devicePk":"5469bc01e40fe65ca2b7baaf55171ddb",   // スマホのPublic Keyの前の16 bytes. 例え同じセサミデバイスの鍵でセサミデバイスを操作したとしても、スマホ毎に異なる。但し、アプリを削除し再度インストールすると、Public Keyが変わる。アプリを再インストールしない限り、Public Keyが変わらない。
         "recordID":262,                                  // 連続でない(将来、連続になるように修正する予定)、セサミデバイスがリセットされるまで当履歴の唯1つのID、 小→大
         "parameter":null                                 // 説明を補足する予定
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
```

## 2. Sesame2 Shadow

* HTTP: Get
* path: "/device/sesame2/{sesame2_uuid}"
* Parameters:
	* name = "sesame2_uuid", location = "path"
     


### Request
``` http
    GET https://jhcr1i3ecb.execute-api.ap-northeast-1.amazonaws.com/prod/device/sesame2/214A9AD8-8B4A-13D0-DB7E-ED62270A6663
```
### Response
``` javascript
{
   "batteryPercentage":94, // 電池残量94%
   "batteryVoltage":5.869794721407625, // 電池の電圧, 単位: ボルト(V)
   "position":0, // セサミデバイスの角度, 360˚ は 1024
   "deviceStatus":"locked"
}
```

[Message]: README.md
